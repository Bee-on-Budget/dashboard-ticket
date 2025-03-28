import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserStatusManager extends StatefulWidget {
  final String userId;
  final bool initialStatus;

  const UserStatusManager({
    super.key,
    required this.userId,
    required this.initialStatus,
  });

  @override
  State<UserStatusManager> createState() => _UserStatusManagerState();
}

class _UserStatusManagerState extends State<UserStatusManager> {
  late bool _currentStatus;
  late TextEditingController _userIdController;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.initialStatus;
    _userIdController = TextEditingController(text: widget.userId);
  }

  @override
  void dispose() {
    _userIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _userIdController,
              decoration: const InputDecoration(
                labelText: 'User ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 40, // Smaller button height
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _currentStatus ? Colors.red : Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: _toggleStatus,
                child: Text(
                  _currentStatus ? 'Deactivate Account' : 'Activate Account',
                  style: const TextStyle(
                    fontSize: 14, // Smaller font size
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus() async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_userIdController.text) // Use the edited ID
          .update({'isActive': !_currentStatus});

      setState(() {
        _currentStatus = !_currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _currentStatus
                ? 'User account activated'
                : 'User account deactivated',
          ),
          backgroundColor: _currentStatus ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
