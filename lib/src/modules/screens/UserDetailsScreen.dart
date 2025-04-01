import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.isActive;
    _loadUserCompanies();
  }

  Future<void> _loadUserCompanies() async {
    setState(() => isLoadingCompanies = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final companies = data['companies'] as List<dynamic>? ?? [];
        setState(() {
          userCompanies = companies.map((e) => e.toString()).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading companies: $e');
    } finally {
      setState(() => isLoadingCompanies = false);
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

    if (selectedCompany != null) {
      await _deactivateCompanyUsers(selectedCompany, context);
    }
  }

  Future<void> _deactivateCompanyUsers(
      String company, BuildContext context) async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('companies', arrayContains: company)
          .get();

      final batch = FirebaseFirestore.instance.batch();

      for (final doc in usersSnapshot.docs) {
        batch.update(doc.reference, {'isActive': false});
      }

      await batch.commit();

      if (userCompanies.contains(company)) {
        setState(() => _currentStatus = false);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Deactivated all users of $company'),
          backgroundColor: Colors.green,
        ),
      );
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
        title: const Text(
          'User Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF44564A),
        iconTheme: IconThemeData(
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
                    Text(
                      _currentStatus ? 'Active account' : 'Inactive account',
                      style: TextStyle(
                        fontSize: 14,
                        color: _currentStatus ? Colors.green : Colors.grey,
                      ),
                    ),
                    if (isLoadingCompanies)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: CircularProgressIndicator(),
                      ),
                    if (userCompanies.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Associated Companies:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      ...userCompanies.map((company) => Text(company)).toList(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Action Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // View Tickets Button

                const SizedBox(width: 16),

                // Deactivate Company Button - Now always visible
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
          .collection('users')
          .doc(widget.userId)
          .update({'isActive': !_currentStatus});

      setState(() {
        _currentStatus = !_currentStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(!_currentStatus ? 'User deactivated' : 'User activated'),
          backgroundColor: !_currentStatus ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
