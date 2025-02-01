import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({Key? key}) : super(key: key);

  @override
  _TicketsScreenState createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  String? selectedTicketId;
  Map<String, dynamic>? selectedTicketData;
  List<Map<String, dynamic>> admins = [];
  Map<String, dynamic> users = {};
  String searchQuery = '';
  String selectedFilter = 'title';
  DateTime? startDate;
  DateTime? endDate;
  List<String> statusOptions = ['Open', 'In Progress', 'Closed'];

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
            final data = doc.data() as Map<String, dynamic>;
            return {
              'id': doc.id,
              'name': data['fullName'] ?? 'No Name',
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

      if (mounted) {
        setState(() {
          users = {
            for (var doc in userSnapshot.docs) doc.id: doc.data()['fullName']
          };
        });
      }
    } catch (e) {
      _showSnackBar('Failed to fetch users: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
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
      ),
      body: Column(
        children: [
          _buildSearchAndFilterBar(),
          _buildDateRangePicker(),
          Expanded(
            child: selectedTicketId == null
                ? _buildTicketList()
                : _buildTicketDetail(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: 'Search tickets...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20.0),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey[200],
              prefixIcon: const Icon(Icons.search, color: Color(0XFF44564A)),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8.0,
                  children: [
                    FilterChip(
                      label: const Text('Title'),
                      selected: selectedFilter == 'title',
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = 'title';
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Description'),
                      selected: selectedFilter == 'description',
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = 'description';
                        });
                      },
                    ),
                    FilterChip(
                      label: const Text('Status'),
                      selected: selectedFilter == 'status',
                      onSelected: (selected) {
                        setState(() {
                          selectedFilter = 'status';
                        });
                      },
                    ),
                  ],
                ),
              ),
              if (startDate != null && endDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Color(0XFF44564A)),
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                    });
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ElevatedButton(
        onPressed: () async {
          DateTimeRange? picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2000),
            lastDate: DateTime.now(),
            initialDateRange: startDate != null && endDate != null
                ? DateTimeRange(start: startDate!, end: endDate!)
                : null,
            helpText: "Select a date range",
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  primaryColor: Color(0XFF44564A),
                  colorScheme:
                      const ColorScheme.light(primary: Color(0XFF44564A)),
                  buttonTheme:
                      const ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
                child: child!,
              );
            },
          );
          if (picked != null) {
            setState(() {
              startDate = picked.start;
              endDate = picked.end;
            });
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0XFF44564A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.calendar_today, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              startDate != null && endDate != null
                  ? '${DateFormat('MMM dd, yyyy').format(startDate!)} - ${DateFormat('MMM dd, yyyy').format(endDate!)}'
                  : 'Select Date Range',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _getFilteredTicketsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No tickets available'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16.0),
          itemCount: snapshot.data!.docs.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            String assignedAdminId = data['assignedAdminId'] ?? '';
            String publisherName = users[data['publisherId']] ?? 'Unknown';

            return Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () {
                  setState(() {
                    selectedTicketId = doc.id;
                    selectedTicketData = data;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        spacing: 8,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'No Title',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Published by: $publisherName',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          Text(
                            'Status: ${data['status'] ?? 'No Status'}',
                            style: TextStyle(
                              color: _getStatusColor(data['status']),
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
                          _assignAdminToTicket(doc.id, newValue!);
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

    final files = selectedTicketData!['files'] as List<dynamic>? ?? [];
    String status = selectedTicketData!['status'] ?? 'No Status';
    String publisherName =
        users[selectedTicketData!['publisherId']] ?? 'Unknown';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedTicketData!['title'] ?? 'No Title',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            selectedTicketData!['description'] ?? 'No Description',
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
                  icon: const Icon(Icons.download, color: Color(0XFF44564A)),
                  onPressed: () {
                    _downloadFile(fileUrl);
                  },
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getFilteredTicketsStream() {
    final collection = FirebaseFirestore.instance.collection('tickets');
    Query query = collection;

    if (searchQuery.length >= 3) {
      query = query.where(selectedFilter,
          isGreaterThanOrEqualTo: searchQuery,
          isLessThanOrEqualTo: searchQuery + '\uf8ff');
    }

    if (startDate != null && endDate != null) {
      query = query.where('createdDate',
          isGreaterThanOrEqualTo: startDate, isLessThanOrEqualTo: endDate);
    }

    return query.snapshots();
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
    if (await canLaunch(url)) {
      await launch(url);
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
