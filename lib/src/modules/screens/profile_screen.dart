import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../../service/data_service.dart';
import 'UserDetailsScreen.dart';
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
  String? _expandedUserId;
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expansionStates = {};
  final Map<String, GlobalKey> _itemKeys = {};
  double? _lastScrollPosition;

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
    _scrollController.dispose();
    super.dispose();
  }

  void _saveScrollPosition() {
    _lastScrollPosition = _scrollController.position.pixels;
  }

  void _restoreScrollPosition() {
    if (_lastScrollPosition != null) {
      _scrollController.jumpTo(_lastScrollPosition!);
    }
  }

  void _scrollToExpandedItem(String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemKeys.containsKey(userId)) {
        final key = _itemKeys[userId]!;
        final context = key.currentContext;
        if (context != null) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: 0.1,
          );
        }
      }
    });
  }

  Future<void> _saveUserChanges({
    required User originalUser,
    required String username,
    required String email,
    required String phone,
    required String companies,
  }) async {
    if (username.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username and email are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final updatedCompanies = companies
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final updatedUser = User(
      id: originalUser.id,
      username: username,
      email: email,
      phoneNumber: phone,
      role: originalUser.role,
      paymentMethods:
          originalUser.paymentMethods, // Keep original payment methods
      createdAt: originalUser.createdAt,
      companies: updatedCompanies,
      isActive: originalUser.isActive,
      userId: originalUser.userId,
    );

    try {
      await DataService.updateUser(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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

  Future<void> _editUserInfo(User user) async {
    final usernameController = TextEditingController(text: user.username);
    final emailController = TextEditingController(text: user.email);
    final phoneController = TextEditingController(text: user.phoneNumber);
    final companiesController = TextEditingController(
      text: user.companies.join(', '),
    );

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        color: Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Username Field
                  _buildEditField(
                    controller: usernameController,
                    label: 'Username',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  _buildEditField(
                    controller: emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),

                  // Phone Field
                  _buildEditField(
                    controller: phoneController,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Companies Field
                  _buildEditField(
                    controller: companiesController,
                    label: 'Companies',
                    icon: Icons.business_outlined,
                    hintText: 'Separate with commas (e.g., Google, Apple)',
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey,
                        ),
                        child: const Text('CANCEL'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => _saveUserChanges(
                          originalUser: user,
                          username: usernameController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          companies: companiesController.text,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 12),
                        ),
                        child: const Text('SAVE CHANGES'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEditField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[400]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: Theme.of(context).primaryColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[800]
            : Colors.grey[100],
      ),
      keyboardType: keyboardType,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Page'),
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
                      width: min(MediaQuery.of(context).size.width * 0.8, 350),
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
                      icon: const Icon(Icons.swap_horiz),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: (notification) {
                  _saveScrollPosition();
                  return false;
                },
                child: StreamBuilder<List<User>>(
                  stream: DataService.getUsers(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return const Center(child: Text('Something went wrong!'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('There are no users'));
                    }

                    final users = snapshot.data!;
                    final filteredUsers = _filterUsers(users);

                    for (var user in filteredUsers) {
                      _itemKeys.putIfAbsent(user.id, () => GlobalKey());
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_expandedUserId != null) {
                        _scrollToExpandedItem(_expandedUserId!);
                      } else {
                        _restoreScrollPosition();
                      }
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, idx) {
                        final user = filteredUsers[idx];
                        final isExpanded = _expansionStates[user.id] ?? false;

                        return Card(
                          key: _itemKeys[user.id],
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ExpansionTile(
                            initiallyExpanded: isExpanded,
                            maintainState: true,
                            onExpansionChanged: (expanded) {
                              setState(() {
                                _expansionStates[user.id] = expanded;
                                _expandedUserId = expanded ? user.id : null;
                                if (expanded) {
                                  _scrollToExpandedItem(user.id);
                                }
                              });
                            },
                            title: Text(
                              user.username,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                            subtitle: Text(
                              user.role.toString(),
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailRow('Email', user.email),
                                    _buildDetailRow(
                                        'Phone Number', user.phoneNumber),
                                    _buildDetailRow(
                                      'Payment Methods',
                                      user.paymentMethods
                                          .map((pm) => pm.toString())
                                          .join(', '),
                                    ),
                                    _buildDetailRow(
                                      'Created At',
                                      user.createdAt == null
                                          ? 'No Date'
                                          : DateFormat('yyyy MMM, dd')
                                              .format(user.createdAt!),
                                    ),
                                    _buildDetailRow(
                                      'Companies',
                                      user.companies.join(', '),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    TicketsScreen(
                                                  userId: user.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('View Tickets'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.blue,
                                            foregroundColor: Colors.white,
                                          ),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AbsolutelyVisibleUserDetailsScreen(
                                                  userId: user.id,
                                                  username: user.username,
                                                  isActive: user.isActive,
                                                ),
                                              ),
                                            );
                                          },
                                          child: const Text('Full Details'),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          color: Colors.green,
                                          onPressed: () => _editUserInfo(user),
                                          tooltip: 'Edit User',
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _onSearchChange() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  Timer? _debounce;

  void _switchSearch() {
    setState(() {
      _isSearchUsers = !_isSearchUsers;
      _searchText = '';
      _searchController.clear();
    });
  }

  List<User> _filterUsers(List<User> users) {
    if (_searchText.isEmpty) {
      return users;
    }
    return users.where((user) {
      if (_isSearchUsers) {
        return user.username.toLowerCase().contains(_searchText) ||
            user.email.toLowerCase().contains(_searchText);
      } else {
        return user.companies
            .any((company) => company.toLowerCase().contains(_searchText));
      }
    }).toList();
  }
}
