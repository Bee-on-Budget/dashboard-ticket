import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'test_screen.dart';
import 'home_screen.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';
import 'profile_screen.dart';

class MergedScreen extends StatefulWidget {
  const MergedScreen({super.key});

  @override
  State<MergedScreen> createState() => MergedScreenState();
}

// MergedScreen.dart
class MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 3; // Private variable

  // Public method to update _currentIndex
  void updateCurrentIndex(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  final List<Widget> _pages = [
    HomeScreen(),
    CreateUserScreen(),
    TicketsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Admin Panel',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
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
                  children: const [
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
                      'Welcome to the Admin Panel',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(Icons.dashboard, 'Dashboard', 0),
              _buildDrawerItem(Icons.person_add, 'Create User', 1),
              _buildDrawerItem(Icons.list, 'Tickets', 2),
              _buildDrawerItem(Icons.person, 'Profile', 3),
              const Divider(color: Colors.white54),
              _buildDrawerItem(Icons.logout, 'Logout', 4, isLogout: true),
            ],
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
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

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
