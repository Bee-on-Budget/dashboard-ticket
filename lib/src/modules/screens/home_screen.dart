import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'create_user_screen.dart';
import 'tickets_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Overview',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildStatisticsGrid(),
            const SizedBox(height: 20),
            const Text('Ticket Status Distribution',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildPieChart(),
            const SizedBox(height: 20),
            const Text('Tickets Over Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildLineChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid() {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: List.generate(4, (index) => _buildStatisticCard(index)),
    );
  }

  Widget _buildStatisticCard(int index) {
    final List<Map<String, dynamic>> stats = [
      {'title': 'Total Tickets', 'value': '120', 'color': Colors.blue},
      {'title': 'Open Tickets', 'value': '45', 'color': Colors.orange},
      {'title': 'In Progress', 'value': '30', 'color': Colors.purple},
      {'title': 'Closed Tickets', 'value': '45', 'color': Colors.green},
    ];

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              stats[index]['title'],
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              stats[index]['value'],
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: stats[index]['color'],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 45,
              color: Colors.blue,
              title: 'Open',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: 30,
              color: Colors.orange,
              title: 'In Progress',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            PieChartSectionData(
              value: 45,
              color: Colors.green,
              title: 'Closed',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          centerSpaceRadius: 60,
          sectionsSpace: 0,
        ),
      ),
    );
  }

  Widget _buildLineChart() {
    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true),
          titlesData: FlTitlesData(show: true),
          borderData: FlBorderData(
            show: true,
            border: Border.all(color: const Color(0xff37434d), width: 1),
          ),
          minX: 0,
          maxX: 11,
          minY: 0,
          maxY: 6,
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(0, 3),
                FlSpot(2, 1),
                FlSpot(4, 4),
                FlSpot(6, 2),
                FlSpot(8, 5),
                FlSpot(10, 3),
              ],
              isCurved: true,
              color: Colors.blue,
              dotData: FlDotData(show: false),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}

class MergedScreen extends StatefulWidget {
  @override
  _MergedScreenState createState() => _MergedScreenState();
}

class _MergedScreenState extends State<MergedScreen> {
  int _currentIndex = 0; // Default index is 0 (HomeScreen)

  final List<Widget> _pages = [
    const HomeScreen(), // HomeScreen is the dashboard
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
      body: _pages[_currentIndex], // Display the selected page
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacementNamed(context, '/login');
  }
}
