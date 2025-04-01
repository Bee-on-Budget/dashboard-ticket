import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a user with email and password
  Future<String?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
    required List<String> companies,
    required List<String> paymentMethods,
    required String role,
  }) async {
    try {
      // Create user with email and password
      final UserCredential userCredential =
          await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Save additional user data to Firestore
      await _saveUserToFirestore(
        userCredential.user!.uid,
        email,
        username,
        companies,
        paymentMethods,
        role,
      );

      return null; // No error, registration successful
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the actual error message
    } catch (e) {
      return e.toString(); // Handle any other exceptions
    }
  }

  Future<String?> createUserWithPhoneAndPassword({
    required String phone,
    required String password,
    required String username,
    required List<String> companies,
    required List<String> paymentMethods,
    required String role,
  }) async {
    try {
      // Placeholder for custom phone + password registration
      // Firebase does not natively support phone + password registration.
      // You may need to implement a custom solution for this.
      return 'Phone registration not implemented yet';
    } on FirebaseAuthException catch (e) {
      return e.message; // Return the actual error message
    } catch (e) {
      return e.toString(); // Handle any other exceptions
    }
  }

  Future<void> _saveUserToFirestore(
    String uid,
    String identifier,
    String username,
    List<String> companies,
    List<String> paymentMethods,
    String role,
  ) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': identifier,
          'username': username,
          'companies': companies,
          'paymentMethods': paymentMethods,
          'role': role,
          'isActive': true, // Ensure isActive is set to true by default
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint("User successfully saved to Firestore!");
      } else {
        debugPrint("User already exists in Firestore.");
      }
    } catch (e) {
      debugPrint('Error saving user to Firestore: $e');
    }
  }

  // Sign in with email and password and check user role and active status
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check user role and active status
      final user = userCredential.user;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final role = userDoc['role'] as String?;
        final isActive = userDoc['isActive'] as bool? ?? true;

        if (isActive) {
          return user; // Allow active users to proceed
        } else {
          debugPrint('Access denied: User is inactive.');
          return null; // Return null for inactive users
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error during email sign-in: $e');
      return null;
    }
  }

  // Sign in with phone number and password and check user role and active status
  Future<User?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      // Use the phone number as an email-like identifier
      final fakeEmail = '$phone@phone.com';

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      // Check user role and active status
      final user = userCredential.user;
      if (user != null) {
        final userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        final role = userDoc['role'] as String?;
        final isActive = userDoc['isActive'] as bool? ?? true;

        if (isActive) {
          return user; // Allow active users to proceed
        } else {
          debugPrint('Access denied: User is inactive.');
          return null; // Return null for inactive users
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error during phone sign-in: $e');
      return null;
    }
  }

  // Get user role
  Future<String?> getRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc['role'] as String?;
    } catch (e) {
      debugPrint('Error fetching user role: $e');
      return null;
    }
  }

  // Deactivate a user
  Future<void> deactivateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': false});
      debugPrint("User deactivated successfully!");
    } catch (e) {
      debugPrint('Error deactivating user: $e');
    }
  }

  // Reactivate a user
  Future<void> reactivateUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).update({'isActive': true});
      debugPrint("User reactivated successfully!");
    } catch (e) {
      debugPrint('Error reactivating user: $e');
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
    }
  }
}
