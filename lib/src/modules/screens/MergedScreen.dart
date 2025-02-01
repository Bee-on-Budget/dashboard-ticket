import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';

class MergedScreen extends StatefulWidget {
  @override
  _MergedScreenState createState() => _MergedScreenState();
}

class _MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const HomeScreen(),
      CreateUserScreen(),
      TicketsScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_add),
            label: 'Create User',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Tickets',
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/createUser');
              },
              child: const Text('Create User'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tickets');
              },
              child: const Text('View Tickets'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                _signOut(context);
              },
              child: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
