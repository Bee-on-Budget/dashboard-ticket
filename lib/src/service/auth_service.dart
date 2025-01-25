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
    String role, // Added role parameter
  ) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user info in Firestore with role
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'companies': companies,
        'role': role, // Save the role in Firestore
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
    String role, // Added role parameter
  ) async {
    try {
      // Register the user with the phone number (using an email-like identifier)
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: '$phone@phone.com', // Treat phone as email-like identifier
        password: password,
      );
      final user = userCredential.user;

      // Save user to Firestore with role
      if (user != null) {
        await _saveUserToFirestore(user.uid, phone, username, companies, role);
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
    String role,
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
          'role': role, // Save the role
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

  // Sign in with email and password and check user role
// Sign in with email and password and check user role
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Check user role
      final user = userCredential.user;
      if (user != null) {
        final role = await getRole(user.uid);
        if (role != null) {
          print("User role: $role");
          if (role == 'admin') {
            return user; // Allow admin users to proceed
          } else {
            print('Access denied: User is not an admin.');
            // Optionally, you could throw an exception or return a specific error message
            // throw Exception('Access denied: User is not an admin.');
            return null; // Return null or handle it as needed for non-admin users
          }
        }
      }
      return null;
    } catch (e) {
      print('Error during email sign-in: $e');
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
      print('Error fetching user role: $e');
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

  // Sign in with phone number and password and check user role
  Future<User?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      // Use the phone number as an email-like identifier
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: '$phone@phone.com', // Treat phone as email-like identifier
        password: password,
      );

      // Check user role
      final user = userCredential.user;
      if (user != null) {
        final role = await getRole(user.uid);
        if (role != null) {
          print("User role: $role");
          if (role == 'admin') {
            return user; // Allow admin users to proceed
          } else {
            print('Access denied: User is not an admin.');
            // Optionally, you could throw an exception or return a specific error message
            // throw Exception('Access denied: User is not an admin.');
            return null; // Return null or handle it as needed for non-admin users
          }
        }
      }
      return null;
    } catch (e) {
      print('Error during phone sign-in: $e');
      return null;
    }
  }
}
