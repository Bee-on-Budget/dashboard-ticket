import 'package:flutter/material.dart';
import '../../service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isEmailSelected = true; // Toggle between Email and Phone

  // Register user with email and password
  void _registerWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final user =
        await AuthService().createUserWithEmailAndPassword(email, password);
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  // Register user with phone number and password
  void _registerWithPhone() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final user =
        await AuthService().createUserWithPhoneAndPassword(phone, password);
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Toggle between Email and Phone
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Email'),
                  selected: isEmailSelected,
                  onSelected: (value) {
                    setState(() {
                      isEmailSelected = true;
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
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Email Registration
            if (isEmailSelected)
              Column(
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerWithEmail,
                    child: const Text('Register with Email'),
                  ),
                ],
              ),

            // Phone Registration
            if (!isEmailSelected)
              Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    decoration:
                        const InputDecoration(labelText: 'Phone Number'),
                    keyboardType: TextInputType.phone,
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _registerWithPhone,
                    child: const Text('Register with Phone'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
