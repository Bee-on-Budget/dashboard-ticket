import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a user with email and password
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
    List<String> companies,
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user info in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'companies': companies,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential.user;
    } catch (e) {
      print('Error during user creation: $e');
      return null;
    }
  }

  // Create a user with phone number and password
  Future<User?> createUserWithPhoneAndPassword(
    String phone,
    String password,
    String username,
    List<String> companies,
  ) async {
    try {
      // Register the user with the phone number (we're using an email-like identifier for Firebase Auth)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: '$phone@phone.com', // Treat phone as an email-like identifier
        password: password,
      );
      final user = userCredential.user;

      // Save user to Firestore if the user is successfully created
      if (user != null) {
        await _saveUserToFirestore(user.uid, phone, username, companies);
        print("User created and saved to Firestore.");
      }

      return user;
    } catch (e) {
      print('Error during user creation with phone: $e');
      return null;
    }
  }

  // Save user data to Firestore (for both email and phone)
  Future<void> _saveUserToFirestore(
    String uid,
    String identifier,
    String username,
    List<String> companies,
  ) async {
    try {
      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (!userDoc.exists) {
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'identifier': identifier,
          'username': username,
          'companies': companies,
          'createdAt': FieldValue.serverTimestamp(),
        });
        print("User successfully saved to Firestore!");
      } else {
        print("User already exists in Firestore.");
      }
    } catch (e) {
      print('Error saving user to Firestore: $e');
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

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      print('Error sending password reset email: $e');
    }
  }
}
