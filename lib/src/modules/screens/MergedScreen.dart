import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';
import 'home_screen.dart'; // Ensure you import the HomeScreen

class MergedScreen extends StatefulWidget {
  @override
  _MergedScreenState createState() => _MergedScreenState();
}

class _MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 0; // Default index is 0 (HomeScreen)

  final List<Widget> _pages = [
    HomeScreen(), // HomeScreen is the dashboard
    CreateUserScreen(),
    TicketsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: const BoxDecoration(
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
            ListTile(
              leading: const Icon(Icons.dashboard, color: Color(0xFF44564A)),
              title: const Text(
                'Dashboard',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = 0; // Set index to 0 for HomeScreen
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Color(0xFF44564A)),
              title: const Text(
                'Create User',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = 1; // Set index to 1 for CreateUserScreen
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.list, color: Color(0xFF44564A)),
              title: const Text(
                'Tickets',
                style: TextStyle(fontSize: 16),
              ),
              onTap: () {
                setState(() {
                  _currentIndex = 2; // Set index to 2 for TicketsScreen
                });
                Navigator.pop(context); // Close the drawer
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(fontSize: 16, color: Colors.red),
              ),
              onTap: () {
                _signOut(context);
              },
            ),
          ],
        ),
      ),
      body: Row(
        children: [
          Expanded(
            flex: 1,
            child: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
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
                  ListTile(
                    leading:
                        const Icon(Icons.dashboard, color: Color(0xFF44564A)),
                    title: const Text(
                      'Dashboard',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      setState(() {
                        _currentIndex = 0; // Set index to 0 for HomeScreen
                      });
                    },
                  ),
                  ListTile(
                    leading:
                        const Icon(Icons.person_add, color: Color(0xFF44564A)),
                    title: const Text(
                      'Create User',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      setState(() {
                        _currentIndex =
                            1; // Set index to 1 for CreateUserScreen
                      });
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list, color: Color(0xFF44564A)),
                    title: const Text(
                      'Tickets',
                      style: TextStyle(fontSize: 16),
                    ),
                    onTap: () {
                      setState(() {
                        _currentIndex = 2; // Set index to 2 for TicketsScreen
                      });
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout, color: Colors.red),
                    title: const Text(
                      'Logout',
                      style: TextStyle(fontSize: 16, color: Colors.red),
                    ),
                    onTap: () {
                      _signOut(context);
                    },
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: _pages[_currentIndex], // Display the selected page
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
