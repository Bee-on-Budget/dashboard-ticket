import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../modules/models/ticket_file.dart';
import '../modules/models/ticket.dart';
import '../modules/models/user.dart';
import '../modules/models/company.dart';
import '../config/db_collections.dart';
import '../config/enums/payment_methods.dart';

class DataService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  static Stream<List<User>> getUsers() {
    return _firestore
        .collection(DbCollections.users)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return User.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  static Future<List<String>> getUserCompany(String userId) async {
    return List<String>.from(
      (await _firestore.collection(DbCollections.users).doc(userId).get())
              .data()?['companies'] ??
          [],
    );
  }

  static Future<void> updateUser(User user) async {
    try {
      await _firestore.collection(DbCollections.users).doc(user.id).update({
        'username': user.username,
        'email': user.email,
        'phoneNumber': user.phoneNumber,
        'role': user.role.toString(),
        'paymentMethods': user.paymentMethods.map((e) => e.toString()).toList(),
        'companies': user.companies,
        'isActive': user.isActive,
      });
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  static Stream<List<Ticket>> getAllTickets() {
    return _firestore
        .collection(DbCollections.tickets)
        .snapshots()
        .map((snapshot) {
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
        .collection(DbCollections.tickets)
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
        .collection(DbCollections.tickets)
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

  // UPDATED: Fetch files - prioritize Firestore, gracefully handle Storage errors
  static Future<List<Map<String, String>>> getTicketFiles(
      String ticketId) async {
    try {
      // First, try to get files from Firestore subcollection
      final firestoreSnapshot = await _firestore
          .collection(DbCollections.tickets)
          .doc(ticketId)
          .collection('files')
          .get();

      if (firestoreSnapshot.docs.isNotEmpty) {
        // Files exist in Firestore - this is the primary source
        print(
            'Found ${firestoreSnapshot.docs.length} files in Firestore for ticket $ticketId');
        return firestoreSnapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'fileId': doc.id,
            'url': data['url'] as String? ?? '',
            'fileName': data['fileName'] as String? ?? 'Unknown File',
          };
        }).toList();
      }

      // Only try Storage if Firestore has no files
      print('No files in Firestore for ticket $ticketId, checking Storage...');

      try {
        // Check if Storage is available
        final storageRef = _storage.ref('tickets/$ticketId/files');
        final listResult = await storageRef.listAll().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Storage timeout for ticket $ticketId');
            throw TimeoutException('Storage listing timed out');
          },
        );

        if (listResult.items.isEmpty) {
          print('No files found in Storage for ticket $ticketId');
          return [];
        }

        print(
            'Found ${listResult.items.length} files in Storage for ticket $ticketId');

        final filesFutures = listResult.items.map((item) async {
          try {
            final url = await item.getDownloadURL();
            final metadata = await item.getMetadata();

            return {
              'fileId': item.name,
              'url': url,
              'fileName': metadata.customMetadata?['fileName'] ??
                  metadata.name ??
                  item.name,
            };
          } catch (e) {
            print('Error getting file ${item.name}: $e');
            return null;
          }
        }).toList();

        final files = await Future.wait(filesFutures);
        return files
            .where((file) => file != null && file['url']!.isNotEmpty)
            .cast<Map<String, String>>()
            .toList();
      } on TimeoutException catch (e) {
        print('Storage timeout: $e');
        return [];
      } on FirebaseException catch (e) {
        print('Firebase Storage error: ${e.code} - ${e.message}');
        return [];
      }
    } catch (e) {
      print('Error in getTicketFiles: $e');
      return [];
    }
  }

  // ALTERNATIVE: Get files from Storage with better error handling
  static Future<List<Map<String, String>>> getTicketFilesFromStorage(
      String ticketId) async {
    try {
      final storageRef = _storage.ref().child('tickets/$ticketId/files');
      final listResult = await storageRef.listAll();

      if (listResult.items.isEmpty) {
        return [];
      }

      final filesFutures = listResult.items.map((item) async {
        try {
          final url = await item.getDownloadURL();
          final metadata = await item.getMetadata();

          return {
            'fileId': item.name,
            'url': url,
            'fileName': metadata.customMetadata?['originalName'] ?? item.name,
          };
        } catch (e) {
          print('Error getting file ${item.name}: $e');
          return {
            'fileId': item.name,
            'url': '',
            'fileName': item.name,
          };
        }
      }).toList();

      return await Future.wait(filesFutures);
    } catch (e) {
      print('Error fetching files from storage: $e');
      return [];
    }
  }

  static Stream<List<Map<String, dynamic>>> getFileComments(
      String ticketId, String fileId) {
    return _firestore
        .collection(DbCollections.tickets)
        .doc(ticketId)
        .collection('files')
        .doc(fileId)
        .snapshots()
        .map((doc) {
      final data = doc.data();
      return (data?['comments'] as List<dynamic>?)
              ?.map((comment) => Map<String, dynamic>.from(comment))
              .toList() ??
          [];
    });
  }

  static Future<void> addComment(
      String ticketId, String fileId, String message, String senderId) async {
    final docRef = _firestore
        .collection(DbCollections.tickets)
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

  // Company methods
  static Stream<List<Company>> getCompanies() {
    return _firestore
        .collection(DbCollections.companies)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Company.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  static Future<void> createCompany(Company company) async {
    try {
      await _firestore
          .collection(DbCollections.companies)
          .doc(company.id)
          .set(company.toJson());
    } catch (e) {
      throw Exception('Failed to create company: $e');
    }
  }

  static Future<void> updateCompany(Company company) async {
    try {
      await _firestore
          .collection(DbCollections.companies)
          .doc(company.id)
          .update({
        'name': company.name,
        'paymentMethods':
            company.paymentMethods.map((pm) => pm.toString()).toList(),
        'isActive': company.isActive,
      });

      // If company is deactivated, deactivate all its users
      if (!company.isActive) {
        await deactivateCompanyUsers(company.name);
      }
    } catch (e) {
      throw Exception('Failed to update company: $e');
    }
  }

  static Future<void> deleteCompany(String companyId) async {
    try {
      await _firestore
          .collection(DbCollections.companies)
          .doc(companyId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete company: $e');
    }
  }

  // Deactivate all users belonging to a company
  static Future<void> deactivateCompanyUsers(String companyName) async {
    try {
      final usersSnapshot = await _firestore
          .collection(DbCollections.users)
          .where('companies', arrayContains: companyName)
          .get();

      final batch = _firestore.batch();
      for (var doc in usersSnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to deactivate company users: $e');
    }
  }

  // When payment method is added to company, update all users in that company
  static Future<void> syncPaymentMethodsToCompanyUsers(
      String companyName, List<String> paymentMethods) async {
    try {
      final usersSnapshot = await _firestore
          .collection(DbCollections.users)
          .where('companies', arrayContains: companyName)
          .get();

      final batch = _firestore.batch();
      for (var doc in usersSnapshot.docs) {
        final currentPaymentMethods =
            List<String>.from(doc.data()['paymentMethods'] ?? []);
        final newPaymentMethods =
            paymentMethods.map((pm) => pm.toString()).toList();

        // Merge: add new payment methods that don't exist
        for (var pm in newPaymentMethods) {
          if (!currentPaymentMethods.contains(pm)) {
            currentPaymentMethods.add(pm);
          }
        }

        batch.update(doc.reference, {'paymentMethods': currentPaymentMethods});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to sync payment methods: $e');
    }
  }

  // Search users by username or email
  static Future<List<User>> searchUsers(String query) async {
    try {
      final snapshot = await _firestore
          .collection(DbCollections.users)
          .where('isActive', isEqualTo: true)
          .get();

      final allUsers = snapshot.docs
          .map((doc) => User.fromJson(doc.data(), doc.id))
          .toList();

      if (query.isEmpty) return allUsers;

      final lowerQuery = query.toLowerCase();
      return allUsers.where((user) {
        return user.username.toLowerCase().contains(lowerQuery) ||
            user.email.toLowerCase().contains(lowerQuery);
      }).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
