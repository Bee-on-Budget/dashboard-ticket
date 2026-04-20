import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// import 'test_screen.dart';
import 'home_screen.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';
import 'companies_screen.dart';
import '../../config/db_collections.dart';
import '../../config/enums/user_role.dart';

class MergedScreen extends StatefulWidget {
  const MergedScreen({super.key});

  @override
  State<MergedScreen> createState() => MergedScreenState();
}

class MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 0;
  String? _userName;
  bool _isUsersExpanded = false;
  bool _isLoadingUserContext = true;
  UserRole _currentUserRole = UserRole.unknown;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  Future<void> _loadUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection(DbCollections.users)
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final userData = userDoc.data();
          setState(() {
            _userName = userData?['username'] ??
                user.displayName ??
                user.email?.split('@')[0] ??
                'User';
            _currentUserRole =
                UserRole.fromString(userData?['role']?.toString());
            _isLoadingUserContext = false;
          });
        } else {
          setState(() {
            _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
            _currentUserRole = UserRole.unknown;
            _isLoadingUserContext = false;
          });
        }
      } catch (e) {
        setState(() {
          _userName = user.displayName ?? user.email?.split('@')[0] ?? 'User';
          _currentUserRole = UserRole.unknown;
          _isLoadingUserContext = false;
        });
      }
    } else {
      setState(() {
        _isLoadingUserContext = false;
      });
    }
  }

  void updateCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Widget> get _pages {
    if (_currentUserRole == UserRole.admin) {
      return const [
        HomeScreen(),
        CreateUserScreen(),
        TicketsScreen(),
        ProfileScreen(),
        CompaniesScreen(),
      ];
    }

    return const [
      TicketsScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _pages;
    final currentIndex = _currentIndex >= pages.length ? 0 : _currentIndex;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Expanded(
              child: Text(
                _currentUserRole == UserRole.admin
                    ? 'Admin Panel'
                    : 'Tickets',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_userName != null)
              Text(
                'Hi $_userName!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        backgroundColor: Color(0xFF44564A),
        elevation: 0,
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notification action
            },
          ),
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: _signOut,
          ),
        ],
      ),
      drawer: Drawer(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF44564A), Color(0xFF2C3E50)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFF44564A),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _currentUserRole == UserRole.admin
                          ? 'Welcome to the Admin Panel'
                          : 'Ticket access',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    if (_userName != null) ...[
                      SizedBox(height: 8),
                      Text(
                        'Hi $_userName!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isLoadingUserContext)
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else ...[
                if (_currentUserRole == UserRole.admin) ...[
                  _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
                  _buildUsersCategory(),
                  _buildDrawerItem(Icons.list, 'Tickets', 2),
                  _buildDrawerItem(Icons.business, 'Companies', 4),
                ] else
                  _buildDrawerItem(Icons.list, 'Tickets', 0),
              ],
              const Divider(color: Colors.white54),
              _buildDrawerItem(Icons.logout, 'Logout', 5, isLogout: true),
            ],
          ),
        ),
      ),
      body: _isLoadingUserContext
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: currentIndex,
              children: pages,
            ),
    );
  }

  Widget _buildUsersCategory() {
    return Column(
      children: [
        ListTile(
          leading: Icon(
            Icons.people,
            color: Colors.white,
          ),
          title: Text(
            'Users',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
            ),
          ),
          trailing: Icon(
            _isUsersExpanded ? Icons.expand_less : Icons.expand_more,
            color: Colors.white,
          ),
          onTap: () {
            setState(() {
              _isUsersExpanded = !_isUsersExpanded;
            });
          },
        ),
        if (_isUsersExpanded) ...[
          _buildSubDrawerItem(Icons.person_add, 'Create User', 1),
          _buildSubDrawerItem(Icons.person, 'Profile', 3),
        ],
      ],
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(
        icon,
        color: isLogout ? Colors.red : Colors.white,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.white,
        ),
      ),
      onTap: () {
        if (isLogout) {
          _signOut();
        } else {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildSubDrawerItem(IconData icon, String title, int index) {
    return Padding(
      padding: const EdgeInsets.only(left: 32.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white70,
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
