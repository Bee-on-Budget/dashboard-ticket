import 'package:flutter/material.dart';
import '../../service/auth_service.dart';

class CreateUserScreen extends StatefulWidget {
  const CreateUserScreen({Key? key}) : super(key: key);

  @override
  _CreateUserScreenState createState() => _CreateUserScreenState();
}

class _CreateUserScreenState extends State<CreateUserScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();

  bool isEmailSelected = true;
  List<String> companies = [];
  String _selectedRole = 'user';

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
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF44564A)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: const Color(0xFF44564A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 600 : screenWidth - 40,
            padding: const EdgeInsets.all(20.0),
            margin: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Create a New Account',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF44564A),
                      ),
                ),
                const SizedBox(height: 20),
                _buildChoiceChips(),
                const SizedBox(height: 20),
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
          label: const Text('Email'),
          selected: isEmailSelected,
          onSelected: (value) {
            setState(() {
              isEmailSelected = true;
            });
          },
          selectedColor: const Color(0xFF44564A),
          labelStyle: TextStyle(
            color: isEmailSelected ? Colors.white : Colors.black,
          ),
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
          selectedColor: const Color(0xFF44564A),
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
        const SizedBox(height: 15),
        if (isEmailSelected)
          _buildTextField(_emailController, 'Email', Icons.email,
              keyboardType: TextInputType.emailAddress),
        if (!isEmailSelected)
          _buildTextField(_phoneController, 'Phone', Icons.phone,
              keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildTextField(_passwordController, 'Password', Icons.lock,
            isPassword: true),
        const SizedBox(height: 15),
        _buildTextField(_companyController, 'Add Company', Icons.business),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _addCompany,
          child:
              const Text('Add Company', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF44564A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: companies
              .map((company) => Chip(
                    label: Text(company),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() {
                        companies.remove(company);
                      });
                    },
                    backgroundColor: Colors.grey[200],
                  ))
              .toList(),
        ),
        const SizedBox(height: 20),
        _buildRoleDropdown(),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: isEmailSelected ? _registerWithEmail : _registerWithPhone,
          child: Text(
            isEmailSelected ? 'Register with Email' : 'Register with Phone',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF44564A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
        prefixIcon: Icon(icon, color: const Color(0xFF44564A)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
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
        prefixIcon: Icon(Icons.security, color: const Color(0xFF44564A)),
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
