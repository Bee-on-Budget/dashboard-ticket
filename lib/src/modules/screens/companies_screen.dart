import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/company.dart';
import '../models/user.dart';
import '../../service/data_service.dart';
import '../../config/db_collections.dart';
import 'searchable_user_selection.dart';
import 'CreateCompanyScreen.dart';

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({super.key});

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

class _CompaniesScreenState extends State<CompaniesScreen> {
  late final TextEditingController _searchController;
  String _searchText = '';
  String? _expandedCompanyId;
  final ScrollController _scrollController = ScrollController();
  final Map<String, bool> _expansionStates = {};
  final Map<String, GlobalKey> _itemKeys = {};
  double? _lastScrollPosition;
  Timer? _debounce;

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
    _debounce?.cancel();
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

  void _scrollToExpandedItem(String companyId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_itemKeys.containsKey(companyId)) {
        final key = _itemKeys[companyId]!;
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

  Future<void> _saveCompanyWithUsers({
    required Company originalCompany,
    required String name,
    required List<String> paymentMethods,
    required bool isActive,
    required List<String> assignedUserIds,
    required List<User> allUsers,
  }) async {
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company name is required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show confirmation if deactivating company
    if (!isActive && originalCompany.isActive) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Deactivate Company'),
          content: const Text(
            'Deactivating this company will also deactivate all users assigned to it. Do you want to continue?',
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
    }

    final updatedCompany = Company(
      id: originalCompany.id,
      name: name,
      paymentMethods: paymentMethods,
      createdAt: originalCompany.createdAt ?? DateTime.now(),
      isActive: isActive,
    );

    try {
      // 1. Update company (this will auto-deactivate users if company is deactivated)
      await DataService.updateCompany(updatedCompany);

      // 2. Sync payment methods to assigned users
      await DataService.syncPaymentMethodsToCompanyUsers(name, paymentMethods);

      // 3. Update user assignments
      final batch = FirebaseFirestore.instance.batch();

      for (final user in allUsers) {
        final userRef = FirebaseFirestore.instance
            .collection(DbCollections.users)
            .doc(user.id);

        final shouldBeAssigned = assignedUserIds.contains(user.id);
        final isCurrentlyAssigned =
            user.companies.contains(originalCompany.name);

        if (shouldBeAssigned && !isCurrentlyAssigned) {
          // Add company to user
          batch.update(userRef, {
            'companies': FieldValue.arrayUnion([name]),
          });
        } else if (!shouldBeAssigned && isCurrentlyAssigned) {
          // Remove company from user
          batch.update(userRef, {
            'companies': FieldValue.arrayRemove([originalCompany.name]),
          });
        } else if (shouldBeAssigned && name != originalCompany.name) {
          // Company name changed, update it
          batch.update(userRef, {
            'companies': FieldValue.arrayRemove([originalCompany.name]),
          });
          batch.update(userRef, {
            'companies': FieldValue.arrayUnion([name]),
          });
        }
      }

      await batch.commit();

      if (mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isActive
                  ? 'Company and user assignments updated successfully!'
                  : 'Company deactivated and all its users have been deactivated',
            ),
            backgroundColor: isActive ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
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

  Future<void> _editCompanyInfo(Company company) async {
    final nameController = TextEditingController(text: company.name);
    final paymentMethodController = TextEditingController();
    List<String> selectedPaymentMethods = List.from(company.paymentMethods);
    bool isActive = company.isActive;

    // Load users assigned to this company
    List<String> assignedUserIds = [];
    List<User> allUsers = [];
    bool isLoadingUsers = true;

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Load users on first build
            if (isLoadingUsers && allUsers.isEmpty) {
              DataService.getUsers().first.then((users) {
                setDialogState(() {
                  allUsers = users.where((u) => u.isActive).toList();
                  // Find users already in this company
                  assignedUserIds = users
                      .where((u) => u.companies.contains(company.name))
                      .map((u) => u.id)
                      .toList();
                  isLoadingUsers = false;
                });
              });
            }

            return Dialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Edit Company',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
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

                      // Company Name
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business_outlined,
                              color: Colors.grey[600]),
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
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Payment Methods Section
                      Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: paymentMethodController,
                              decoration: InputDecoration(
                                labelText: 'Add Payment Method',
                                prefixIcon: Icon(Icons.payment,
                                    color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: theme.primaryColor,
                            iconSize: 36,
                            onPressed: () {
                              final method =
                                  paymentMethodController.text.trim();
                              if (method.isNotEmpty &&
                                  !selectedPaymentMethods.contains(method)) {
                                setDialogState(() {
                                  selectedPaymentMethods.add(method);
                                  paymentMethodController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedPaymentMethods.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedPaymentMethods.map((method) {
                            return Chip(
                              label: Text(method),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setDialogState(() {
                                  selectedPaymentMethods.remove(method);
                                });
                              },
                              backgroundColor:
                                  theme.primaryColor.withOpacity(0.2),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // Assigned Users Section with Search
                      Text(
                        'Assigned Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isLoadingUsers)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else
                        SearchableUserSelection(
                          initialSelectedUserIds: assignedUserIds,
                          onSelectionChanged: (selectedIds) {
                            assignedUserIds = selectedIds;
                          },
                        ),
                      const SizedBox(height: 20),

                      // Active Status with Warning
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.green.withOpacity(0.1)
                              : Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isActive ? Colors.green : Colors.orange,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isActive ? Icons.check_circle : Icons.warning,
                              color: isActive ? Colors.green : Colors.orange,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Active Status:',
                                        style: TextStyle(
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
                                  if (!isActive)
                                    const Text(
                                      'All users in this company will be deactivated',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
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
                            onPressed: () => _saveCompanyWithUsers(
                              originalCompany: company,
                              name: nameController.text,
                              paymentMethods: selectedPaymentMethods,
                              isActive: isActive,
                              assignedUserIds: assignedUserIds,
                              allUsers: allUsers,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: theme.colorScheme.onPrimary,
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
  }

  Future<void> _createNewCompany() async {
    final nameController = TextEditingController();
    final paymentMethodController = TextEditingController();
    List<String> selectedPaymentMethods = [];
    List<String> assignedUserIds = [];

    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: isDarkMode ? Colors.grey[900] : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: const BoxConstraints(maxWidth: 600),
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Create Company',
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
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Company Name',
                          prefixIcon: Icon(Icons.business_outlined,
                              color: Colors.grey[600]),
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
                              color: theme.primaryColor,
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor:
                              isDarkMode ? Colors.grey[800] : Colors.grey[100],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Payment Methods',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: paymentMethodController,
                              decoration: InputDecoration(
                                labelText: 'Add Payment Method',
                                prefixIcon: Icon(Icons.payment,
                                    color: Colors.grey[600]),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: isDarkMode
                                    ? Colors.grey[800]
                                    : Colors.grey[100],
                              ),
                              onSubmitted: (value) {
                                final method = value.trim();
                                if (method.isNotEmpty &&
                                    !selectedPaymentMethods.contains(method)) {
                                  setDialogState(() {
                                    selectedPaymentMethods.add(method);
                                    paymentMethodController.clear();
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add_circle),
                            color: theme.primaryColor,
                            iconSize: 36,
                            onPressed: () {
                              final method =
                                  paymentMethodController.text.trim();
                              if (method.isNotEmpty &&
                                  !selectedPaymentMethods.contains(method)) {
                                setDialogState(() {
                                  selectedPaymentMethods.add(method);
                                  paymentMethodController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (selectedPaymentMethods.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: selectedPaymentMethods.map((method) {
                            return Chip(
                              label: Text(method),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setDialogState(() {
                                  selectedPaymentMethods.remove(method);
                                });
                              },
                              backgroundColor:
                                  theme.primaryColor.withOpacity(0.2),
                            );
                          }).toList(),
                        ),
                      const SizedBox(height: 20),

                      // User Selection with Search
                      Text(
                        'Assign Users',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SearchableUserSelection(
                        initialSelectedUserIds: assignedUserIds,
                        onSelectionChanged: (selectedIds) {
                          assignedUserIds = selectedIds;
                        },
                      ),
                      const SizedBox(height: 24),

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
                            onPressed: () async {
                              if (nameController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Company name is required'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              final newCompany = Company(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                name: nameController.text,
                                paymentMethods: selectedPaymentMethods,
                                createdAt: DateTime.now(),
                                isActive: true,
                              );

                              try {
                                await DataService.createCompany(newCompany);

                                // Assign users to company
                                if (assignedUserIds.isNotEmpty) {
                                  final batch =
                                      FirebaseFirestore.instance.batch();
                                  for (final userId in assignedUserIds) {
                                    final userRef = FirebaseFirestore.instance
                                        .collection(DbCollections.users)
                                        .doc(userId);
                                    batch.update(userRef, {
                                      'companies': FieldValue.arrayUnion(
                                          [newCompany.name]),
                                    });
                                  }
                                  await batch.commit();
                                }

                                if (mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content:
                                          Text('Company created successfully!'),
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                            ),
                            child: const Text('CREATE'),
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Create Company',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateCompanyScreen(),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateCompanyScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Create Company',
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
                      hintText: 'Search companies by name or description...',
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
              child: StreamBuilder<List<Company>>(
                stream: DataService.getCompanies(),
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
                            Icons.business_center_outlined,
                            size: 64,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No companies found',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'There are no companies in the system yet',
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
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const CreateCompanyScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.add_business),
                            label: const Text('Add First Company'),
                          ),
                        ],
                      ),
                    );
                  }

                  final companies = snapshot.data!;
                  final filteredCompanies = _filterCompanies(companies);

                  for (var company in filteredCompanies) {
                    _itemKeys.putIfAbsent(company.id, () => GlobalKey());
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_expandedCompanyId != null) {
                      _scrollToExpandedItem(_expandedCompanyId!);
                    } else {
                      _restoreScrollPosition();
                    }
                  });

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredCompanies.length,
                    itemBuilder: (context, idx) {
                      final company = filteredCompanies[idx];
                      final isExpanded = _expansionStates[company.id] ?? false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Card(
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: company.isActive
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
                                _expansionStates[company.id] = expanded;
                                _expandedCompanyId =
                                    expanded ? company.id : null;
                                if (expanded) {
                                  _scrollToExpandedItem(company.id);
                                }
                              });
                            },
                            leading: CircleAvatar(
                              backgroundColor: company.isActive
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                              child: Icon(
                                Icons.business,
                                color: company.isActive
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            title: Text(
                              company.name,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            subtitle: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: company.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  company.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: company.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(
                                      company.createdAt ?? DateTime.now()),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Basic Info
                                    if (company.description?.isNotEmpty ??
                                        false) ...[
                                      _buildDetailRow(
                                          'Description', company.description!),
                                      const SizedBox(height: 12),
                                    ],
                                    Row(
                                      children: [
                                        if (company.phone?.isNotEmpty ?? false)
                                          Expanded(
                                            child: _buildDetailRow(
                                                'Phone', company.phone!),
                                          ),
                                        if (company.email?.isNotEmpty ?? false)
                                          Expanded(
                                            child: _buildDetailRow(
                                                'Email', company.email!),
                                          ),
                                      ],
                                    ),
                                    if (company.website?.isNotEmpty ??
                                        false) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                          'Website', company.website!),
                                    ],
                                    if (company.address?.isNotEmpty ??
                                        false) ...[
                                      const SizedBox(height: 12),
                                      _buildDetailRow(
                                          'Address', company.address!),
                                    ],

                                    // Payment Methods
                                    const SizedBox(height: 16),
                                    Text(
                                      'Payment Methods',
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
                                    company.paymentMethods.isEmpty
                                        ? Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .outline
                                                    .withOpacity(0.2),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.payment,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                      .withOpacity(0.6),
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  'No payment methods configured',
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
                                          )
                                        : Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: company.paymentMethods
                                                .map((method) {
                                              return Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary
                                                      .withOpacity(0.1),
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                        .withOpacity(0.3),
                                                  ),
                                                ),
                                                child: Text(
                                                  method.toString(),
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primary,
                                                  ),
                                                ),
                                              );
                                            }).toList(),
                                          ),

                                    // Action Buttons
                                    const SizedBox(height: 20),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FilledButton.icon(
                                            onPressed: () =>
                                                _editCompanyInfo(company),
                                            icon: const Icon(Icons.edit),
                                            label: const Text('Edit Company'),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton.filledTonal(
                                          onPressed: () =>
                                              _deleteCompany(company),
                                          icon: const Icon(Icons.delete),
                                          style: IconButton.styleFrom(
                                            backgroundColor: Theme.of(context)
                                                .colorScheme
                                                .error
                                                .withOpacity(0.1),
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                          tooltip: 'Delete Company',
                                        ),
                                      ],
                                    ),
                                  ],
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

  Future<void> _deleteCompany(Company company) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Company'),
        content: Text(
          'Are you sure you want to delete "${company.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await DataService.deleteCompany(company.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Company "${company.name}" deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting company: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<Company> _filterCompanies(List<Company> companies) {
    if (_searchText.isEmpty) {
      return companies;
    }
    return companies.where((company) {
      return company.name.toLowerCase().contains(_searchText) ||
          company.paymentMethods
              .any((pm) => pm.toLowerCase().contains(_searchText));
    }).toList();
  }
}
