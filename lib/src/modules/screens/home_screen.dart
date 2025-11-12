import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dashboard/src/config/db_collections.dart';
import 'package:flutter_dashboard/src/config/enums/ticket_status.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dashboard/src/modules/screens/CreateCompanyScreen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<Map<String, int>> _fetchStatistics() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .get();
    final tickets = snapshot.docs;

    return {
      'total': tickets.length,
      'open': tickets.where((t) => t['status'] == 'Open').length,
      'in_progress': tickets.where((t) => t['status'] == 'In Progress').length,
      'closed': tickets.where((t) => t['status'] == 'Closed').length,
      'rework': tickets.where((t) => t['status'] == 'Need Re-work').length,
      'canceled': tickets.where((t) => t['status'] == 'Canceled').length,
    };
  }

  Future<List<PieChartSectionData>> _fetchTicketStatusData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .get();
    final tickets = snapshot.docs;

    final statusCounts = {
      'Open': 0,
      'In Progress': 0,
      'Closed': 0,
      'needReWork': 0,
      'canceled': 0,
    };

    for (var ticket in tickets) {
      final status = ticket['status'] as String;
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    final totalTickets = tickets.length;
    if (totalTickets == 0) return [];

    const double radius = 60;
    const double fontSize = 14;

    return [
      _buildPieSection('Open', statusCounts['Open']!, totalTickets,
          TicketStatus.open.getColor(), radius, fontSize),
      _buildPieSection('In Progress', statusCounts['In Progress']!,
          totalTickets, TicketStatus.inProgress.getColor(), radius, fontSize),
      _buildPieSection('Closed', statusCounts['Closed']!, totalTickets,
          TicketStatus.closed.getColor(), radius, fontSize),
      _buildPieSection('Rework', statusCounts['needReWork']!, totalTickets,
          TicketStatus.needReWork.getColor(), radius, fontSize),
      _buildPieSection('Canceled', statusCounts['canceled']!, totalTickets,
          TicketStatus.canceled.getColor(), radius, fontSize),
    ];
  }

  PieChartSectionData _buildPieSection(
    String title,
    int value,
    int total,
    Color color,
    double radius,
    double fontSize,
  ) {
    final percentage = (value / total * 100).toStringAsFixed(1);
    return PieChartSectionData(
      value: value.toDouble(),
      color: color,
      title: '$value\n($percentage%)',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
      badgeWidget: _StatusBadge(title: title, color: color),
      badgePositionPercentageOffset:
          1.6, // Changed from .98 to 1.02 to move badges outward
    );
  }

  Future<List<Map<String, dynamic>>> _fetchTicketsOverTime() async {
    final snapshot = await FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .get();
    final tickets = snapshot.docs;

    final ticketsByDate = <String, int>{};
    final dateFormat = DateFormat('MMM dd');

    for (var ticket in tickets) {
      final date = (ticket['createdDate'] as Timestamp).toDate();
      final dateKey = dateFormat.format(date);
      ticketsByDate[dateKey] = (ticketsByDate[dateKey] ?? 0) + 1;
    }

    // Convert to list and sort with proper type safety
    final resultList = ticketsByDate.entries
        .map((e) => {'date': e.key as String, 'count': e.value as int})
        .toList();

    resultList.sort((a, b) {
      final dateA = a['date'] as String;
      final dateB = b['date'] as String;
      return dateA.compareTo(dateB);
    });

    return resultList;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final cardColor = isDarkMode ? Colors.grey[900]! : Colors.white;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeaderSection(theme),
            const SizedBox(height: 24),

            // Statistics Cards
            FutureBuilder<Map<String, int>>(
              future: _fetchStatistics(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }
                return _buildStatisticsGrid(snapshot.data!, cardColor, theme);
              },
            ),
            const SizedBox(height: 32),

            // Ticket Status Distribution
            _buildSectionTitle('Ticket Status Overview', theme),
            const SizedBox(height: 16),
            FutureBuilder<List<PieChartSectionData>>(
              future: _fetchTicketStatusData(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }
                return _buildEnhancedPieChart(snapshot.data!, theme);
              },
            ),
            const SizedBox(height: 32),

            // Tickets Over Time
            _buildSectionTitle('Tickets Timeline', theme),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTicketsOverTime(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingIndicator();
                }
                if (snapshot.hasError) {
                  return _buildErrorWidget(snapshot.error.toString());
                }
                return _buildEnhancedLineChart(snapshot.data!, theme);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard Overview',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track and analyze your support tickets',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildStatisticsGrid(
      Map<String, int> stats, Color cardColor, ThemeData theme) {
    return StaggeredGrid.count(
      crossAxisCount: 4,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildEnhancedStatCard(
          'Total Tickets',
          stats['total']!,
          Icons.assignment,
          Colors.blue,
          cardColor,
          theme,
        ),
        _buildEnhancedStatCard(
          'Open',
          stats['open']!,
          Icons.lock_open,
          Colors.orange,
          cardColor,
          theme,
        ),
        _buildEnhancedStatCard(
          'In Progress',
          stats['in_progress']!,
          Icons.autorenew,
          Colors.purple,
          cardColor,
          theme,
        ),
        _buildEnhancedStatCard(
          'Closed',
          stats['closed']!,
          Icons.check_circle,
          Colors.green,
          cardColor,
          theme,
        ),
        _buildEnhancedStatCard(
          'Rework',
          stats['rework']!,
          Icons.build,
          Colors.red,
          cardColor,
          theme,
        ),
        _buildEnhancedStatCard(
          'Canceled',
          stats['canceled']!,
          Icons.cancel,
          Colors.grey,
          cardColor,
          theme,
        ),
      ],
    );
  }

  Widget _buildEnhancedStatCard(
    String title,
    int value,
    IconData icon,
    Color color,
    Color cardColor,
    ThemeData theme,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                Text(
                  value.toString(),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedPieChart(
      List<PieChartSectionData>? data, ThemeData theme) {
    if (data == null || data.isEmpty) {
      return const Center(child: Text('No ticket data available'));
    }

    return Container(
      height: 360,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: PieChart(
              PieChartData(
                sections: data,
                centerSpaceRadius: 80,
                sectionsSpace: 2,
                startDegreeOffset: -90,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: data.map((section) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: section.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          section.badgeWidget is _StatusBadge
                              ? (section.badgeWidget as _StatusBadge).title
                              : '',
                          style: theme.textTheme.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedLineChart(
      List<Map<String, dynamic>> data, ThemeData theme) {
    if (data.isEmpty) {
      return const Center(child: Text('No timeline data available'));
    }

    final maxY =
        data.map((e) => e['count']).reduce((a, b) => a > b ? a : b).toDouble();

    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.3),
              strokeWidth: 1,
            ),
            getDrawingVerticalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(),
            topTitles: const AxisTitles(),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < data.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        data[value.toInt()]['date'],
                        style: theme.textTheme.bodySmall,
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 36,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: theme.textTheme.bodySmall,
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: true,
            border: Border.all(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
          minX: 0,
          maxX: data.length.toDouble() - 1,
          minY: 0,
          maxY: maxY + (maxY * 0.1), // Add 10% padding
          lineBarsData: [
            LineChartBarData(
              spots: data.asMap().entries.map((entry) {
                return FlSpot(
                  entry.key.toDouble(),
                  entry.value['count'].toDouble(),
                );
              }).toList(),
              isCurved: true,
              color: theme.colorScheme.primary,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary.withOpacity(0.3),
                    theme.colorScheme.primary.withOpacity(0.1),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      heightFactor: 5,
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      heightFactor: 5,
      child: Text(
        'Error: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String title;
  final Color color;

  const _StatusBadge({
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
