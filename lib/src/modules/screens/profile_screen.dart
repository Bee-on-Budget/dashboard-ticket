import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/user.dart';
import '../../service/data_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _searchController;
  bool _isSearchUsers = true;
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChange);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChange);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Page'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          spacing: 30,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 20,
                  children: [
                    SizedBox(
                      width: max(MediaQuery.of(context).size.width * 0.4, 350),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: _isSearchUsers
                              ? 'Search Users...'
                              : 'Search Companies...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey[200],
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF44564A),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _switchSearch,
                      tooltip: 'Switch Search',
                      icon: Icon(Icons.flip),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: StreamBuilder(
                stream: DataService.getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Something went wrong!'),
                    );
                  }
                  if (!snapshot.hasData) {
                    return Center(
                      child: Text('There are no users'),
                    );
                  }
                  final List<User> users = snapshot.data!;
                  final filteredUsers = _filterUsers(users);
                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, idx) => Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: InkWell(
                        onTap: () {
                          showUserDetailsDialog(context, filteredUsers[idx]);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                filteredUsers[idx].username,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              Text(
                                filteredUsers[idx].role.toString(),
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onSearchChange() {
    setState(() {
      _searchText = _searchController.text.toLowerCase();
    });
  }

  void _switchSearch() {
    setState(() {
      _isSearchUsers = !_isSearchUsers;
      _searchText = ''; // Clear search text when switching modes
      _searchController.clear();
    });
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchText.isEmpty) {
      return users;
    }
    return users.where((user) {
      if (_isSearchUsers) {
        // Search by username or email for users
        return user.username.toLowerCase().contains(_searchText) ||
            user.email.toLowerCase().contains(_searchText);
      } else {
        // Search by company names
        return user.companies
            .any((company) => company.toLowerCase().contains(_searchText));
      }
    }).toList();
  }

  void showUserDetailsDialog(BuildContext context, User user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('User Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Username', user.username),
                _buildDetailRow('Role', user.role.toString()),
                _buildDetailRow('Email', user.email),
                _buildDetailRow('Phone Number', user.phoneNumber),
                _buildDetailRow(
                  'Payment Methods',
                  user.paymentMethods.join(', '),
                ),
                _buildDetailRow(
                  'Created At',
                  user.createdAt == null
                      ? 'No Date'
                      : DateFormat('yyyy MMM,dd').format(user.createdAt!),
                ),
                _buildDetailRow('Companies', user.companies.join(', ')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}
