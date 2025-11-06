import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../config/db_collections.dart';
import '../models/company.dart';
import '../models/user.dart';

class ManageCompaniesScreen extends StatefulWidget {
  const ManageCompaniesScreen({super.key});

  @override
  State<ManageCompaniesScreen> createState() => _ManageCompaniesScreenState();
}

class _ManageCompaniesScreenState extends State<ManageCompaniesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Stream<List<Company>> _getCompaniesStream() {
    return FirebaseFirestore.instance
        .collection('companies')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Company.fromJson(doc.data(), doc.id))
            .where((company) {
              if (_searchText.isEmpty) return true;
              return company.name.toLowerCase().contains(_searchText.toLowerCase()) ||
                  (company.email?.toLowerCase().contains(_searchText.toLowerCase()) ?? false) ||
                  (company.phone?.toLowerCase().contains(_searchText.toLowerCase()) ?? false);
            })
            .toList());
  }

  Future<void> _editCompany(Company company) async {
    final nameController = TextEditingController(text: company.name);
    final emailController = TextEditingController(text: company.email ?? '');
    final phoneController = TextEditingController(text: company.phone ?? '');
    final paymentMethodsController = TextEditingController(
      text: company.paymentMethods.join(', '),
    );
    bool isActive = company.isActive;

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit Company'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: paymentMethodsController,
                    decoration: const InputDecoration(
                      labelText: 'Payment Methods (comma-separated)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Active:'),
                      const SizedBox(width: 12),
                      Switch(
                        value: isActive,
                        onChanged: (value) {
                          setDialogState(() {
                            isActive = value;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final paymentMethods = paymentMethodsController.text
                        .split(',')
                        .map((e) => e.trim())
                        .where((e) => e.isNotEmpty)
                        .toList();

                    await FirebaseFirestore.instance
                        .collection('companies')
                        .doc(company.id)
                        .update({
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'paymentMethods': paymentMethods,
                      'isActive': isActive,
                    });

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Company updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _manageCompanyUsers(Company company) async {
    // Get all users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection(DbCollections.users)
        .where('isActive', isEqualTo: true)
        .get();

    final allUsers = usersSnapshot.docs
        .map((doc) => User.fromJson(doc.data(), doc.id))
        .toList();

    // Get users already in this company
    final currentUserIds = allUsers
        .where((user) => user.companies.contains(company.name))
        .map((user) => user.id)
        .toSet();

    List<String> selectedUserIds = currentUserIds.toList();

    return showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text('Manage Users - ${company.name}'),
            content: SizedBox(
              width: double.maxFinite,
              height: 400,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: allUsers.length,
                itemBuilder: (context, index) {
                  final user = allUsers[index];
                  final isSelected = selectedUserIds.contains(user.id);
                  return CheckboxListTile(
                    title: Text(user.username),
                    subtitle: Text(user.email),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          selectedUserIds.add(user.id);
                        } else {
                          selectedUserIds.remove(user.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final batch = FirebaseFirestore.instance.batch();

                    // Remove company from users no longer selected
                    for (final userId in currentUserIds) {
                      if (!selectedUserIds.contains(userId)) {
                        final userRef = FirebaseFirestore.instance
                            .collection(DbCollections.users)
                            .doc(userId);
                        batch.update(userRef, {
                          'companies': FieldValue.arrayRemove([company.name]),
                        });
                      }
                    }

                    // Add company to newly selected users
                    for (final userId in selectedUserIds) {
                      if (!currentUserIds.contains(userId)) {
                        final userRef = FirebaseFirestore.instance
                            .collection(DbCollections.users)
                            .doc(userId);
                        batch.update(userRef, {
                          'companies': FieldValue.arrayUnion([company.name]),
                        });
                      }
                    }

                    await batch.commit();

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Users updated successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _toggleCompanyStatus(Company company) async {
    try {
      final newStatus = !company.isActive;
      
      // Update company status
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(company.id)
          .update({'isActive': newStatus});

      // If deactivating, also deactivate all users with this company
      if (!newStatus) {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection(DbCollections.users)
            .where('companies', arrayContains: company.name)
            .get();

        final batch = FirebaseFirestore.instance.batch();
        for (final doc in usersSnapshot.docs) {
          batch.update(doc.reference, {'isActive': false});
        }
        await batch.commit();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? 'Company activated'
                  : 'Company and all its users deactivated',
            ),
            backgroundColor: newStatus ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Companies'),
        backgroundColor: const Color(0xFF44564A),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchText = value;
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Company>>(
              stream: _getCompaniesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No companies found'));
                }

                final companies = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: companies.length,
                  itemBuilder: (context, index) {
                    final company = companies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: company.isActive ? Colors.green : Colors.grey,
                          width: 2,
                        ),
                      ),
                      child: ExpansionTile(
                        title: Text(
                          company.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Text(
                          company.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: company.isActive ? Colors.green : Colors.grey,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (company.email != null)
                                  _buildDetailRow('Email', company.email!),
                                if (company.phone != null)
                                  _buildDetailRow('Phone', company.phone!),
                                if (company.paymentMethods.isNotEmpty)
                                  _buildDetailRow(
                                    'Payment Methods',
                                    company.paymentMethods.join(', '),
                                  ),
                                if (company.createdAt != null)
                                  _buildDetailRow(
                                    'Created',
                                    DateFormat('MMM dd, yyyy')
                                        .format(company.createdAt!),
                                  ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () => _manageCompanyUsers(company),
                                      icon: const Icon(Icons.people),
                                      label: const Text('Users'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _editCompany(company),
                                      icon: const Icon(Icons.edit),
                                      label: const Text('Edit'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () =>
                                          _toggleCompanyStatus(company),
                                      icon: Icon(company.isActive
                                          ? Icons.block
                                          : Icons.check_circle),
                                      label: Text(company.isActive
                                          ? 'Deactivate'
                                          : 'Activate'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: company.isActive
                                            ? Colors.red
                                            : Colors.green,
                                        foregroundColor: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/create-company');
        },
        backgroundColor: const Color(0xFF44564A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create Company'),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}