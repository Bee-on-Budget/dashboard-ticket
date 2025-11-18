import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/db_collections.dart';
import '../../config/enums/user_role.dart';

// NOTE: Removed PaymentMethods enum import - we're using raw strings now

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
  // Changed to store payment methods as raw strings from Firestore
  Map<String, List<String>> companyPaymentMethods = {};
  bool isLoadingPaymentMethods = false;
  // Store user payment methods as raw strings
  List<String> userPaymentMethods = [];

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

        // Load user's payment methods directly as strings - NO ENUM CONVERSION
        final userMethods = data['paymentMethods'] as List<dynamic>? ?? [];
        final userPaymentMethodsList = userMethods
            .map((method) => method.toString())
            .where((method) => method.isNotEmpty)
            .toList();

        setState(() {
          userCompanies = companyNames;
          userPaymentMethods = userPaymentMethodsList;
          isLoadingCompanies = false;
        });

        // Load payment methods for each company
        if (companyNames.isNotEmpty) {
          final Map<String, List<String>> paymentMethodsMap = {};

          // Query all companies at once for better performance
          final companiesSnapshot = await FirebaseFirestore.instance
              .collection(DbCollections.companies)
              .get();

          debugPrint('Total companies in database: ${companiesSnapshot.docs.length}');
          
          // Create a map of company names to payment methods
          final companyMap = <String, List<String>>{};
          for (var doc in companiesSnapshot.docs) {
            final data = doc.data();
            final name = data['name'] as String? ?? '';
            final methods = data['paymentMethods'] as List<dynamic>? ?? [];
            
            final paymentMethods = methods
                .map((method) => method.toString())
                .where((method) => method.isNotEmpty)
                .toList();
            
            companyMap[name] = paymentMethods;
            debugPrint('Company: $name has ${paymentMethods.length} payment methods');
          }

          // Match user companies with database companies
          for (final companyName in companyNames) {
            if (companyMap.containsKey(companyName)) {
              paymentMethodsMap[companyName] = companyMap[companyName]!;
              debugPrint('✓ Matched company: $companyName with ${companyMap[companyName]!.length} methods');
            } else {
              paymentMethodsMap[companyName] = [];
              debugPrint('✗ No match for company: $companyName');
              debugPrint('  Available companies: ${companyMap.keys.join(", ")}');
            }
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
              final methods = companyPaymentMethods[company] ?? [];
              return ListTile(
                title: Text(company),
                subtitle: Text(
                  methods.isNotEmpty
                      ? 'Payment methods: ${methods.join(', ')}'
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
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.companies)
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

      final companyBatch = FirebaseFirestore.instance.batch();
      for (final doc in companiesSnapshot.docs) {
        companyBatch.update(doc.reference, {'isActive': false});
      }
      await companyBatch.commit();

      final usersSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .where('companies', arrayContains: companyName)
          .get();

      final userBatch = FirebaseFirestore.instance.batch();
      for (final userDoc in usersSnapshot.docs) {
        final userData = userDoc.data();
        final userRole = UserRole.fromString(userData['role'] ?? 'unknown');
        final userCompanies = List<String>.from(userData['companies'] ?? []);

        if (userRole == UserRole.admin) continue;

        bool hasOtherActiveCompany = false;
        for (final company in userCompanies) {
          if (company != companyName) {
            final companyDoc = await FirebaseFirestore.instance
                .collection(DbCollections.companies)
                .where('name', isEqualTo: company)
                .where('isActive', isEqualTo: true)
                .get();
            if (companyDoc.docs.isNotEmpty) {
              hasOtherActiveCompany = true;
              break;
            }
          }
        }

        if (!hasOtherActiveCompany) {
          userBatch.update(userDoc.reference, {'isActive': false});
        }
      }
      await userBatch.commit();

      if (userCompanies.contains(companyName)) {
        bool hasOtherActiveCompany = false;
        for (final company in userCompanies) {
          if (company != companyName) {
            final companyDoc = await FirebaseFirestore.instance
                .collection(DbCollections.companies)
                .where('name', isEqualTo: company)
                .where('isActive', isEqualTo: true)
                .get();
            if (companyDoc.docs.isNotEmpty) {
              hasOtherActiveCompany = true;
              break;
            }
          }
        }
        if (!hasOtherActiveCompany) {
          setState(() => _currentStatus = false);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Deactivated company "$companyName" and its users (excluding admins and users with other active companies)'),
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
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.waving_hand,
                    color: Colors.blue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Hi ${widget.username}!',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
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

                    if (isLoadingCompanies || isLoadingPaymentMethods)
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: CircularProgressIndicator(),
                      ),

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
                                  children: paymentMethods.map((methodString) {
                                    return Chip(
                                      avatar: const Icon(
                                        Icons.payment,
                                        size: 14,
                                        color: Colors.blue,
                                      ),
                                      label: Text(
                                        methodString, // Raw string from Firestore
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

                    if (!isLoadingCompanies && !isLoadingPaymentMethods) ...[
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      const Text(
                        'User Payment Methods',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (userPaymentMethods.isEmpty)
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
                          children: userPaymentMethods.map((methodString) {
                            return Chip(
                              avatar: const Icon(
                                Icons.payment,
                                size: 16,
                                color: Colors.green,
                              ),
                              label: Text(
                                methodString, // Raw string from Firestore
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.green.withOpacity(0.15),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 4,
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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