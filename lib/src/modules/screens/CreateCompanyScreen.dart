import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/db_collections.dart';
import '../../service/data_service.dart';
import '../models/company.dart';
import 'searchable_user_selection.dart';

class CreateCompanyScreen extends StatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  State<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}

class _CreateCompanyScreenState extends State<CreateCompanyScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _paymentMethodController =
      TextEditingController();

  final List<String> _paymentMethods = [];
  List<String> _selectedUserIds = [];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _paymentMethodController.dispose();
    super.dispose();
  }

  Future<void> _createCompany() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      _showSnackBar('Please fill in name, email, and phone');
      return;
    }

    if (_selectedUserIds.isEmpty) {
      _showSnackBar('Please select at least one user');
      return;
    }

    _showLoadingDialog();

    try {
      // Create company document
      final companyId = DateTime.now().millisecondsSinceEpoch.toString();
      final company = Company(
        id: companyId,
        name: name,
        paymentMethods: _paymentMethods,
        createdAt: DateTime.now(),
        isActive: true,
      );

      // Save company with additional fields
      await FirebaseFirestore.instance
          .collection(DbCollections.companies)
          .doc(companyId)
          .set({
        ...company.toJson(),
        'email': email,
        'phone': phone,
      });

      // Update selected users with company reference
      final batch = FirebaseFirestore.instance.batch();
      for (final userId in _selectedUserIds) {
        final userRef = FirebaseFirestore.instance
            .collection(DbCollections.users)
            .doc(userId);

        batch.update(userRef, {
          'companies': FieldValue.arrayUnion([name]),
        });
      }
      await batch.commit();

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSuccessDialog('Company created successfully!');
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
      _showSnackBar('An error occurred: ${e.toString()}');
    }
  }

  void _addPaymentMethod() {
    final method = _paymentMethodController.text.trim();
    if (method.isNotEmpty && !_paymentMethods.contains(method)) {
      setState(() {
        _paymentMethods.add(method);
        _paymentMethodController.clear();
      });
    } else if (_paymentMethods.contains(method)) {
      _showSnackBar('Payment method already added');
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
              Navigator.pop(context); // Go back to previous screen
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
        title: const Text('Create Company'),
        backgroundColor: const Color(0xFF44564A),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: screenWidth > 800 ? 700 : screenWidth - 40,
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
                  'Create a New Company',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF44564A),
                      ),
                ),
                const SizedBox(height: 24),
                _buildForm(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(_nameController, 'Company Name', Icons.business),
        const SizedBox(height: 16),
        _buildTextField(
          _emailController,
          'Email',
          Icons.email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          _phoneController,
          'Phone',
          Icons.phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 24),
        _buildPaymentMethodField(),
        const SizedBox(height: 24),
        _buildUserSelectionField(),
        const SizedBox(height: 32),
        _buildCreateButton(),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
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
      ),
      keyboardType: keyboardType,
    );
  }

  Widget _buildPaymentMethodField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _paymentMethodController,
                decoration: InputDecoration(
                  labelText: 'Add Payment Method',
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                  prefixIcon:
                      const Icon(Icons.payment, color: Color(0xFF44564A)),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.0),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _addPaymentMethod(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _addPaymentMethod,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF44564A),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Add',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPaymentMethodChips(),
      ],
    );
  }

  Widget _buildPaymentMethodChips() {
    if (_paymentMethods.isEmpty) {
      return const Text(
        'No payment methods added yet',
        style: TextStyle(color: Colors.grey),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
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

  Widget _buildUserSelectionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Users',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF44564A),
          ),
        ),
        const SizedBox(height: 12),
        // Use the SearchableUserSelection component
        SearchableUserSelection(
          initialSelectedUserIds: _selectedUserIds,
          onSelectionChanged: (selectedIds) {
            setState(() {
              _selectedUserIds = selectedIds;
            });
          },
        ),
        const SizedBox(height: 12),
        Text(
          '${_selectedUserIds.length} user(s) selected',
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _createCompany,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF44564A),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Create Company',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      ),
    );
  }
}
