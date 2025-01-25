import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../../service/auth_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  bool isEmailSelected = true;
  List<String> companies = [];
  String _selectedRole = 'user';
  final Color primaryColor =
      Color(0xFF44564A); // Updated to use the specified color

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  void _checkAdminAccess() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final role = await AuthService().getRole(user.uid);
      if (role != 'admin') {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }

  void _registerWithEmail() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (username.isEmpty || companies.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    _showLoadingDialog();
    final user = await AuthService().createUserWithEmailAndPassword(
      email,
      password,
      username,
      companies,
      _selectedRole,
    );
    Navigator.pop(context);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Registration failed');
    }
  }

  void _registerWithPhone() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (username.isEmpty || companies.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    _showLoadingDialog();
    final user = await AuthService().createUserWithPhoneAndPassword(
      phone,
      password,
      username,
      companies,
      _selectedRole,
    );
    Navigator.pop(context);

    if (user != null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      _showSnackBar('Registration failed');
    }
  }

  void _addCompany() {
    final company = _companyController.text.trim();
    if (company.isNotEmpty) {
      setState(() {
        companies.add(company);
        _companyController.clear();
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text('Create Account', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: Colors.white),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/home');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 800 : screenWidth,
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create a New Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 20),
                _buildChoiceChips(),
                SizedBox(height: 20),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChips() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ChoiceChip(
          label: Text('Email'),
          selected: isEmailSelected,
          onSelected: (value) {
            setState(() {
              isEmailSelected = true;
            });
          },
          selectedColor: primaryColor,
          labelStyle: TextStyle(
            color: isEmailSelected ? Colors.white : Colors.black,
          ),
        ),
        SizedBox(width: 10),
        ChoiceChip(
          label: Text('Phone'),
          selected: !isEmailSelected,
          onSelected: (value) {
            setState(() {
              isEmailSelected = false;
            });
          },
          selectedColor: primaryColor,
          labelStyle: TextStyle(
            color: !isEmailSelected ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        _buildTextField(_usernameController, 'Username', Icons.person),
        SizedBox(height: 15),
        if (isEmailSelected)
          _buildTextField(_emailController, 'Email', Icons.email,
              keyboardType: TextInputType.emailAddress),
        if (!isEmailSelected)
          _buildTextField(_phoneController, 'Phone', Icons.phone,
              keyboardType: TextInputType.phone),
        SizedBox(height: 15),
        _buildTextField(_passwordController, 'Password', Icons.lock,
            isPassword: true),
        SizedBox(height: 15),
        _buildTextField(_companyController, 'Add Company', Icons.business),
        SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addCompany,
          child: Text('Add Company', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
        SizedBox(height: 10),
        Wrap(
          children: companies
              .map((company) => Chip(
                    label: Text(company),
                    deleteIcon: Icon(Icons.close),
                    onDeleted: () {
                      setState(() {
                        companies.remove(company);
                      });
                    },
                  ))
              .toList(),
        ),
        SizedBox(height: 20),
        _buildRoleDropdown(),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: isEmailSelected ? _registerWithEmail : _registerWithPhone,
          child: Text(
              isEmailSelected ? 'Register with Email' : 'Register with Phone',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
        ),
      ],
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isPassword = false, TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: Icon(Icons.security, color: primaryColor),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: ['user', 'admin']
          .map((role) => DropdownMenuItem(value: role, child: Text(role)))
          .toList(),
      onChanged: (role) => setState(() => _selectedRole = role!),
    );
  }
}
