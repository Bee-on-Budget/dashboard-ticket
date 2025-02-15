import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';

import '../../service/data_service.dart';

const Color primaryColor = Color(0xFF44564A);
final TextStyle boldTextStyle = TextStyle(fontWeight: FontWeight.bold);

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  final TextEditingController searchController = TextEditingController();
  String? selectedTicketId;
  Map<String, dynamic>? selectedTicketData;
  String? selectedFilterValue;

  List<Map<String, dynamic>> admins = [];
  Map<String, dynamic> users = {};
  Map<String, List<String>> userCompanies = {};
  String searchQuery = '';
  String selectedFilter = 'title';
  DateTimeRange? selectedDateRange;
  List<String> statusOptions = ['Open', 'In Progress', 'Closed'];
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
    _fetchUsers();
  }

  Future<void> _fetchAdmins() async {
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      if (mounted) {
        setState(() {
          admins = adminSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'name': data['username'] ?? 'No Name',
            };
          }).toList();
        });
      }
    } catch (e) {
      _showSnackBar('Failed to fetch admins: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final userSnapshot =
          await FirebaseFirestore.instance.collection('users').get();

      // if (mounted) {
      setState(() {
        users = {
          for (var doc in userSnapshot.docs)
            doc.id: _handleNullString(doc.data()['username'])
        };
        userCompanies = {
          for (var doc in userSnapshot.docs)
            doc.id: List<String>.from(doc.data()['companies'] ?? [])
        };
      });
      // }
    } catch (e) {
      _showSnackBar('Failed to fetch users: $e');
    }
  }

  String _handleNullString(String? nullableString) {
    return nullableString ?? 'Unknown';
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTicketId == null ? 'Tickets' : 'Ticket Details'),
        elevation: 0,
        leading: selectedTicketId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  setState(() {
                    selectedTicketId = null;
                    selectedTicketData = null;
                  });
                },
              )
            : null,
        actions: [
          if (selectedTicketId == null)
            IconButton(
              icon: const Icon(Icons.clear_all, color: Colors.white),
              onPressed: _clearAllFilters,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          Expanded(
            child: selectedTicketId == null
                ? _buildTicketList()
                : _buildTicketDetail(),
          ),
        ],
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      searchController.clear();
      selectedFilter = 'title';
      selectedFilterValue = null;
      selectedDateRange = null;
    });
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search tickets...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: const Icon(Icons.search, color: primaryColor),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: _onSearchChanged,
          ),
          const SizedBox(height: 10),
          _buildStatusDropdown(),
          _buildDateSelection(),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedFilter == 'status' ? selectedFilterValue : null,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10),
      ),
      hint: const Text('Select Status'),
      onChanged: (String? newValue) {
        setState(() {
          selectedFilter = 'status';
          selectedFilterValue = newValue;
        });
      },
      items: statusOptions.map<DropdownMenuItem<String>>((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
    );
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      setState(() {
        searchQuery = query;
      });
    });
  }

  // Widget _buildFilterBar() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         child: DropdownButtonFormField<String>(
  //           value: selectedFilter == 'status' ? selectedFilterValue : null,
  //           decoration: InputDecoration(
  //             labelText: 'Status',
  //             border: OutlineInputBorder(
  //               borderRadius: BorderRadius.circular(20.0),
  //             ),
  //             contentPadding: const EdgeInsets.symmetric(horizontal: 10),
  //           ),
  //           hint: const Text('Select Status'),
  //           onChanged: (String? newValue) {
  //             setState(() {
  //               selectedFilter = 'status';
  //               selectedFilterValue = newValue;
  //             });
  //           },
  //           items: statusOptions.map<DropdownMenuItem<String>>((String value) {
  //             return DropdownMenuItem<String>(
  //               value: value,
  //               child: Text(value),
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildDateSelection() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.calendar_today, color: primaryColor),
          onPressed: () => _showDateRangePicker(context),
        ),
        if (selectedDateRange != null)
          IconButton(
            icon: const Icon(Icons.clear, color: primaryColor),
            onPressed: () {
              setState(() {
                selectedDateRange = null;
              });
            },
          ),
        if (selectedDateRange != null)
          Text(
            '${DateFormat('MMM dd').format(selectedDateRange!.start)} - ${DateFormat('MMM dd').format(selectedDateRange!.end)}',
            style: const TextStyle(color: primaryColor),
          ),
      ],
    );
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: "Select Date Range",
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            colorScheme: ColorScheme.light(primary: primaryColor),
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: Dialog(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8, // Smaller width
              child: child,
            ),
          ),
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _getFilteredTicketsStream() async* {
    final snapshot =
        await FirebaseFirestore.instance.collection('tickets').get();
    List<Map<String, dynamic>> tickets = snapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();

    if (searchQuery.length >= 3) {
      final searchLower = searchQuery.toLowerCase();

      tickets = tickets.where((ticket) {
        final title = ticket['title']?.toLowerCase() ?? '';
        final description = ticket['description']?.toLowerCase() ?? '';
        final publisherId = ticket['userId'] ?? '';
        final publisherName = users[publisherId]?.toLowerCase() ?? '';
        final companies =
            userCompanies[publisherId]?.map((e) => e.toLowerCase()) ?? [];

        return title.contains(searchLower) ||
            description.contains(searchLower) ||
            publisherName.contains(searchLower) ||
            companies.any((company) => company.contains(searchLower));
      }).toList();
    }

    if (selectedFilter == 'status' && selectedFilterValue != null) {
      tickets = tickets.where((ticket) {
        return ticket['status'] == selectedFilterValue;
      }).toList();
    }

    if (selectedDateRange != null) {
      tickets = tickets.where((ticket) {
        final createdDate = (ticket['createdDate'] as Timestamp).toDate();
        return createdDate.isAfter(selectedDateRange!.start) &&
            createdDate.isBefore(selectedDateRange!.end);
      }).toList();
    }

    yield tickets;
  }

  Widget _buildTicketList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getFilteredTicketsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tickets available'));
        }
        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final ticket = snapshot.data![index];
            String assignedAdminId = ticket['assignedAdminId'] ?? '';
            String publisherName = users[ticket['userId']] ?? 'Unknown';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  setState(() {
                    selectedTicketId = ticket['id'];
                    selectedTicketData = ticket;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ticket['title'] ?? 'No Title',
                            style: boldTextStyle.copyWith(fontSize: 18),
                          ),
                          Text(
                            'Published by: $publisherName',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            'Status: ${ticket['status'] ?? 'No Status'}',
                            style: TextStyle(
                              color: _getStatusColor(ticket['status']),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      DropdownButton<String>(
                        value:
                            assignedAdminId.isNotEmpty ? assignedAdminId : null,
                        hint: const Text('Assign Admin'),
                        onChanged: (String? newValue) {
                          _assignAdminToTicket(ticket['id'], newValue!);
                        },
                        items: admins.map<DropdownMenuItem<String>>(
                            (Map<String, dynamic> admin) {
                          return DropdownMenuItem<String>(
                            value: admin['id'],
                            child: Text(admin['name']),
                          );
                        }).toList(),
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

  Widget _buildTicketDetail() {
    if (selectedTicketData == null) return Container();

    final files = selectedTicketData?['files'] as List<dynamic>? ?? [];
    String status = selectedTicketData?['status'] ?? 'No Status';
    String publisherName = users[selectedTicketData?['userId']] ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedTicketData?['title'] ?? 'No Title',
            style: boldTextStyle.copyWith(fontSize: 24),
          ),
          const SizedBox(height: 16),
          Text(
            selectedTicketData?['description'] ?? 'No Description',
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Text(
            'Published by: $publisherName',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: status,
            decoration: InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            onChanged: (String? newValue) {
              _updateTicketStatus(selectedTicketId!, newValue!);
            },
            items: statusOptions.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const Text(
            'Attachments:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...files.map((fileUrl) {
            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                title: Text(fileUrl),
                trailing: IconButton(
                  icon: const Icon(Icons.download, color: primaryColor),
                  onPressed: () {
                    _downloadFile(fileUrl);
                  },
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _assignAdminToTicket(String ticketId, String adminId) {
    FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .update({'assignedAdminId': adminId}).then((_) {
      _showSnackBar('Admin assigned successfully');
    }).catchError((error) {
      _showSnackBar('Failed to assign admin: $error');
    });
  }

  void _updateTicketStatus(String ticketId, String newStatus) {
    FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .update({'status': newStatus}).then((_) {
      setState(() {
        if (selectedTicketData != null) {
          selectedTicketData!['status'] = newStatus;
        }
      });
      _showSnackBar('Status updated successfully');
    }).catchError((error) {
      _showSnackBar('Failed to update status: $error');
    });
  }

  void _downloadFile(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      _showSnackBar('Could not launch $url');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'In Progress':
        return Colors.orange;
      case 'Closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
