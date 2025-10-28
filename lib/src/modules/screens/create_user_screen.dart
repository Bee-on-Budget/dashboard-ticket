import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _paymentMethodController =
      TextEditingController();
  final FocusNode _companyFocusNode = FocusNode();

  bool _isPasswordVisible = false;
  bool _isEmailSelected = true;
  bool _showCompanySuggestions = false;
  bool _isLoadingCompanies = true;

  final List<String> _companies = [];
  final List<String> _paymentMethods = [];
  final List<String> _allCompanies = [];
  late TextEditingController _companyController;
  String _selectedRole = 'user';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> _filteredCompanies = [];

  @override
  void initState() {
    super.initState();
    _companyController = TextEditingController();
    _loadCompaniesFromFirestore();
    _companyController.addListener(_onCompanyTextChanged);
    _companyFocusNode.addListener(_onCompanyFocusChanged);
  }

  Future<void> _loadCompaniesFromFirestore() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final allCompanies = <String>{};

      for (final doc in querySnapshot.docs) {
        final userData = doc.data();
        if (userData['companies'] != null) {
          final userCompanies = List<String>.from(userData['companies']);
          allCompanies.addAll(userCompanies);
        }
      }

      setState(() {
        _allCompanies.addAll(allCompanies.toList());
        _filteredCompanies = _allCompanies;
        _isLoadingCompanies = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCompanies = false;
      });
      _showSnackBar('Failed to load companies: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _usernameController.dispose();
    _companyController.dispose();
    _paymentMethodController.dispose();
    _companyFocusNode.dispose();
    super.dispose();
  }

  void _onCompanyFocusChanged() {
    setState(() {
      _showCompanySuggestions = _companyFocusNode.hasFocus;
    });
  }

  void _onCompanyTextChanged() {
    final query = _companyController.text.toLowerCase();
    setState(() {
      _filteredCompanies = _allCompanies
          .where((company) => company.toLowerCase().contains(query))
          .toList();
    });
  }

  void _selectCompany(String company) {
    final trimmedCompany = company.trim();
    if (trimmedCompany.isEmpty) return;

    if (!_companies.contains(trimmedCompany)) {
      setState(() {
        _companies.add(trimmedCompany);
        _companyController.clear();

        // Add to suggestions if new
        if (!_allCompanies.contains(trimmedCompany)) {
          _allCompanies.add(trimmedCompany);
          _filteredCompanies = _allCompanies;
        }

        _showCompanySuggestions = false;
      });
    } else {
      _showSnackBar('Company already added');
      setState(() {
        _companyController.clear();
        _showCompanySuggestions = false;
      });
    }
  }

  Future<void> _registerUser() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();
    final emailOrPhone = _isEmailSelected
        ? _emailController.text.trim()
        : _phoneController.text.trim();

    if (username.isEmpty ||
        password.isEmpty ||
        _companies.isEmpty ||
        _paymentMethods.isEmpty) {
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
              companies: _companies,
              paymentMethods: _paymentMethods,
              role: _selectedRole,
            )
          : await AuthService().createUserWithPhoneAndPassword(
              phone: emailOrPhone,
              password: password,
              username: username,
              companies: _companies,
              paymentMethods: _paymentMethods,
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
    _companyController.clear();
    _paymentMethodController.clear();
    setState(() {
      _companies.clear();
      _paymentMethods.clear();
      _selectedRole = 'user';
    });
  }

  void _addCompany() {
    final company = _companyController.text.trim();
    if (company.isNotEmpty && !_companies.contains(company)) {
      setState(() {
        _companies.add(company);
        _companyController.clear();
        if (!_allCompanies.contains(company)) {
          _allCompanies.add(company);
          _filteredCompanies = _allCompanies;
        }
      });
    }
  }

  void _addPaymentMethod() {
    final method = _paymentMethodController.text.trim();
    if (method.isNotEmpty) {
      setState(() {
        _paymentMethods.add(method);
        _paymentMethodController.clear();
      });
    }
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
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
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
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 600 : screenWidth - 40,
            padding: const EdgeInsets.all(24.0),
            margin: const EdgeInsets.only(top: 80.0, bottom: 40.0),
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
        _buildCompanyField(),
        const SizedBox(height: 24),
        _buildPaymentMethodField(),
        const SizedBox(height: 24),
        _buildRoleDropdown(),
        const SizedBox(height: 32),
        _buildRegisterButton(),
      ],
    );
  }

  Widget _buildCompanyField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _companyController,
          focusNode: _companyFocusNode,
          decoration: InputDecoration(
            labelText: 'Add Company',
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            prefixIcon: const Icon(Icons.business, color: Color(0xFF44564A)),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add, color: Color(0xFF44564A)),
              onPressed: () {
                if (_companyController.text.trim().isNotEmpty) {
                  _selectCompany(_companyController.text.trim());
                }
              },
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
          ),
          onTap: () {
            setState(() => _showCompanySuggestions = true);
          },
        ),
        if (_isLoadingCompanies)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: LinearProgressIndicator(),
          ),
        if (_showCompanySuggestions && _filteredCompanies.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _filteredCompanies.length,
              primary: false,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                final company = _filteredCompanies[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    // onTapDown fires before focus changes on web/desktop
                    onTapDown: (_) {
                      // unfocus immediately to avoid the TextField stealing the tap
                      FocusScope.of(context).unfocus();
                      // select company right away
                      _selectCompany(company);
                      // ensure the UI updates
                      if (mounted) setState(() {});
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(company),
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        _buildCompanyChips(),
      ],
    );
  }

  Widget _buildPaymentMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          _paymentMethodController,
          'Add Payment Method',
          Icons.payment,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _addPaymentMethod,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF44564A),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Add Payment Method',
            style: TextStyle(color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodChips(),
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

  Widget _buildCompanyChips() {
    return Wrap(
      spacing: 8,
      children: _companies
          .map((company) => Chip(
                label: Text(company),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _companies.remove(company)),
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ))
          .toList(),
    );
  }

  Widget _buildPaymentMethodChips() {
    return Wrap(
      spacing: 8,
      children: _paymentMethods
          .map((method) => Chip(
                label: Text(method),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => setState(() => _paymentMethods.remove(method)),
                backgroundColor: Colors.grey[200],
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              ))
          .toList(),
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
    return ElevatedButton(
      onPressed: _registerUser,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF44564A),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        _isEmailSelected ? 'Register with Email' : 'Register with Phone',
        style: const TextStyle(color: Colors.white),
      ),
    );
  }
}
