import 'package:cloud_firestore/cloud_firestore.dart';

import '../../service/synchronized_time.dart';

class FileComment {
  FileComment({
    required this.message,
    required this.senderId,
    required this.createdAt,
  });

  final String message;
  final String senderId;
  final DateTime createdAt;

  factory FileComment.fromJson(Map<String, dynamic> json) {
    SynchronizedTime.initialize();
    return FileComment(
      message: json['message'] ?? "",
      senderId: json["senderId"] ?? "Unknown Sender",
      createdAt:
      (json["timestamp"] as Timestamp?)?.toDate() ?? SynchronizedTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'senderId': senderId,
      'createdTime': createdAt.toIso8601String(),
    };
  }
}
