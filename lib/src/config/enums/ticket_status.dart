import 'package:flutter/material.dart';

enum TicketStatus {
  open,
  closed,
  inProgress,
  canceled,
  needReWork,
  unknown;

  static TicketStatus fromString(String status) {
    switch (status) {
      case 'Open':
        return TicketStatus.open;
      case 'In Progress':
        return TicketStatus.inProgress;
      case 'Closed':
        return TicketStatus.closed;
      case 'Canceled':
        return TicketStatus.canceled;
      case 'Need Re-work':
        return TicketStatus.needReWork;
      default:
        return TicketStatus.unknown;
    }
  }

  Color getColor() {
    switch (this) {
      case TicketStatus.open:
        return Colors.blue;
      case TicketStatus.inProgress:
        return Colors.orange;
      case TicketStatus.closed:
        return Colors.green;
      case TicketStatus.canceled:
        return Colors.red;
      case TicketStatus.needReWork:
        return Colors.deepOrange;
      case TicketStatus.unknown:
        return Colors.grey;
    }
  }

  @override
  String toString() => name[0].toUpperCase() + name.substring(1);
}
