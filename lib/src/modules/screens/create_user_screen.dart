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

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();

    _animationController =
        AnimationController(vsync: this, duration: Duration(seconds: 1));

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade300, Colors.blue.shade700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      'Create a New Account',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildChoiceChips(),
                    const SizedBox(height: 30),
                    _buildFormCard(),
                  ],
                ),
              ),
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
          selectedColor: Colors.blue.shade700,
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: isEmailSelected ? Colors.white : Colors.blue.shade700,
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
          selectedColor: Colors.blue.shade700,
          backgroundColor: Colors.grey[200],
          labelStyle: TextStyle(
            color: !isEmailSelected ? Colors.white : Colors.blue.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildTextField(
              controller: _usernameController,
              label: 'Username',
              icon: Icons.person,
            ),
            const SizedBox(height: 15),
            if (isEmailSelected) ...[
              _buildTextField(
                controller: _emailController,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                icon: Icons.lock,
              ),
            ],
            if (!isEmailSelected) ...[
              _buildTextField(
                controller: _phoneController,
                label: 'Phone Number',
                keyboardType: TextInputType.phone,
                icon: Icons.phone,
              ),
              const SizedBox(height: 15),
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
                icon: Icons.lock,
              ),
            ],
            const SizedBox(height: 20),
            _buildTextField(
              controller: _companyController,
              label: 'Add Company',
              icon: Icons.business,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _addCompany,
              child: const Text(
                'Add Company',
                style: TextStyle(
                  color: Colors.white, // White text color
                  fontWeight: FontWeight.bold, // Bold text for emphasis
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.blue.shade700, // Button background color
                padding: const EdgeInsets.symmetric(
                    vertical: 14.0, horizontal: 20.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0), // Rounded corners
                ),
                elevation: 5, // Slight elevation for a raised effect
              ),
            ),
            const SizedBox(height: 10),
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
            const SizedBox(height: 20),
            _buildRoleDropdown(),
            const SizedBox(height: 20),
            _buildSubmitButton(
              label: isEmailSelected
                  ? 'Register with Email'
                  : 'Register with Phone',
              onPressed:
                  isEmailSelected ? _registerWithEmail : _registerWithPhone,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.blue),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: Icon(Icons.security, color: Colors.blue.shade700),
        filled: true,
        fillColor: Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
      ),
      items: <String>['user', 'admin']
          .map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedRole = newValue!;
        });
      },
    );
  }

  Widget _buildSubmitButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue.shade700,
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 30.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        elevation: 5,
      ),
      child: Text(
        label,
        style: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }
}
