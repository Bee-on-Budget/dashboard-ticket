import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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

  double? _getItemOffset(BuildContext context, {double alignment = 0.0}) {
    final renderObject = context.findRenderObject();
    if (renderObject == null || !renderObject.attached) {
      return null;
    }

    final RenderAbstractViewport? viewport =
        RenderAbstractViewport.of(renderObject);
    final ScrollableState? scrollable = Scrollable.of(context);

    if (viewport == null || scrollable == null) {
      return null;
    }

    return viewport.getOffsetToReveal(renderObject, alignment).offset;
  }

  void _scrollToExpandedItem(String userId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemKeys.containsKey(userId)) {
        final key = _itemKeys[userId]!;
        final context = key.currentContext;
        if (context != null) {
          final ScrollableState? scrollable = Scrollable.of(context);
          final double? itemCenterOffset = _getItemOffset(context, alignment: 0.5);
          if (scrollable != null && itemCenterOffset != null) {
            final double currentOffset = _scrollController.position.pixels;
            final double viewportExtent = _scrollController.position.viewportDimension;
            final double itemTopOffset = itemCenterOffset - viewportExtent / 2;

            if ((itemTopOffset - currentOffset).abs() > 1.0) {
              _scrollController.animateTo(
                itemTopOffset.clamp(
                  _scrollController.position.minScrollExtent,
                  _scrollController.position.maxScrollExtent,
                ),
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
              );
            }
          }
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
        title: const Text('User Management'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: _switchSearch,
            tooltip: _isSearchUsers ? 'Search Companies' : 'Search Users',
            icon: Icon(_isSearchUsers ? Icons.business : Icons.people),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            // Search Section
            Container(
              margin: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: _isSearchUsers
                          ? 'Search users by name or email...'
                          : 'Search companies...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.3),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchText = '';
                                });
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    ),
                  ),
                ),
              ),
            ),

            // Content
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
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Something went wrong!',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              snapshot.error.toString(),
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'There are no users in the system yet',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.7),
                                  ),
                            ),
                          ],
                        ),
                      );
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
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, idx) {
                        final user = filteredUsers[idx];
                        final isExpanded = _expansionStates[user.id] ?? false;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Card(
                            key: _itemKeys[user.id],
                            elevation: 4,
                            shadowColor: Colors.black.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: user.isActive
                                    ? Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.3)
                                    : Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                width: 1,
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
                              leading: CircleAvatar(
                                backgroundColor: user.isActive
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                                child: Text(
                                  user.username.isNotEmpty
                                      ? user.username[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: user.isActive
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                user.username,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                              subtitle: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: user.role.toString() == 'admin'
                                          ? Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1)
                                          : Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      user.role.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: user.role.toString() == 'admin'
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .secondary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: user.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user.isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: user.isActive
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(20.0),
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
                                          // Basic Info
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _buildDetailRow(
                                                    'Email', user.email),
                                              ),
                                              Expanded(
                                                child: _buildDetailRow(
                                                    'Phone', user.phoneNumber),
                                              ),
                                            ],
                                          ),

                                          // Companies Section
                                          if (user.companies.isNotEmpty) ...[
                                            const SizedBox(height: 16),
                                            Text(
                                              'Associated Companies',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onSurface,
                                                  ),
                                            ),
                                            const SizedBox(height: 12),
                                            if (paymentSnapshot
                                                    .connectionState ==
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
                                                      const EdgeInsets.all(16),
                                                  decoration: BoxDecoration(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .surfaceContainerHighest
                                                        .withOpacity(0.3),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .outline
                                                          .withOpacity(0.2),
                                                    ),
                                                  ),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Icon(
                                                            Icons.business,
                                                            size: 20,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .primary,
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(
                                                            companyName,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .titleSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  color: Theme.of(
                                                                          context)
                                                                      .colorScheme
                                                                      .onSurface,
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
                                                          Icon(
                                                            Icons.payment,
                                                            size: 16,
                                                            color: Theme.of(
                                                                    context)
                                                                .colorScheme
                                                                .onSurface
                                                                .withOpacity(
                                                                    0.6),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child: Text(
                                                              paymentMethods
                                                                      .isEmpty
                                                                  ? 'No payment methods configured'
                                                                  : paymentMethods
                                                                      .map((pm) => pm
                                                                          .toString())
                                                                      .join(
                                                                          ', '),
                                                              style: Theme.of(
                                                                      context)
                                                                  .textTheme
                                                                  .bodySmall
                                                                  ?.copyWith(
                                                                    color: Theme.of(
                                                                            context)
                                                                        .colorScheme
                                                                        .onSurface
                                                                        .withOpacity(
                                                                            0.8),
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

                                          // Created Date
                                          const SizedBox(height: 16),
                                          _buildDetailRow(
                                            'Member Since',
                                            user.createdAt == null
                                                ? 'Unknown'
                                                : DateFormat('MMM dd, yyyy')
                                                    .format(user.createdAt!),
                                          ),

                                          // Action Buttons
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: OutlinedButton.icon(
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
                                                  icon: const Icon(Icons
                                                      .confirmation_number),
                                                  label: const Text(
                                                      'View Tickets'),
                                                  style:
                                                      OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        vertical: 12),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: FilledButton.icon(
                                                  onPressed: () {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            AbsolutelyVisibleUserDetailsScreen(
                                                          userId: user.id,
                                                          username:
                                                              user.username,
                                                          isActive:
                                                              user.isActive,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  icon: const Icon(Icons.info),
                                                  label: const Text('Details'),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              IconButton.filledTonal(
                                                onPressed: () =>
                                                    _editUserInfo(user),
                                                icon: const Icon(Icons.edit),
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
