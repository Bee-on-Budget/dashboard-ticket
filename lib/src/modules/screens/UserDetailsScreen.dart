import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/db_collections.dart';
import '../../config/enums/payment_methods.dart';
import '../../service/data_service.dart';

class AbsolutelyVisibleUserDetailsScreen extends StatefulWidget {
  final String userId;
  final String username;
  final bool isActive;

  const AbsolutelyVisibleUserDetailsScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.isActive,
  });

  @override
  State<AbsolutelyVisibleUserDetailsScreen> createState() =>
      _AbsolutelyVisibleUserDetailsScreenState();
}

class _AbsolutelyVisibleUserDetailsScreenState
    extends State<AbsolutelyVisibleUserDetailsScreen> {
  late bool _currentStatus;
  List<String> userCompanies = [];
  bool isLoadingCompanies = false;
  Map<String, List<PaymentMethods>> companyPaymentMethods = {};
  bool isLoadingPaymentMethods = false;

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.isActive;
    _loadUserCompaniesAndPaymentMethods();
  }

  Future<void> _loadUserCompaniesAndPaymentMethods() async {
    setState(() {
      isLoadingCompanies = true;
      isLoadingPaymentMethods = true;
    });

    try {
      final doc = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final companies = data['companies'] as List<dynamic>? ?? [];
        final companyNames = companies.map((e) => e.toString()).toList();

        setState(() {
          userCompanies = companyNames;
          isLoadingCompanies = false;
        });

        // Load payment methods for each company
        if (companyNames.isNotEmpty) {
          final companiesSnapshot = await FirebaseFirestore.instance
              .collection(DbCollections.companies)
              .where('name', whereIn: companyNames)
              .get();

          final Map<String, List<PaymentMethods>> paymentMethodsMap = {};

          for (var companyDoc in companiesSnapshot.docs) {
            final companyData = companyDoc.data();
            final companyName = companyData['name'] as String;
            final methods =
                companyData['paymentMethods'] as List<dynamic>? ?? [];

            final paymentMethods = <PaymentMethods>[];
            for (var method in methods) {
              final pm = PaymentMethods.fromString(method.toString());
              if (pm != null) {
                paymentMethods.add(pm);
              }
            }

            paymentMethodsMap[companyName] = paymentMethods;
          }

          setState(() {
            companyPaymentMethods = paymentMethodsMap;
            isLoadingPaymentMethods = false;
          });
        } else {
          setState(() {
            isLoadingPaymentMethods = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading companies and payment methods: $e');
      setState(() {
        isLoadingCompanies = false;
        isLoadingPaymentMethods = false;
      });
    }
  }

  Future<void> _showCompanyDeactivateDialog(BuildContext context) async {
    if (userCompanies.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User has no companies associated')),
      );
      return;
    }

    String? selectedCompany = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Company to Deactivate'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userCompanies.length,
            itemBuilder: (context, index) {
              final company = userCompanies[index];
              return ListTile(
                title: Text(company),
                subtitle: Text(
                  companyPaymentMethods[company]?.isNotEmpty == true
                      ? 'Payment methods: ${companyPaymentMethods[company]!.map((pm) => pm.toString()).join(', ')}'
                      : 'No payment methods',
                  style: const TextStyle(fontSize: 12),
                ),
                onTap: () => Navigator.pop(context, company),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedCompany != null && mounted) {
      await _deactivateCompanyUsers(selectedCompany, context);
    }
  }

  Future<void> _deactivateCompanyUsers(
      String companyName, BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: Text(
          'This will deactivate the company "$companyName" and ALL users assigned to it. This action cannot be undone. Do you want to continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      // Step 1: Get the company document
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection('companies')
          .where('name', isEqualTo: companyName)
          .get();

      if (companiesSnapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Company not found'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 2: Deactivate the company (this will auto-deactivate all users via DataService)
      final companyBatch = FirebaseFirestore.instance.batch();
      for (final doc in companiesSnapshot.docs) {
        companyBatch.update(doc.reference, {'isActive': false});
      }
      await companyBatch.commit();

      // Step 3: Use DataService to deactivate all users in the company
      await DataService.deactivateCompanyUsers(companyName);

      // Update local status if current user is affected
      if (userCompanies.contains(companyName)) {
        setState(() => _currentStatus = false);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Deactivated company "$companyName" and all its users'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF44564A),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        elevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.blue[50],
                      child: Text(
                        widget.username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _currentStatus
                            ? Colors.green.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _currentStatus ? Colors.green : Colors.grey,
                        ),
                      ),
                      child: Text(
                        _currentStatus ? 'Active account' : 'Inactive account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: _currentStatus ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),

                    // Loading indicator
                    if (isLoadingCompanies || isLoadingPaymentMethods)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),

                    // Companies and Payment Methods Section
                    if (!isLoadingCompanies &&
                        !isLoadingPaymentMethods &&
                        userCompanies.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'Companies & Payment Methods',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...userCompanies.map((company) {
                        final paymentMethods =
                            companyPaymentMethods[company] ?? [];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Company Name
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.business,
                                      size: 20,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      company,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Payment Methods
                              const Text(
                                'Payment Methods:',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (paymentMethods.isEmpty)
                                const Text(
                                  'No payment methods available',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: paymentMethods.map((method) {
                                    return Chip(
                                      avatar: const Icon(
                                        Icons.payment,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      label: Text(
                                        method.toString(),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor:
                                          Colors.blue.withOpacity(0.15),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                        vertical: 2,
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    // No companies message
                    if (!isLoadingCompanies && userCompanies.isEmpty) ...[
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text(
                        'No companies assigned',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Warning Card
            if (userCompanies.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Deactivating a company will deactivate all users in it',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Deactivate Company Button
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () => _showCompanyDeactivateDialog(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Deactivate Co.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Status Toggle Button
                SizedBox(
                  width: 140,
                  child: ElevatedButton(
                    onPressed: () => _toggleStatus(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor:
                          _currentStatus ? Colors.red : Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      _currentStatus ? 'Deactivate' : 'Activate',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Back Button
            SizedBox(
              width: 200,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Back to List',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleStatus(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .doc(widget.userId)
          .update({'isActive': !_currentStatus});

      setState(() {
        _currentStatus = !_currentStatus;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(!_currentStatus ? 'User deactivated' : 'User activated'),
            backgroundColor: !_currentStatus ? Colors.red : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
