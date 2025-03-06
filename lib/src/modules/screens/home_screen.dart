import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  Future<Map<String, int>> _fetchStatistics() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('tickets').get();
    final tickets = snapshot.docs;

    int totalTickets = tickets.length;
    int openTickets =
        tickets.where((ticket) => ticket['status'] == 'Open').length;
    int inProgressTickets =
        tickets.where((ticket) => ticket['status'] == 'In Progress').length;
    int closedTickets =
        tickets.where((ticket) => ticket['status'] == 'Closed').length;

    return {
      'total_tickets': totalTickets,
      'open_tickets': openTickets,
      'in_progress': inProgressTickets,
      'closed_tickets': closedTickets,
    };
  }

  Future<List<Map<String, dynamic>>> _fetchTicketStatus() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('tickets').get();
    final tickets = snapshot.docs;

    Map<String, int> statusCounts = {
      'Open': 0,
      'In Progress': 0,
      'Closed': 0,
    };

    for (var ticket in tickets) {
      String status = ticket['status'];
      if (statusCounts.containsKey(status)) {
        statusCounts[status] = statusCounts[status]! + 1;
      }
    }

    return statusCounts.entries
        .map((entry) => {
              'status': entry.key,
              'value': entry.value,
            })
        .toList();
  }

  Future<List<Map<String, dynamic>>> _fetchTicketsOverTime() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('tickets').get();
    final tickets = snapshot.docs;

    Map<String, int> ticketsOverTime = {};

    for (var ticket in tickets) {
      String date = ticket['createdDate'].toDate().toString().split(' ')[0];
      if (ticketsOverTime.containsKey(date)) {
        ticketsOverTime[date] = ticketsOverTime[date]! + 1;
      } else {
        ticketsOverTime[date] = 1;
      }
    }

    return ticketsOverTime.entries
        .map((entry) => {
              'date': entry.key,
              'count': entry.value,
            })
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            FutureBuilder<Map<String, int>>(
              future: _fetchStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final stats = snapshot.data!;
                return _buildStatisticsGrid(stats);
              },
            ),
            const SizedBox(height: 20),
            const Text('Ticket Status Distribution',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTicketStatus(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final statusData = snapshot.data!;
                return _buildPieChart(statusData);
              },
            ),
            const SizedBox(height: 20),
            const Text('Tickets Over Time',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTicketsOverTime(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final ticketsOverTime = snapshot.data!;
                return _buildLineChart(ticketsOverTime);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsGrid(Map<String, int> stats) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16.0,
      crossAxisSpacing: 16.0,
      children: [
        _buildStatisticCard(
            'Total Tickets', stats['total_tickets'].toString(), Colors.blue),
        _buildStatisticCard(
            'Open Tickets', stats['open_tickets'].toString(), Colors.orange),
        _buildStatisticCard(
            'In Progress', stats['in_progress'].toString(), Colors.purple),
        _buildStatisticCard(
            'Closed Tickets', stats['closed_tickets'].toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatisticCard(String title, String value, Color color) {
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
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart(List<Map<String, dynamic>> statusData) {
    return SizedBox(
      height: 300,
      child: PieChart(
        PieChartData(
          sections: statusData.map((data) {
            return PieChartSectionData(
              value: data['value'].toDouble(),
              color: TicketStatus.fromString(data['status']).getColor(),
              title: data['status'],
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList(),
          centerSpaceRadius: 60,
          sectionsSpace: 0,
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> ticketsOverTime) {
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
          maxX: ticketsOverTime.length.toDouble() - 1,
          minY: 0,
          maxY: ticketsOverTime
              .map((e) => e['count'])
              .reduce((a, b) => a > b ? a : b)
              .toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: ticketsOverTime.asMap().entries.map((entry) {
                return FlSpot(
                    entry.key.toDouble(), entry.value['count'].toDouble());
              }).toList(),
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
