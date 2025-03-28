import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/enums/ticket_status.dart';
import '../models/ticket_file.dart';
import 'comment_screen.dart';
import '../../service/data_service.dart';

const Color primaryColor = Color(0xFF44564A);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardColor = Colors.white;
final TextStyle boldTextStyle = TextStyle(
  fontWeight: FontWeight.bold,
  color: primaryColor,
);

class TicketsScreen extends StatefulWidget {
  final String? userId;

  const TicketsScreen({super.key, this.userId});
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

  Future<bool> _handleWillPop() async {
    if (selectedTicketId != null) {
      setState(() {
        selectedTicketId = null;
        selectedTicketData = null;
      });
      return false;
    }
    return true;
  }

  void _handleBackButton() {
    if (selectedTicketId != null) {
      setState(() {
        selectedTicketId = null;
        selectedTicketData = null;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: Text(
            selectedTicketId == null ? 'Tickets' : 'Ticket Details',
            style: boldTextStyle.copyWith(fontSize: 24),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: primaryColor),
            onPressed: _handleBackButton,
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              if (selectedTicketId == null) _buildSearchAndFilterBar(),
              const SizedBox(height: 16),
              Expanded(
                child: selectedTicketId == null
                    ? _buildTicketList()
                    : _buildTicketDetail(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.4,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search tickets...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      prefixIcon: const Icon(
                        Icons.search,
                        color: primaryColor,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                ),
                const SizedBox(width: 10),
                _buildStatusDropdown(),
                const SizedBox(width: 10),
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: primaryColor),
                  onPressed: () => _showDateRangePicker(context),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all, color: primaryColor),
                  onPressed: _clearAllFilters,
                ),
              ],
            ),
            if (selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${DateFormat('MMM dd').format(selectedDateRange!.start)} - ${DateFormat('MMM dd').format(selectedDateRange!.end)}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButton<String>(
        value: selectedFilter == 'status' ? selectedFilterValue : null,
        hint: const Text(
          'Status',
          style: TextStyle(color: primaryColor),
        ),
        icon: const Icon(Icons.arrow_drop_down, color: primaryColor),
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          setState(() {
            selectedFilter = 'status';
            selectedFilterValue = newValue;
          });
        },
        items: statusOptions.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(
              value,
              style: const TextStyle(color: primaryColor),
            ),
          );
        }).toList(),
      ),
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
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
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

  void _clearAllFilters() {
    setState(() {
      searchQuery = '';
      searchController.clear();
      selectedFilter = 'title';
      selectedFilterValue = null;
      selectedDateRange = null;
    });
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

    // Filter by user ID if provided
    if (widget.userId != null) {
      tickets =
          tickets.where((ticket) => ticket['userId'] == widget.userId).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
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

    // Filter by status
    if (selectedFilter == 'status' && selectedFilterValue != null) {
      tickets = tickets.where((ticket) {
        return ticket['status'] == selectedFilterValue;
      }).toList();
    }

    // Filter by date range
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
              margin: const EdgeInsets.only(bottom: 16),
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
                              color: TicketStatus.fromString(
                                ticket['status'],
                              ).getColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      _buildAdminDropdown(ticket['id'], assignedAdminId),
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

  Widget _buildAdminDropdown(String ticketId, String assignedAdminId) {
    final uniqueAdmins = admins
        .fold<Map<String, Map<String, dynamic>>>(
          {},
          (map, admin) {
            if (!map.containsKey(admin['id'])) {
              map[admin['id']] = admin;
            }
            return map;
          },
        )
        .values
        .toList();

    // Check if the assignedAdminId exists in our unique admins
    final validAssignedAdmin =
        uniqueAdmins.any((admin) => admin['id'] == assignedAdminId);

    return DropdownButton<String>(
      value: validAssignedAdmin ? assignedAdminId : null,
      hint: const Text('Assign Admin'),
      onChanged: (String? newValue) {
        _assignAdminToTicket(ticketId, newValue);
      },
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('Unassigned'),
        ),
        ...uniqueAdmins.map((admin) {
          return DropdownMenuItem<String>(
            value: admin['id'] as String,
            child: Text(admin['name'] as String),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildTicketDetail() {
    if (selectedTicketData == null) return Container();

    return StreamBuilder<List<Map<String, String>>>(
      stream: DataService.getTicketFiles(selectedTicketId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No attachments available'));
        }

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
              Container(
                padding: const EdgeInsets.only(right: 8),
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => FutureBuilder<List<String>>(
                        future: DataService.getUserCompany(
                            selectedTicketData?['userId']),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }
                          bool isOtherText = false;
                          String otherText = '';
                          if (snapshot.hasError) {
                            isOtherText = true;
                            otherText = 'Something went wrong!';
                          } else if (!snapshot.hasData) {
                            isOtherText = true;
                            otherText = 'No Companies Listed';
                          } else if (snapshot.data!.isEmpty) {
                            isOtherText = true;
                            otherText = 'No Companies Listed';
                          }
                          return AlertDialog(
                            title: const Text('Companies'),
                            content: !isOtherText
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: snapshot.data!
                                        .map(
                                          (company) => Text(company),
                                        )
                                        .toList(),
                                  )
                                : Text(otherText),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text("Ok"),
                              ),
                            ],
                          );
                        },
                      ),
                    );
                  },
                  label: const Text('Show Companies'),
                  icon: const Icon(Icons.business),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Published by: '
                '${users[selectedTicketData?['userId']] ?? 'Unknown'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedTicketData?['status'],
                decoration: InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onChanged: (String? newValue) {
                  _updateTicketStatus(selectedTicketId!, newValue!);
                },
                items: statusOptions.map<DropdownMenuItem<String>>(
                  (String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  },
                ).toList(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Attachments:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...snapshot.data!.map((file) {
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    title: Text(file['fileName'] ?? 'Unknown File'),
                    onTap: () {
                      final fileId = file['fileId'];
                      if (fileId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CommentScreen(
                              ticketId: selectedTicketId!,
                              file: TicketFile.fromJson(
                                json: file,
                                fileId: fileId,
                              ),
                            ),
                          ),
                        );
                      } else {
                        debugPrint('File ID is null');
                      }
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.download, color: primaryColor),
                      onPressed: () {
                        _downloadFile(file['url']!);
                      },
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _assignAdminToTicket(String ticketId, String? adminId) {
    FirebaseFirestore.instance
        .collection('tickets')
        .doc(ticketId)
        .update({'assignedAdminId': adminId}).then((_) {
      _showSnackBar(adminId == null
          ? 'Admin unassigned successfully'
          : 'Admin assigned successfully');
    }).catchError((error) {
      _showSnackBar('Failed to update admin assignment: $error');
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
}
