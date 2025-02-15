import 'package:cloud_firestore/cloud_firestore.dart';

class TicketFile {
  const TicketFile({
    required this.fileId,
    required this.fileName,
    required this.uploadedAt,
    required this.url,
  });

  final String fileId;
  final String fileName;
  final DateTime? uploadedAt;
  final String url;

  factory TicketFile.fromJson({
    required Map<String, dynamic> json,
    required String fileId,
  }) {
    return TicketFile(
      fileId: fileId,
      fileName: json['fileName'] ?? "No Filename",
      uploadedAt: (json['uploadedAt'] as Timestamp?)?.toDate(),
      url: json['url'] ?? "Missing url",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'uploadedAt': uploadedAt?.toIso8601String(),
      'url': url,
    };
  }
}
