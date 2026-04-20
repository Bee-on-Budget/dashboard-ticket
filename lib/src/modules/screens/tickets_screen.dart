import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../../config/enums/ticket_status.dart';
import '../../config/enums/user_role.dart';
import '../models/ticket_file.dart';
import 'comment_screen.dart';
import '../../service/data_service.dart';
import '../../config/db_collections.dart';

const Color primaryColor = Color(0xFF44564A);
const Color backgroundColor = Color(0xFFF5F5F5);
const Color cardColor = Color(0xFFBCD3B9);
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
  final TextEditingController referenceController = TextEditingController();
  String? selectedTicketId;
  Map<String, dynamic>? selectedTicketData;
  String? selectedFilterValue;
  int _currentPage = 1;
  int _itemsPerPage = 10;
  List<int> _pageSizeOptions = [5, 10, 20, 30];
  List<Map<String, dynamic>> _allTickets = [];
  int _totalTickets = 0;
  String? _scrollToTicketId;
  List<Map<String, dynamic>> admins = [];
  Map<String, dynamic> users = {};
  Map<String, List<String>> userCompanies = {};
  String searchQuery = '';
  String selectedFilter = 'title';
  DateTimeRange? selectedDateRange;
  List<String> statusOptions = [
    'Open',
    'In Progress',
    'Closed',
    'Canceled',
    'Need Re-work'
  ];
  Timer? _debounce;
  bool _isExporting = false;
  Set<String> selectedTicketIds = {};
  bool selectAll = false;
  bool _isLoadingCurrentUser = true;
  UserRole _currentUserRole = UserRole.unknown;
  List<String> _currentUserCompanies = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserContext();
    _fetchAdmins();
    _fetchUsers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    referenceController.dispose();
    super.dispose();
  }

  Future<void> _fetchAdmins() async {
    try {
      final adminSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .where('role', whereIn: ['admin', 'Admin'])
          .where('isActive', isEqualTo: true)
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

  Future<void> _loadCurrentUserContext() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (mounted) {
        setState(() {
          _currentUserRole = UserRole.unknown;
          _currentUserCompanies = [];
          _isLoadingCurrentUser = false;
        });
      }
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .doc(currentUser.uid)
          .get();
      final userData = userDoc.data() ?? <String, dynamic>{};

      if (mounted) {
        setState(() {
          _currentUserRole =
              UserRole.fromString(userData['role']?.toString());
          _currentUserCompanies =
              List<String>.from(userData['companies'] ?? const []);
          _isLoadingCurrentUser = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentUserRole = UserRole.unknown;
          _currentUserCompanies = [];
          _isLoadingCurrentUser = false;
        });
      }
      _showSnackBar('Failed to load your access permissions: $e');
    }
  }

  Future<void> _fetchUsers() async {
    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.users)
          .where('isActive', isEqualTo: true)
          .get();

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

  bool get _isAdmin => _currentUserRole == UserRole.admin;

  bool _canAccessTicket(Map<String, dynamic> ticket) {
    if (_isAdmin || widget.userId != null) {
      return true;
    }

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final publisherId = ticket['userId']?.toString();

    if (_currentUserRole == UserRole.user) {
      return publisherId == currentUserId;
    }

    if (_currentUserRole == UserRole.accountent) {
      final publisherCompanies = userCompanies[publisherId] ?? const <String>[];
      return publisherCompanies
          .toSet()
          .intersection(_currentUserCompanies.toSet())
          .isNotEmpty;
    }

    return false;
  }

  Future<bool> _handleWillPop() async {
    if (selectedTicketId != null) {
      final ticketId = selectedTicketId;
      setState(() {
        selectedTicketId = null;
        selectedTicketData = null;
        _scrollToTicketId = ticketId;
      });
      return false;
    }
    return true;
  }

  void _handleBackButton() {
    if (selectedTicketId != null) {
      final ticketId = selectedTicketId;
      setState(() {
        selectedTicketId = null;
        selectedTicketData = null;
        _scrollToTicketId = ticketId; // Set flag to scroll to this ticket
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _exportToExcel(List<Map<String, dynamic>> tickets) async {
    if (_isExporting) return;

    setState(() {
      _isExporting = true;
    });

    try {
      var excel = Excel.createExcel();
      Sheet sheetObject = excel['Tickets'];

      // Add headers - include Payment Method
      List<String> headers = [
        'Title',
        'Reference',
        'Reference ID',
        'Description',
        'Status',
        'Published By',
        'Company',
        'Payment Method', // Column for payment method from ticket
        'Assigned Admin',
        'Created Date',
        'Latest Upload Date',
        'Attachments'
      ];
      CellStyle headerStyle = CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString('#44564A'),
        fontColorHex: ExcelColor.fromHexString('#FFFFFF'),
      );

      for (int i = 0; i < headers.length; i++) {
        var cell = sheetObject
            .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
        cell.value = TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      // Add data rows
      for (int i = 0; i < tickets.length; i++) {
        final ticket = tickets[i];

        final attachmentNames =
            (ticket['attachmentNames'] as List<dynamic>? ?? const [])
                .map((name) => name.toString())
                .toList();

        String publisherName = users[ticket['userId']] ?? 'Unknown';
        String companyName = userCompanies[ticket['userId']]?.isNotEmpty == true
            ? userCompanies[ticket['userId']]!.join(', ')
            : 'N/A';

        // Get payment method directly from ticket document
        String paymentMethod = ticket['paymentMethod']?.toString() ?? 'N/A';

        String assignedAdminName = 'Unassigned';
        if (ticket['assignedAdminId'] != null) {
          final admin = admins.firstWhere(
            (a) => a['id'] == ticket['assignedAdminId'],
            orElse: () => {'name': 'Unknown Admin'},
          );
          assignedAdminName = admin['name'] as String;
        }

        String createdDate = ticket['createdDate'] != null
            ? DateFormat('MMM dd, yyyy - HH:mm')
                .format((ticket['createdDate'] as Timestamp).toDate())
            : 'N/A';

        String latestUploadDate = ticket['latestUploadDate'] != null
            ? DateFormat('MMM dd, yyyy - HH:mm')
                .format(ticket['latestUploadDate'] as DateTime)
            : 'N/A';

        String attachments = attachmentNames.isEmpty
            ? 'No attachments'
            : attachmentNames.join('; ');

        List<dynamic> rowData = [
          ticket['title'] ?? 'No Title',
          ticket['reference'] ?? 'N/A',
          ticket['ref_id'] ?? 'N/A',
          ticket['description'] ?? 'No Description',
          ticket['status'] ?? 'No Status',
          publisherName,
          companyName,
          paymentMethod, // Add payment method from ticket
          assignedAdminName,
          createdDate,
          latestUploadDate,
          attachments,
        ];

        for (int j = 0; j < rowData.length; j++) {
          var cell = sheetObject.cell(
              CellIndex.indexByColumnRow(columnIndex: j, rowIndex: i + 1));
          cell.value = TextCellValue(rowData[j].toString());
        }
      }

      // Auto-fit columns
      for (int i = 0; i < headers.length; i++) {
        sheetObject.setColumnWidth(i, 20);
      }

      // Save file
      var fileBytes = excel.save();
      if (fileBytes != null) {
        try {
          final directory = await getApplicationDocumentsDirectory();
          final timestamp =
              DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final statusFilter =
              selectedFilterValue != null ? '_${selectedFilterValue}' : '_All';
          final filePath =
              '${directory.path}/tickets_export$statusFilter$timestamp.xlsx';

          File(filePath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(fileBytes);

          _showSnackBar('Excel file exported successfully to: $filePath');

          // Optional: Open the file location
          if (Platform.isAndroid || Platform.isIOS) {
            _showSnackBar('File saved to Documents folder');
          }
        } catch (e) {
          // Fallback for platforms where getApplicationDocumentsDirectory fails
          try {
            final directory = Directory.systemTemp;
            final timestamp =
                DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
            final statusFilter = selectedFilterValue != null
                ? '_${selectedFilterValue}'
                : '_All';
            final filePath =
                '${directory.path}/tickets_export$statusFilter$timestamp.xlsx';

            File(filePath)
              ..createSync(recursive: true)
              ..writeAsBytesSync(fileBytes);

            _showSnackBar(
                'Excel file exported successfully to temp folder: $filePath');
          } catch (fallbackError) {
            _showSnackBar('Failed to save file: $fallbackError');
          }
        }
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: backgroundColor,
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

  Future<void> _exportCurrentView() async {
    // Reuse the currently loaded filtered tickets to avoid refetching every
    // ticket and its files again just for export.
    final allTickets = _allTickets.isNotEmpty
        ? List<Map<String, dynamic>>.from(_allTickets)
        : await _getFilteredTicketsStream().first;
    List<Map<String, dynamic>> ticketsToExport;
    if (selectAll) {
      ticketsToExport = allTickets;
    } else if (selectedTicketIds.isNotEmpty) {
      ticketsToExport =
          allTickets.where((t) => selectedTicketIds.contains(t['id'])).toList();
    } else {
      ticketsToExport = allTickets;
    }
    if (ticketsToExport.isEmpty) {
      _showSnackBar('No tickets to export');
      return;
    }
    await _exportToExcel(ticketsToExport);
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
                  width: MediaQuery.of(context).size.width * 0.35,
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search Tickets..',
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
                  tooltip: 'Select Date Range',
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: primaryColor),
                  onPressed: _clearAllFilters,
                  tooltip: 'Refresh Filters',
                ),
                IconButton(
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download, color: primaryColor),
                  onPressed: _isExporting ? null : _exportCurrentView,
                  tooltip: 'Export to Excel',
                ),
              ],
            ),
            if (selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  '${DateFormat('MMM dd, yyyy').format(selectedDateRange!.start)} - ${DateFormat('MMM dd, yyyy').format(selectedDateRange!.end)}',
                  style: const TextStyle(
                    color: primaryColor,
                    fontSize: 12,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: (bool? value) {
                    setState(() {
                      selectAll = value ?? false;
                      if (!selectAll) {
                        selectedTicketIds.clear();
                      }
                    });
                  },
                ),
                const Text('Select All'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> _getFilteredTicketsStream() async* {
    // Base query construction
    Query query = FirebaseFirestore.instance.collection(DbCollections.tickets);
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    // Server-side filters
    if (widget.userId != null) {
      query = query.where('userId', isEqualTo: widget.userId);
    } else if (_currentUserRole == UserRole.user && currentUserId != null) {
      query = query.where('userId', isEqualTo: currentUserId);
    }
    if (selectedFilter == 'status' && selectedFilterValue != null) {
      query = query.where('status', isEqualTo: selectedFilterValue);
    }
    if (selectedDateRange != null) {
      final startDate = DateTime(selectedDateRange!.start.year,
          selectedDateRange!.start.month, selectedDateRange!.start.day);
      final endDate = DateTime(selectedDateRange!.end.year,
          selectedDateRange!.end.month, selectedDateRange!.end.day, 23, 59, 59);

      query = query
          .where('createdDate',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdDate',
              isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }

    // Get tickets
    final ticketsSnapshot = await query.get();
    if (ticketsSnapshot.docs.isEmpty) {
      yield [];
      return;
    }

    // Parallel file loading
    final filesFutures = ticketsSnapshot.docs.map((ticketDoc) async {
      final filesSnapshot = await FirebaseFirestore.instance
          .collection(DbCollections.tickets)
          .doc(ticketDoc.id)
          .collection('files')
          .orderBy('uploadedAt', descending: true)
          .get();

      DateTime? latestUploadDate;
      List<String> fileIds = [];
      List<String> attachmentNames = [];
      int fileCount = 0;

      if (filesSnapshot.docs.isNotEmpty) {
        fileIds = filesSnapshot.docs.map((fileDoc) => fileDoc.id).toList();
        attachmentNames = filesSnapshot.docs
            .map(
              (fileDoc) =>
                  fileDoc.data()['fileName']?.toString() ?? 'Unknown File',
            )
            .toList();
        fileCount = filesSnapshot.docs.length;

        final latestFile = filesSnapshot.docs.first;
        latestUploadDate =
            (latestFile.data()['uploadedAt'] as Timestamp?)?.toDate();
      } else {
        try {
          final files = await DataService.getTicketFiles(ticketDoc.id);
          fileIds = files
              .map((file) => file['fileId'] ?? '')
              .where((id) => id.isNotEmpty)
              .toList();
          attachmentNames = files
              .map((file) => file['fileName'] ?? 'Unknown File')
              .toList();
          fileCount = files.length;

          if (files.isNotEmpty) {
            latestUploadDate = null;
          }
        } catch (e) {
          debugPrint(
              'Error fetching files from storage for ticket ${ticketDoc.id}: $e');
          fileIds = [];
          attachmentNames = [];
          fileCount = 0;
        }
      }

      return {
        'ticketId': ticketDoc.id,
        'fileCount': fileCount,
        'fileIds': fileIds,
        'attachmentNames': attachmentNames,
        'latestUploadDate': latestUploadDate,
      };
    });

    final filesResults = await Future.wait(filesFutures);
    final filesMap = {
      for (var result in filesResults)
        result['ticketId'] as String: {
          'fileIds': result['fileIds'] as List<String>,
          'fileCount': result['fileCount'] as int,
          'attachmentNames': result['attachmentNames'] as List<String>,
          'latestUploadDate': result['latestUploadDate'] as DateTime?,
        }
    };

    // Convert tickets with type safety
    final tickets = ticketsSnapshot.docs.map<Map<String, dynamic>>((doc) {
      final data = doc.data();
      return {
        if (data is Map<String, dynamic>) ...data,
        'id': doc.id,
        'fileIds': filesMap[doc.id]?['fileIds'] ?? <String>[],
        'fileCount': filesMap[doc.id]?['fileCount'] ?? 0,
        'attachmentNames': filesMap[doc.id]?['attachmentNames'] ?? <String>[],
        'latestUploadDate': filesMap[doc.id]?['latestUploadDate'],
      };
    }).toList();

    tickets.retainWhere(_canAccessTicket);

    // Apply client-side search filter
    if (searchQuery.isNotEmpty) {
      final searchLower = searchQuery.toLowerCase();
      tickets.retainWhere((ticket) {
        final String title = (ticket['title']?.toString() ?? '').toLowerCase();
        final String description =
            (ticket['description']?.toString() ?? '').toLowerCase();
        final String publisherId = ticket['userId']?.toString() ?? '';
        final String ticketRefId =
            (ticket['ref_id']?.toString() ?? '').toLowerCase();
        final String ticketReference =
            (ticket['reference']?.toString() ?? '').toLowerCase();

        final String publisherName =
            (users[publisherId]?.toString() ?? '').toLowerCase();
        final List<String> fileIds =
            (ticket['fileIds'] as List<dynamic>).cast<String>();
        final List<String> companies = (userCompanies[publisherId] ?? [])
            .map((e) => e.toString().toLowerCase())
            .toList();

        return title.contains(searchLower) ||
            description.contains(searchLower) ||
            publisherName.contains(searchLower) ||
            ticketReference.contains(searchLower) ||
            ticketRefId.contains(searchLower) ||
            fileIds
                .any((fileId) => fileId.toLowerCase().contains(searchLower)) ||
            companies.any((company) => company.contains(searchLower));
      });
    }

    // Store all tickets for pagination
    _allTickets = tickets;
    _totalTickets = tickets.length;

    yield tickets;
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
      lastDate: DateTime(2030),
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
      selectedTicketIds.clear();
      selectAll = false;
      _currentPage = 1;
    });
  }

  List<Map<String, dynamic>> _getPaginatedTickets(
      List<Map<String, dynamic>> allTickets) {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= allTickets.length) {
      return [];
    }

    return allTickets.sublist(
      startIndex,
      endIndex > allTickets.length ? allTickets.length : endIndex,
    );
  }

  Widget _buildTicketList() {
    if (_isLoadingCurrentUser) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getFilteredTicketsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No tickets available'));
        }

        final allTickets = snapshot.data!;
        final paginatedTickets = _getPaginatedTickets(allTickets);
        final totalPages = (_totalTickets / _itemsPerPage).ceil();

        // Scroll to ticket if needed
        if (_scrollToTicketId != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToTicket(_scrollToTicketId!);
          });
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                key: PageStorageKey<String>('ticket_list'),
                itemCount: paginatedTickets.length,
                itemBuilder: (context, index) {
                  final ticket = paginatedTickets[index];
                  String assignedAdminId = ticket['assignedAdminId'] ?? '';
                  String publisherName = users[ticket['userId']] ?? 'Unknown';
                  String companyName =
                      userCompanies[ticket['userId']]?.isNotEmpty == true
                          ? userCompanies[ticket['userId']]!.join(', ')
                          : '';

                  return Card(
                    key: ValueKey(ticket['id']),
                    elevation: 2,
                    color: cardColor,
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
                          referenceController.text = ticket['reference'] ?? '';
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Checkbox(
                              value: selectAll ||
                                  selectedTicketIds.contains(ticket['id']),
                              onChanged: (bool? value) {
                                setState(() {
                                  if (selectAll) {
                                    selectAll = false;
                                    if (value == true) {
                                      selectedTicketIds.add(ticket['id']);
                                    }
                                  } else {
                                    if (value == true) {
                                      selectedTicketIds.add(ticket['id']);
                                    } else {
                                      selectedTicketIds.remove(ticket['id']);
                                    }
                                  }
                                });
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ticket['title'] ?? 'No Title',
                                    style: boldTextStyle.copyWith(fontSize: 18),
                                  ),
                                  if (ticket['reference']?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Reference: ${ticket['reference']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  Text(
                                    'Published by: $publisherName',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                  if (companyName.isNotEmpty)
                                    Text(
                                      'Company: $companyName',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  if (ticket['paymentMethod'] != null &&
                                      ticket['paymentMethod']
                                          .toString()
                                          .isNotEmpty)
                                    Text(
                                      'Payment Method: ${ticket['paymentMethod']}',
                                      style: TextStyle(
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w500,
                                        fontSize: 13,
                                      ),
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
                                  const SizedBox(height: 4),
                                  if (ticket['ref_id']?.isNotEmpty == true)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'Reference Id: ${ticket['ref_id']}',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  if (ticket['createdDate'] != null)
                                    Text(
                                      'Created: ${DateFormat('MMM dd, yyyy - HH:mm').format((ticket['createdDate'] as Timestamp).toDate())}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (ticket['latestUploadDate'] != null)
                                    Text(
                                      'Latest Upload: ${DateFormat('MMM dd, yyyy - HH:mm').format(ticket['latestUploadDate'] as DateTime)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  if (ticket['lastUpdate'] != null)
                                    Text(
                                      'Last Update: ${DateFormat('MMM dd, yyyy - HH:mm').format((ticket['lastUpdate'] as Timestamp).toDate())}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  const SizedBox(height: 4),
                                  if (ticket['fileIds'] != null &&
                                      (ticket['fileIds'] as List).isNotEmpty)
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.attach_file,
                                          size: 16,
                                          color: Colors.grey[600],
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(ticket['fileIds'] as List).length} attachment${(ticket['fileIds'] as List).length == 1 ? '' : 's'}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                            _buildAdminDropdown(ticket['id'], assignedAdminId),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            _buildPaginationControls(totalPages),
          ],
        );
      },
    );
  }

  Widget _buildPaginationControls(int totalPages) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Page size dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButton<int>(
              value: _itemsPerPage,
              underline: const SizedBox(),
              items: _pageSizeOptions.map((size) {
                return DropdownMenuItem<int>(
                  value: size,
                  child: Text('$size per page'),
                );
              }).toList(),
              onChanged: (newSize) {
                setState(() {
                  _itemsPerPage = newSize!;
                  _currentPage = 1; // Reset to first page
                });
              },
            ),
          ),
          const SizedBox(width: 16),
          // First page button
          IconButton(
            icon: const Icon(Icons.first_page),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage = 1;
                    });
                  }
                : null,
            color: primaryColor,
          ),
          // Previous page button
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            color: primaryColor,
          ),
          // Page indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Page $_currentPage of $totalPages',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Next page button
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            color: primaryColor,
          ),
          // Last page button
          IconButton(
            icon: const Icon(Icons.last_page),
            onPressed: _currentPage < totalPages
                ? () {
                    setState(() {
                      _currentPage = totalPages;
                    });
                  }
                : null,
            color: primaryColor,
          ),
          const SizedBox(width: 16),
          // Total count
          Text(
            'Total: $_totalTickets',
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToTicket(String ticketId) {
    // Find the page containing this ticket
    final ticketIndex = _allTickets.indexWhere((t) => t['id'] == ticketId);
    if (ticketIndex != -1) {
      final targetPage = (ticketIndex / _itemsPerPage).floor() + 1;
      setState(() {
        _currentPage = targetPage;
        _scrollToTicketId = null; // Clear the flag
      });
    }
  }

  Widget _buildAdminDropdown(String ticketId, String assignedAdminId) {
    final assignedAdminName = admins.firstWhere(
      (admin) => admin['id'] == assignedAdminId,
      orElse: () => {'name': 'Unassigned'},
    )['name'] as String;

    if (!_isAdmin) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          assignedAdminName,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (admins.isEmpty) {
      return const Text('No admins available');
    }

    // Create a list of unique admins (by ID)
    final uniqueAdmins = admins
        .fold<Map<String, Map<String, dynamic>>>(
          {},
          (map, admin) {
            final id = admin['id'] as String;
            if (!map.containsKey(id)) {
              map[id] = admin;
            }
            return map;
          },
        )
        .values
        .toList();

    // Check if the current assignedAdminId exists in our unique admins
    final isValidAssignedAdmin =
        uniqueAdmins.any((admin) => admin['id'] == assignedAdminId);

    // Determine color based on assignment status
    final bool isAssigned = assignedAdminId.isNotEmpty && isValidAssignedAdmin;
    final Color dropdownColor = isAssigned ? primaryColor : Colors.grey;
    final Color textColor = isAssigned ? Colors.white : Colors.black87;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: dropdownColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: ButtonTheme(
          alignedDropdown: true,
          child: DropdownButton<String>(
            value: isValidAssignedAdmin ? assignedAdminId : null,
            hint: Text(
              'Assign Admin',
              style: TextStyle(color: textColor, fontSize: 14),
            ),
            icon: Icon(Icons.arrow_drop_down, color: textColor),
            dropdownColor: Colors.white,
            isDense: true,
            selectedItemBuilder: (BuildContext context) {
              return [
                Center(
                  child: Text(
                    'Unassigned',
                    style: TextStyle(color: textColor, fontSize: 14),
                  ),
                ),
                ...uniqueAdmins.map((admin) {
                  return Center(
                    child: Text(
                      admin['name'] as String,
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  );
                }).toList(),
              ];
            },
            onChanged: (String? newValue) {
              _assignAdminToTicket(ticketId, newValue);
            },
            items: [
              DropdownMenuItem<String>(
                value: null,
                child: const Text(
                  'Unassigned',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
              ...uniqueAdmins.map((admin) {
                return DropdownMenuItem<String>(
                  value: admin['id'] as String,
                  child: Text(
                    admin['name'] as String,
                    style: const TextStyle(color: Colors.black87),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTicketDetail() {
    if (selectedTicketData == null) return Container();

    String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    bool isAssignedToCurrentUser =
        selectedTicketData?['assignedAdminId'] == currentUserUid;
    final canEditReference = _isAdmin;
    final canEditStatus = _isAdmin || isAssignedToCurrentUser;

    return FutureBuilder<List<Map<String, String>>>(
      future: DataService.getTicketFiles(selectedTicketId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final files = snapshot.data ?? [];

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: primaryColor),
                    onPressed: _handleBackButton,
                  ),
                  Expanded(
                    child: Text(
                      selectedTicketData?['title'] ?? 'No Title',
                      style: boldTextStyle.copyWith(fontSize: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                selectedTicketData?['description'] ?? 'No Description',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              if (selectedTicketData?['createdDate'] != null)
                Text(
                  'Created: ${DateFormat('MMM dd, yyyy - HH:mm').format((selectedTicketData!['createdDate'] as Timestamp).toDate())}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              if (selectedTicketData?['latestUploadDate'] != null)
                Text(
                  'Latest Upload: ${DateFormat('MMM dd, yyyy - HH:mm').format(selectedTicketData!['latestUploadDate'] as DateTime)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              if (selectedTicketData?['lastUpdate'] != null)
                Text(
                  'Last Update: ${DateFormat('MMM dd, yyyy - HH:mm').format((selectedTicketData!['lastUpdate'] as Timestamp).toDate())}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              const SizedBox(height: 16),
              // Display Payment Method in ticket detail
              if (selectedTicketData?['paymentMethod'] != null &&
                  selectedTicketData!['paymentMethod'].toString().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.payment,
                          color: primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Payment Method: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          '${selectedTicketData!['paymentMethod']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              TextField(
                controller: referenceController,
                readOnly: !canEditReference,
                decoration: InputDecoration(
                  labelText: 'Reference',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  suffixIcon: canEditReference
                      ? IconButton(
                          icon: const Icon(Icons.save),
                          onPressed: () {
                            _saveReference(
                                selectedTicketId!, referenceController.text);
                          },
                        )
                      : null,
                ),
                onSubmitted: canEditReference
                    ? (value) {
                        _saveReference(selectedTicketId!, value);
                      }
                    : null,
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
                onChanged: (canEditStatus)
                    ? (String? newValue) {
                        _updateTicketStatus(selectedTicketId!, newValue!);
                      }
                    : null,
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
              if (files.isNotEmpty)
                ...files.map((file) {
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
              if (files.isEmpty)
                const Center(child: Text('No attachments available')),
            ],
          ),
        );
      },
    );
  }

  void _assignAdminToTicket(String ticketId, String? adminId) {
    FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .doc(ticketId)
        .update({
      'assignedAdminId': adminId,
      'lastUpdate': FieldValue.serverTimestamp(),
    }).then((_) {
      _showSnackBar(adminId == null
          ? 'Admin unassigned successfully'
          : 'Admin assigned successfully');
    }).catchError((error) {
      _showSnackBar('Failed to update admin assignment: $error');
    });
  }

  void _updateTicketStatus(String ticketId, String newStatus) {
    FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .doc(ticketId)
        .update({
      'status': newStatus,
      'lastUpdate': FieldValue.serverTimestamp(),
    }).then((_) {
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

  void _saveReference(String ticketId, String reference) {
    FirebaseFirestore.instance
        .collection(DbCollections.tickets)
        .doc(ticketId)
        .update({
      'reference': reference,
      'lastUpdate': FieldValue.serverTimestamp(),
    }).then((_) {
      setState(() {
        if (selectedTicketData != null) {
          selectedTicketData!['reference'] = reference;
        }
      });
      _showSnackBar('Reference saved successfully');
    }).catchError((error) {
      _showSnackBar('Failed to save reference: $error');
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
