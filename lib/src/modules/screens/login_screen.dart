import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../service/auth_service.dart';

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
      final user =
          await AuthService().signInWithEmailAndPassword(identifier, password);

      if (user != null) {
        final role = await AuthService().getRole(user.uid);

        if (role == 'admin') {
          Navigator.pushReplacementNamed(
              context, '/merged'); // Admins go to CreateUser
        } else {
          Navigator.pushReplacementNamed(
              context, '/home'); // Regular users go to Home
        }
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
    final double screenWidth = MediaQuery.of(context).size.width;
    final double width = min(screenWidth * 0.4, 600); // Wider for big screens

    return Scaffold(
      backgroundColor: const Color(0xFFf5f5f5), // Light grey background
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: width * 0.1),
          child: Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 60),
                constraints: BoxConstraints(maxWidth: width),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Log In",
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4F4F4F),
                      ),
                    ),
                    SizedBox(height: 30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120, // Set the desired width
                          child: ChoiceChip(
                            label: const Text('Email'),
                            selected: isEmailSelected,
                            onSelected: (value) {
                              setState(() {
                                isEmailSelected = true;
                                _identifierController.clear();
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 120, // Set the desired width
                          child: ChoiceChip(
                            label: const Text('Phone'),
                            selected: !isEmailSelected,
                            onSelected: (value) {
                              setState(() {
                                isEmailSelected = false;
                                _identifierController.clear();
                              });
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),

                    // Input field for email or phone
                    TextField(
                      controller: _identifierController,
                      decoration: InputDecoration(
                        labelText: isEmailSelected ? 'Email' : 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon:
                            Icon(isEmailSelected ? Icons.email : Icons.phone),
                      ),
                      keyboardType: isEmailSelected
                          ? TextInputType.emailAddress
                          : TextInputType.phone,
                    ),
                    const SizedBox(height: 20),

                    // Password field
                    TextField(
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 30),

                    // Login button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        child: const Text('Login'),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white, // Text color
                          backgroundColor: Color(0XFF44564A),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          textStyle: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                    Center(
                      child: TextButton(
                        onPressed: _forgotPassword,
                        child: const Text('Forgot Password?'),
                        style: TextButton.styleFrom(
                          foregroundColor: Color(0XFF44564A),
                          textStyle: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -70,
                child: Image.asset(
                  'assets/images/logo-round.png',
                  width: width * 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
