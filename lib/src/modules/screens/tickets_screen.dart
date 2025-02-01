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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch admins: $e')),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch users: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(selectedTicketId == null ? 'Tickets' : 'Ticket Details'),
        backgroundColor: Theme.of(context).primaryColor,
        leading: selectedTicketId != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
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
          _buildSearchBar(),
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

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search tickets...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          const SizedBox(width: 10),
          ToggleButtons(
            isSelected: [
              selectedFilter == 'title',
              selectedFilter == 'description',
              selectedFilter == 'status',
            ],
            onPressed: (index) {
              setState(() {
                selectedFilter = ['title', 'description', 'status'][index];
              });
            },
            borderRadius: BorderRadius.circular(10),
            color: Theme.of(context).primaryColor,
            selectedColor: Colors.white,
            fillColor: Theme.of(context).primaryColor,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Title'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Description'),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('Status'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                DateTimeRange? picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: ThemeData.light().copyWith(
                        primaryColor: Theme.of(context).primaryColor,
                        colorScheme: ColorScheme.light(
                            primary: Theme.of(context).primaryColor),
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
              icon: const Icon(Icons.calendar_today),
              label: Text(
                startDate != null && endDate != null
                    ? '${DateFormat('dd/MM/yyyy').format(startDate!)} - ${DateFormat('dd/MM/yyyy').format(endDate!)}'
                    : 'Select Date Range',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
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
        return ListView(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            String assignedAdminId = data['assignedAdminId'] ?? '';
            String publisherName = users[data['publisherId']] ?? 'Unknown';

            return Card(
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                title: Text(
                  data['title'] ?? 'No Title',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['description'] ?? 'No Description',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Published by: $publisherName',
                      style: const TextStyle(color: Colors.grey),
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
                trailing: Text(
                  data['status'] ?? 'No Status',
                  style: const TextStyle(color: Colors.grey),
                ),
                onTap: () {
                  setState(() {
                    selectedTicketId = doc.id;
                    selectedTicketData = data;
                  });
                },
              ),
            );
          }).toList(),
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Title: ${selectedTicketData!['title']}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Description: ${selectedTicketData!['description']}',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              'Status:',
              style: const TextStyle(fontSize: 16),
            ),
            DropdownButton<String>(
              value: status,
              onChanged: (String? newValue) {
                _updateTicketStatus(selectedTicketId!, newValue!);
              },
              items:
                  statusOptions.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Published by: $publisherName',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            const Text(
              'Files:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...files.map((fileUrl) {
              return ListTile(
                title: Text(fileUrl),
                trailing: IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () {
                    _downloadFile(fileUrl);
                  },
                ),
              );
            }).toList(),
          ],
        ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin assigned successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign admin: $error')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status updated successfully')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    });
  }

  void _downloadFile(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }
}
