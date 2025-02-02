import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const List<String> validPaymentMethods = [
    'Card',
    'Account',
    'Cash',
    'PayPal',
    'Google Pay',
    'Apple Pay',
    'Bank Transfer',
  ];

  // Create a user with email and password
  Future<User?> createUserWithEmailAndPassword(
    String email,
    String password,
    String username,
    List<String> companies,
    List<String> paymentMethods, // Multiple payment methods
    String role,
  ) async {
    // Validate payment methods
    if (!paymentMethods
        .every((method) => validPaymentMethods.contains(method))) {
      print(
          'Invalid payment methods: ${paymentMethods.where((method) => !validPaymentMethods.contains(method)).join(', ')}');
      return null;
    }

    try {
      // Create user in Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Store user info in Firestore
      await _saveUserToFirestore(
        userCredential.user!.uid,
        email, // Use email as the identifier
        username,
        companies,
        paymentMethods,
        role,
      );

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
    List<String> paymentMethods, // Multiple payment methods
    String role,
  ) async {
    // Validate payment methods
    if (!paymentMethods
        .every((method) => validPaymentMethods.contains(method))) {
      print(
          'Invalid payment methods: ${paymentMethods.where((method) => !validPaymentMethods.contains(method)).join(', ')}');
      return null;
    }

    try {
      // Create a fake email for Firebase Authentication
      final fakeEmail = '$phone@phone.com';

      // Create user in Firebase Authentication
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: fakeEmail,
        password: password,
      );

      // Store user info in Firestore
      await _saveUserToFirestore(
        userCredential.user!.uid,
        phone, // Use phone as the identifier
        username,
        companies,
        paymentMethods,
        role,
      );

      return userCredential.user;
    } catch (e) {
      print('Error during user creation with phone: $e');
      return null;
    }
  }

  // Save user data to Firestore (for both email and phone)
  Future<void> _saveUserToFirestore(
    String uid,
    String identifier, // Can be email or phone
    String username,
    List<String> companies,
    List<String> paymentMethods, // Multiple payment methods
    String role,
  ) async {
    try {
      // Check if the user already exists in Firestore
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();

      if (!userDoc.exists) {
        // Save user data to Firestore
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'identifier': identifier, // Store email or phone
          'username': username,
          'companies': companies,
          'paymentMethods': paymentMethods, // Save list of payment methods
          'role': role,
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

  // Sign in with phone number and password and check user role
  Future<User?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      // Use the phone number as an email-like identifier
      final fakeEmail = '$phone@phone.com';

      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: fakeEmail,
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
}
