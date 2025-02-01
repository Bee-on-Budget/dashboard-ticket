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

  bool _isEmailSelected = true;
  List<String> _companies = [];
  List<String> _selectedPaymentMethods = [];
  String _selectedRole = 'user';

  final List<String> _availablePaymentMethods = [
    'Card',
    'Account',
    'Cash',
    'PayPal',
    'Bank Transfer',
  ];
  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final emailOrPhone = _isEmailSelected
        ? _emailController.text.trim()
        : _phoneController.text.trim();

    if (username.isEmpty ||
        _companies.isEmpty ||
        _selectedPaymentMethods.isEmpty) {
      _showSnackBar('Please fill all fields');
      return;
    }

    _showLoadingDialog();

    final user = _isEmailSelected
        ? await AuthService().createUserWithEmailAndPassword(
            emailOrPhone,
            password,
            username,
            _companies,
            _selectedPaymentMethods, // Pass as list, not string
            _selectedRole,
          )
        : await AuthService().createUserWithPhoneAndPassword(
            emailOrPhone,
            password,
            username,
            _companies,
            _selectedPaymentMethods, // Pass as list, not string
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
        _companies.add(company);
        _companyController.clear();
      });
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
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
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 600 : screenWidth - 40,
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.symmetric(vertical: 20.0),
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
                  'Create a New Account',
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
          _buildTextField(_emailController, 'Email', Icons.email,
              keyboardType: TextInputType.emailAddress),
        if (!_isEmailSelected)
          _buildTextField(_phoneController, 'Phone', Icons.phone,
              keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField(_passwordController, 'Password', Icons.lock,
            isPassword: true),
        const SizedBox(height: 16),
        _buildTextField(_companyController, 'Add Company', Icons.business),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _addCompany,
          child:
              const Text('Add Company', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF44564A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildCompanyChips(),
        const SizedBox(height: 24),
        _buildPaymentMethodMultiSelect(),
        const SizedBox(height: 24),
        _buildRoleDropdown(),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _registerUser,
          child: Text(
            _isEmailSelected ? 'Register with Email' : 'Register with Phone',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF44564A),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
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
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        prefixIcon: Icon(icon, color: const Color(0xFF44564A)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      obscureText: isPassword,
      keyboardType: keyboardType,
    );
  }

  Widget _buildCompanyChips() {
    return Wrap(
      spacing: 8,
      children: _companies
          .map((company) => Chip(
                label: Text(company),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _companies.remove(company));
                },
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ))
          .toList(),
    );
  }

  Widget _buildPaymentMethodMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Payment Methods',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: _availablePaymentMethods.map((method) {
            final isSelected = _selectedPaymentMethods.contains(method);
            return FilterChip(
              label: Text(method),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedPaymentMethods.add(method);
                  } else {
                    _selectedPaymentMethods.remove(method);
                  }
                });
              },
              selectedColor: const Color(0xFF44564A),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRoleDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Role',
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        prefixIcon: Icon(Icons.security, color: const Color(0xFF44564A)),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
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
