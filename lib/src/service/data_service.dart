import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dashboard/src/modules/models/ticket_file.dart';

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
}
