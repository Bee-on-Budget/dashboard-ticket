import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../service/synchronized_time.dart';
import '../models/ticket_file.dart';

class CommentScreen extends StatefulWidget {
  final String ticketId;

  final TicketFile file;

  const CommentScreen({
    super.key,
    required this.ticketId,
    required this.file,
  });

  @override
  State<CommentScreen> createState() => _FileMessagingPageState();
}

class _FileMessagingPageState extends State<CommentScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  bool _enableSending = false;
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('File Discussion', style: TextStyle(fontSize: 18)),
            Text(
              widget.file.fileName,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _firestore
                  .collection('tickets')
                  .doc(widget.ticketId)
                  .collection('files')
                  .doc(widget.file.fileId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollController.jumpTo(
                    _scrollController.position.maxScrollExtent,
                  );
                });

                final fileData = snapshot.data!.data() as Map<String, dynamic>;
                final comments = List<Map<String, dynamic>>.from(
                  fileData['comments'] ?? [],
                )..sort(
                    (a, b) {
                      final timestampA = a['timestamp'] as Timestamp;
                      final timestampB = b['timestamp'] as Timestamp;
                      return timestampA.compareTo(timestampB);
                    },
                  );

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Future<String> _getUsername(String senderId) async {
    final userDoc = await _firestore.collection('users').doc(senderId).get();
    if (userDoc.exists) {
      return userDoc.data()?['username'] ?? 'Unknown User';
    }
    return 'Unknown User';
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final isCurrentUser = comment['senderId'] == _auth.currentUser?.uid;
    final timestamp = (comment['timestamp'] as Timestamp).toDate();

    return FutureBuilder<String>(
      future: _getUsername(comment['senderId']),
      builder: (context, snapshot) {
        final username = snapshot.data ?? 'Loading...';

        return Align(
          alignment:
              isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Text(
                    username, // Display the username here
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (comment['message'] != null && comment['message'].isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(comment['message']),
                  ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type your message...',
                border: InputBorder.none,
              ),
              maxLines: 3,
              minLines: 1,
              onChanged: (value) {
                if (value.trim().isEmpty) {
                  setState(() {
                    _enableSending = false;
                  });
                } else if (!_enableSending) {
                  setState(() {
                    _enableSending = true;
                  });
                }
              },
              enabled: !_isSending,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
            tooltip: 'Send a message',
            onPressed: _isSending || !_enableSending ? null : _sendMessage,
          ),
        ],
      ),
    );
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSending = true);

    try {
      final fileRef = _firestore
          .collection('tickets')
          .doc(widget.ticketId)
          .collection('files')
          .doc(widget.file.fileId);

      final fileDoc = await fileRef.get();
      final existingComments =
          fileDoc.exists && fileDoc.data()!.containsKey("comments")
              ? List<Map<String, dynamic>>.from(fileDoc["comments"])
              : [];

      SynchronizedTime.initialize();
      existingComments.add({
        'message': message,
        'senderId': user.uid,
        'timestamp': SynchronizedTime.now(),
      });

      await fileRef.set({
        'comments': existingComments,
        'isThereMsgNotRead': true,
      }, SetOptions(merge: true));

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }
}
