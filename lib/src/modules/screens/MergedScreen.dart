import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';
import 'home_screen.dart';

class MergedScreen extends StatefulWidget {
  @override
  _MergedScreenState createState() => _MergedScreenState();
}

class _MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomeScreen(),
    CreateUserScreen(),
    TicketsScreen(),
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
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: Colors.white),
            onPressed: () {
              // Handle notification action
            },
          ),
          // Logout Icon
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _signOut(context); // Logout immediately
            },
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
                  image: DecorationImage(
                    image: AssetImage('assets/images/drawer_header.jpg'),
                    fit: BoxFit.cover,
                  ),
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
              const Divider(color: Colors.white54),
              _buildDrawerItem(Icons.logout, 'Logout', 3, isLogout: true),
            ],
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _pages[_currentIndex],
      ),
      floatingActionButton: _currentIndex == 2
          ? FloatingActionButton(
              onPressed: () {
                // Handle FAB action for TicketsScreen
              },
              child: Icon(Icons.add, color: Colors.white),
              backgroundColor: Color(0xFF44564A),
            )
          : null,
    );
  }

  Widget _buildDrawerItem(IconData icon, String title, int index,
      {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.white),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.white,
        ),
      ),
      onTap: () {
        if (isLogout) {
          _signOut(context);
        } else {
          setState(() {
            _currentIndex = index;
          });
          Navigator.pop(context);
        }
      },
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
