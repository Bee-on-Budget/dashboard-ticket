import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../config/db_collections.dart';

class SearchableUserSelection extends StatefulWidget {
  final List<String> initialSelectedUserIds;
  final ValueChanged<List<String>> onSelectionChanged;

  const SearchableUserSelection({
    Key? key,
    this.initialSelectedUserIds = const [],
    required this.onSelectionChanged,
  }) : super(key: key);

  @override
  State<SearchableUserSelection> createState() =>
      _SearchableUserSelectionState();
}

class _SearchableUserSelectionState extends State<SearchableUserSelection> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  bool _isLoading = false;
  List<Map<String, dynamic>> _results = [];
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _selectedIds.addAll(widget.initialSelectedUserIds);
    _loadInitialUsers();
    _controller.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.removeListener(_onSearchChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _searchUsers(_controller.text.trim());
    });
  }

  // Load a small initial set without ordering, then sort and filter client-side
  Future<void> _loadInitialUsers() async {
    setState(() => _isLoading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .limit(100)
          .get();

      final allUsers = snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'name': (data['name'] ?? data['displayName'] ?? '').toString(),
              'email': (data['email'] ?? '').toString(),
              'nameLower': (data['nameLower'] ??
                      (data['name'] ?? '').toString().toLowerCase())
                  .toString(),
              'isActive': data['isActive'] == true,
            };
          })
          .where((u) => u['isActive'] == true)
          .toList();

      // Sort by name client-side
      allUsers.sort((a, b) =>
          (a['nameLower'] as String).compareTo(b['nameLower'] as String));

      // Take first 50 after sorting
      _results = allUsers.take(50).toList();
    } catch (e, st) {
      debugPrint('loadInitialUsers error: $e\n$st');
      _results = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Users load error: ${e.toString().split('\n').first}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Search by nameLower range without isActive in query, filter client-side
  Future<void> _searchUsers(String query) async {
    if (query.isEmpty) {
      await _loadInitialUsers();
      return;
    }

    setState(() => _isLoading = true);
    final lower = query.toLowerCase();
    try {
      final snap = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .where('nameLower', isGreaterThanOrEqualTo: lower)
          .where('nameLower', isLessThanOrEqualTo: '$lower\uf8ff')
          .limit(100)
          .get();

      final allResults = snap.docs
          .map((d) {
            final data = d.data() as Map<String, dynamic>;
            return {
              'id': d.id,
              'name': (data['name'] ?? data['displayName'] ?? '').toString(),
              'email': (data['email'] ?? '').toString(),
              'nameLower': (data['nameLower'] ??
                      (data['name'] ?? '').toString().toLowerCase())
                  .toString(),
              'isActive': data['isActive'] == true,
            };
          })
          .where((u) => u['isActive'] == true)
          .toList();

      // Sort by name client-side
      allResults.sort((a, b) =>
          (a['nameLower'] as String).compareTo(b['nameLower'] as String));

      _results = allResults.take(50).toList();
    } catch (e, st) {
      debugPrint('searchUsers firestore error: $e\n$st');

      // Fallback to client-side filtering of current results
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search error, using local filter')),
        );
      }

      final fallback = _results.where((u) {
        final nl =
            (u['nameLower'] ?? (u['name'] ?? '')).toString().toLowerCase();
        final em = (u['email'] ?? '').toString().toLowerCase();
        return nl.contains(lower) || em.contains(lower);
      }).toList();

      _results = fallback;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleSelect(String userId) {
    setState(() {
      if (_selectedIds.contains(userId)) {
        _selectedIds.remove(userId);
      } else {
        _selectedIds.add(userId);
      }
      widget.onSelectionChanged(_selectedIds.toList());
    });
  }

  @override
  Widget build(BuildContext context) {
    return FocusScope(
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Search users by name or email...',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            SizedBox(
              height: 240,
              child: _results.isEmpty
                  ? const Center(child: Text('No users found'))
                  : ListView.separated(
                      itemCount: _results.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = _results[index];
                        final id = user['id'] as String;
                        final name = user['name'] as String;
                        final email = user['email'] as String;
                        final selected = _selectedIds.contains(id);
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(name),
                          subtitle: Text(email),
                          trailing: Checkbox(
                            value: selected,
                            onChanged: (_) => _toggleSelect(id),
                          ),
                          onTap: () => _toggleSelect(id),
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }
}
