import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isEmailSelected = true; // Toggle between email and phone

  /// Login method
  void _login() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isNotEmpty && password.isNotEmpty) {
      final user = isEmailSelected
          ? await AuthService()
              .signInWithEmailAndPassword(identifier, password) // Email login
          : await AuthService()
              .signInWithPhoneAndPassword(identifier, password); // Phone login

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Login failed. Please check your credentials.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both identifier and password')),
      );
    }
  }

  /// Forgot password method
  void _forgotPassword() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isNotEmpty) {
      if (isEmailSelected) {
        await AuthService().sendPasswordResetEmail(identifier); // Email reset
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password reset email sent')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password reset for phone is not supported.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your email or phone number')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Toggle between Email and Phone login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Email'),
                  selected: isEmailSelected,
                  onSelected: (value) {
                    setState(() {
                      isEmailSelected = true;
                      _identifierController.clear(); // Clear the input
                    });
                  },
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('Phone'),
                  selected: !isEmailSelected,
                  onSelected: (value) {
                    setState(() {
                      isEmailSelected = false;
                      _identifierController.clear(); // Clear the input
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Input field for email or phone
            TextField(
              controller: _identifierController,
              decoration: InputDecoration(
                labelText: isEmailSelected ? 'Email' : 'Phone Number',
              ),
              keyboardType: isEmailSelected
                  ? TextInputType.emailAddress
                  : TextInputType.phone,
            ),
            const SizedBox(height: 10),

            // Password field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),

            // Login button
            ElevatedButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            TextButton(
              onPressed: _forgotPassword,
              child: const Text('Forgot Password?'),
            ),

            const SizedBox(height: 20),

            // Navigation to registration screen
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/createUser');
              },
              child: const Text('Create an Account'),
            ),
          ],
        ),
      ),
    );
  }
}
