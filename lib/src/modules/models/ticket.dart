import 'package:cloud_firestore/cloud_firestore.dart';

import 'ticket_file.dart';
import '../../config/enums/ticket_status.dart';

class Ticket {
  const Ticket({
    required this.ticketId,
    required this.title,
    required this.description,
    required this.status,
    required this.publisher,
    required this.createdDate,
    this.files = const [],
  });

  final String ticketId;
  final String title;
  final String description;
  final TicketStatus status;
  final String publisher;
  final DateTime? createdDate;
  final List<TicketFile> files;

  Ticket copyWith({List<TicketFile>? files}) => Ticket(
        ticketId: ticketId,
        title: title,
        description: description,
        status: status,
        publisher: publisher,
        createdDate: createdDate,
        files: files ?? this.files,
      );

  factory Ticket.fromJson({
    required Map<String, dynamic> json,
    required String ticketId,
    List<TicketFile> files = const [],
    String? publisher,
  }) {
    return Ticket(
      ticketId: ticketId,
      title: json['title'] ?? "No Title",
      description: json['description'] ?? "No Description",
      status: TicketStatus.fromString(json['status'] ?? "Unknown"),
      publisher: publisher ?? "Unknown Publisher",
      createdDate: (json['createdDate'] as Timestamp?)?.toDate(),
      files: files,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'title': title,
      'description': description,
      'status': status.toString(),
      'publisher': publisher,
      'createdDate': createdDate?.toIso8601String(),
    };
  }
}
