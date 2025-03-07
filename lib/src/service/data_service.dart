import 'package:cloud_firestore/cloud_firestore.dart';

import '../modules/models/ticket_file.dart';
import '../modules/models/ticket.dart';
import '../modules/models/user.dart';

class DataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Stream<List<User>> getUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return User.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  static Future<List<String>> getUserCompany(String userId) async {
    return List<String>.from(
      (await _firestore.collection('users').doc(userId).get())
              .data()?['companies'] ??
          [],
    );
  }

  static Stream<List<Ticket>> getAllTickets() {
    return _firestore.collection('tickets').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ticket.fromJson(
          json: doc.data(),
          ticketId: doc.id,
          publisher: null,
        );
      }).toList();
    });
  }

  static Stream<List<Ticket>> getUserTickets({
    required String userId,
    required String publisher,
  }) {
    return _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('createdDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Ticket.fromJson(
          ticketId: doc.id,
          publisher: null,
          json: doc.data(),
        );
      }).toList();
    });
  }

  static Stream<Ticket> getTicketWithFiles(Ticket ticket) {
    List<TicketFile> files = [];
    return _firestore
        .collection('tickets')
        .doc(ticket.ticketId)
        .collection('files')
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      files.addAll(
        snapshot.docs.map(
          (doc) => TicketFile.fromJson(json: doc.data(), fileId: doc.id),
        ),
      );
      return ticket.copyWith(files: files);
    });
  }

  static Stream<List<Map<String, String>>> getTicketFiles(String ticketId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('files')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'fileId': doc.id, // Ensure fileId is included here
          'url': data['url'] as String,
          'fileName': data['fileName'] as String,
        };
      }).toList();
    });
  }

  static Stream<List<Map<String, dynamic>>> getFileComments(
      String ticketId, String fileId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('files')
        .doc(fileId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return (data?['comments'] as List<dynamic>)
          .map((comment) => Map<String, dynamic>.from(comment))
          .toList();
    });
  }

  static Future<void> addComment(
      String ticketId, String fileId, String message, String senderId) async {
    final docRef = _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('files')
        .doc(fileId);

    await docRef.update({
      'comments': FieldValue.arrayUnion([
        {
          'message': message,
          'senderId': senderId,
          'timestamp': FieldValue.serverTimestamp(),
        }
      ]),
      'isThereMsgNotRead': true,
    });
  }
}
