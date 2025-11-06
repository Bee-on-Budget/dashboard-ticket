import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/db_collections.dart';
import '../../service/auth_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({super.key});

  @override
  State<CreateUserScreen> createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isEmailSelected = true;

  String _selectedRole = 'user';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final emailOrPhone = _isEmailSelected
        ? _emailController.text.trim()
        : _phoneController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showSnackBar('Please fill all required fields');
      return;
    }

    _showLoadingDialog();

    try {
      final errorMessage = _isEmailSelected
          ? await AuthService().createUserWithEmailAndPassword(
              email: emailOrPhone,
              password: password,
              username: username,
              companies: [], // Empty companies list
              paymentMethods: [], // Empty payment methods
              role: _selectedRole,
            )
          : await AuthService().createUserWithPhoneAndPassword(
              phone: emailOrPhone,
              password: password,
              username: username,
              companies: [], // Empty companies list
              paymentMethods: [], // Empty payment methods
              role: _selectedRole,
            );

      if (mounted) {
        Navigator.pop(context);
      }

      if (errorMessage == null) {
        _resetForm();
        _showSuccessDialog('User created successfully!');
      } else {
        _showSnackBar(errorMessage);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      _showSnackBar('An error occurred: ${e.toString()}');
    }
  }

  void _resetForm() {
    _usernameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    setState(() {
      _selectedRole = 'user';
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacementNamed(context,
                  '/merged'); // Navigate to merged screen instead of profile
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
        backgroundColor: const Color(0xFF44564A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 600 : screenWidth - 40,
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.only(top: 40.0, bottom: 40.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 5,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Create a New User',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF44564A),
                      ),
                ),
                const SizedBox(height: 24),
                _buildAuthMethodToggle(),
                const SizedBox(height: 24),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthMethodToggle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildToggleButton('Email', _isEmailSelected, () {
          setState(() => _isEmailSelected = true);
        }),
        const SizedBox(width: 16),
        _buildToggleButton('Phone', !_isEmailSelected, () {
          setState(() => _isEmailSelected = false);
        }),
      ],
    );
  }

  Widget _buildToggleButton(
      String label, bool isSelected, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isSelected ? const Color(0xFF44564A) : Colors.grey[200],
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField(_usernameController, 'Username', Icons.person),
        const SizedBox(height: 16),
        if (_isEmailSelected)
          _buildTextField(
            _emailController,
            'Email',
            Icons.email,
            keyboardType: TextInputType.emailAddress,
          ),
        if (!_isEmailSelected)
          _buildTextField(
            _phoneController,
            'Phone',
            Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        const SizedBox(height: 16),
        _buildTextField(
          _passwordController,
          'Password',
          Icons.lock,
          isPassword: true,
        ),
        const SizedBox(height: 24),
        _buildRoleDropdown(),
        const SizedBox(height: 32),
        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPassword = false,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: const Color(0xFF44564A)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: const Color(0xFF44564A),
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
      ),
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: keyboardType,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        prefixIcon: const Icon(Icons.security, color: Color(0xFF44564A)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
      items: ['user', 'admin']
          .map((role) => DropdownMenuItem(
                value: role,
                child: Text(role),
              ))
          .toList(),
      onChanged: (role) => setState(() => _selectedRole = role!),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _registerUser,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF44564A),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _isEmailSelected
              ? 'Create User with Email'
              : 'Create User with Phone',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}

Future<void> createUserInFirestore(
    String uid, String name, String email, String selectedCompanyId) async {
  await FirebaseFirestore.instance.collection('users').doc(uid).set({
    'name': name,
    'email': email,
    'companyId': selectedCompanyId,
    'isActive': true,
    'nameLower': name.toLowerCase(), // <-- add this
    'createdAt': FieldValue.serverTimestamp(),
  });
}
