import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../../service/data_service.dart';
import 'merged_screen.dart';
import 'tickets_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final TextEditingController _searchController;
  bool _isSearchUsers = true;
  String _searchText = '';
  String? _expandedUserId; // Track which user is expanded

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
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 0),
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
                      child: ExpansionTile(
                        key: Key(filteredUsers[idx].id),
                        initiallyExpanded:
                            filteredUsers[idx].id == _expandedUserId,
                        onExpansionChanged: (isExpanded) {
                          setState(() {
                            _expandedUserId =
                                isExpanded ? filteredUsers[idx].id : null;
                          });
                        },
                        title: Text(
                          filteredUsers[idx].username,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        subtitle: Text(
                          filteredUsers[idx].role.toString(),
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildDetailRow(
                                    'Email', filteredUsers[idx].email),
                                _buildDetailRow('Phone Number',
                                    filteredUsers[idx].phoneNumber),
                                _buildDetailRow(
                                  'Payment Methods',
                                  filteredUsers[idx]
                                      .paymentMethods
                                      .map((pm) => pm.toString())
                                      .join(', '),
                                ),
                                _buildDetailRow(
                                  'Created At',
                                  filteredUsers[idx].createdAt == null
                                      ? 'No Date'
                                      : DateFormat('yyyy MMM, dd').format(
                                          filteredUsers[idx].createdAt!),
                                ),
                                _buildDetailRow(
                                  'Companies',
                                  filteredUsers[idx].companies.join(', '),
                                ),
                                SizedBox(height: 16),
                                Center(
                                  child: ElevatedButton(
                                    onPressed: () {
                                      // Navigate to TicketsScreen with the userId
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => TicketsScreen(
                                            userId: filteredUsers[idx].id,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Text('View Tickets'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
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
}
