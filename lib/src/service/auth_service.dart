import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Create a user with email and password
  Future<User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during user creation with email: $e');
      return null;
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during email sign-in: $e');
      return null;
    }
  }

  // Create a user with phone number and password (phone treated as an email identifier)
  Future<User?> createUserWithPhoneAndPassword(
      String phone, String password) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: '$phone@phone.com', // Treat phone as an email-like identifier
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during user creation with phone: $e');
      return null;
    }
  }

  // Sign in with phone number and password (phone as email identifier)
  Future<User?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: '$phone@phone.com', // Treat phone as an email-like identifier
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error during phone sign-in: $e');
      return null;
    }
  }

  // Send a password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }
}
