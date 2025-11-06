import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';
import '../../service/data_service.dart';
import 'UserDetailsScreen.dart';
import 'merged_screen.dart';
import 'tickets_screen.dart';
import '../../config/enums/payment_methods.dart';
import '../../config/enums/user_role.dart';
import '../../config/db_collections.dart';
import '../models/company.dart';

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

  // NEW: Get payment methods for each company separately
  Future<Map<String, List<PaymentMethods>>> _getPaymentMethodsByCompany(
      List<String> companyNames) async {
    if (companyNames.isEmpty) return {};

    try {
      final companiesSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.companies)
          .where('name', whereIn: companyNames)
          .get();

      final Map<String, List<PaymentMethods>> companyPaymentMethods = {};

      for (var doc in companiesSnapshot.docs) {
        final data = doc.data();
        final companyName = data['name'] as String;
        final methods = data['paymentMethods'] as List<dynamic>? ?? [];

        final paymentMethods = <PaymentMethods>[];
        for (var method in methods) {
          final pm = PaymentMethods.fromString(method.toString());
          if (pm != null) {
            paymentMethods.add(pm);
          }
        }

        companyPaymentMethods[companyName] = paymentMethods;
      }

      return companyPaymentMethods;
    } catch (e) {
      debugPrint('Error fetching company payment methods: $e');
      return {};
    }
  }

  Future<void> _saveUserChanges({
    required User originalUser,
    required String username,
    required String email,
    required String phone,
    required String companies,
    required UserRole role,
    required bool isActive,
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
      role: role,
      paymentMethods: originalUser.paymentMethods,
      createdAt: originalUser.createdAt,
      companies: updatedCompanies,
      isActive: isActive,
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
    UserRole selectedRole = user.role;
    bool isActive = user.isActive;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) {
        return StreamBuilder<List<Company>>(
          stream: DataService.getCompanies(),
          builder: (context, companiesSnapshot) {
            final companiesList = companiesSnapshot.data ?? [];
            final companiesNames = companiesList.map((c) => c.name).toList();

            return StatefulBuilder(
              builder: (context, setDialogState) {
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

                          // Role Dropdown
                          DropdownButtonFormField<UserRole>(
                            value: selectedRole,
                            decoration: InputDecoration(
                              labelText: 'Role',
                              prefixIcon:
                                  Icon(Icons.security, color: Colors.grey[600]),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide:
                                    BorderSide(color: Colors.grey[400]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.primaryColor,
                                  width: 2,
                                ),
                              ),
                              filled: true,
                              fillColor: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[100],
                            ),
                            items: [UserRole.admin, UserRole.user]
                                .map((role) => DropdownMenuItem(
                                      value: role,
                                      child: Text(role.toString()),
                                    ))
                                .toList(),
                            onChanged: (role) {
                              setDialogState(() {
                                selectedRole = role!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),

                          // Companies Field with dropdown suggestions
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildEditField(
                                controller: companiesController,
                                label: 'Companies',
                                icon: Icons.business_outlined,
                                hintText:
                                    'Separate with commas or select from list',
                              ),
                              if (companiesNames.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Available Companies:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: companiesNames.map((companyName) {
                                    final isSelected = companiesController.text
                                        .split(',')
                                        .map((e) => e.trim())
                                        .contains(companyName);
                                    return FilterChip(
                                      label: Text(companyName),
                                      selected: isSelected,
                                      onSelected: (selected) {
                                        setDialogState(() {
                                          final currentCompanies =
                                              companiesController.text
                                                  .split(',')
                                                  .map((e) => e.trim())
                                                  .where((e) => e.isNotEmpty)
                                                  .toList();
                                          if (selected) {
                                            if (!currentCompanies
                                                .contains(companyName)) {
                                              currentCompanies.add(companyName);
                                            }
                                          } else {
                                            currentCompanies
                                                .remove(companyName);
                                          }
                                          companiesController.text =
                                              currentCompanies.join(', ');
                                        });
                                      },
                                      selectedColor:
                                          theme.primaryColor.withOpacity(0.3),
                                      checkmarkColor: theme.primaryColor,
                                    );
                                  }).toList(),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Info box about payment methods
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline,
                                    color: Colors.blue, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Payment methods are inherited from assigned companies',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[900],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Active Status
                          Row(
                            children: [
                              Text(
                                'Active:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                  role: selectedRole,
                                  isActive: isActive,
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
          },
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
                            side: BorderSide(
                              color: user.isActive ? Colors.green : Colors.grey,
                              width: 2,
                            ),
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
                                child: FutureBuilder<
                                    Map<String, List<PaymentMethods>>>(
                                  future: _getPaymentMethodsByCompany(
                                      user.companies),
                                  builder: (context, paymentSnapshot) {
                                    final companyPaymentMethods =
                                        paymentSnapshot.data ?? {};

                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        _buildDetailRow('Email', user.email),
                                        _buildDetailRow(
                                            'Phone Number', user.phoneNumber),

                                        // Display companies with their payment methods
                                        if (user.companies.isNotEmpty) ...[
                                          const SizedBox(height: 12),
                                          const Text(
                                            'Companies & Payment Methods:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          if (paymentSnapshot.connectionState ==
                                              ConnectionState.waiting)
                                            const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Center(
                                                  child:
                                                      CircularProgressIndicator()),
                                            )
                                          else
                                            ...user.companies
                                                .map((companyName) {
                                              final paymentMethods =
                                                  companyPaymentMethods[
                                                          companyName] ??
                                                      [];
                                              return Container(
                                                margin: const EdgeInsets.only(
                                                    bottom: 12),
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue
                                                      .withOpacity(0.05),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color: Colors.blue
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.business,
                                                          size: 18,
                                                          color: Colors.blue,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Text(
                                                          companyName,
                                                          style:
                                                              const TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 15,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Icon(
                                                          Icons.payment,
                                                          size: 16,
                                                          color: Colors.grey,
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child: Text(
                                                            paymentMethods
                                                                    .isEmpty
                                                                ? 'No payment methods'
                                                                : paymentMethods
                                                                    .map((pm) =>
                                                                        pm.toString())
                                                                    .join(', '),
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[700],
                                                              fontSize: 13,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                        ],

                                        _buildDetailRow(
                                          'Created At',
                                          user.createdAt == null
                                              ? 'No Date'
                                              : DateFormat('yyyy MMM, dd')
                                                  .format(user.createdAt!),
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
                                              onPressed: () =>
                                                  _editUserInfo(user),
                                              tooltip: 'Edit User',
                                            ),
                                          ],
                                        ),
                                      ],
                                    );
                                  },
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
