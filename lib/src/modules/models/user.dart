import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/enums/payment_methods.dart';
import '../../config/enums/user_role.dart';

class User {
  final String id; // Document ID from Firestore
  final String
      userId; // User ID (could be the same as `id` or a separate field)
  final String username;
  final UserRole role;
  final String email;
  final String phoneNumber;
  final List<PaymentMethods> paymentMethods;
  final DateTime? createdAt;
  final List<String> companies;
  final bool isActive; // Add this field

  const User({
    required this.id,
    required this.userId,
    required this.username,
    required this.role,
    required this.email,
    required this.phoneNumber,
    required this.paymentMethods,
    required this.createdAt,
    required this.companies,
    this.isActive = true, // Default to true
  });

  factory User.fromJson(Map<String, dynamic> json, String id) {
    return User(
      id: id, // Use the `id` parameter passed to the factory constructor
      userId: json["userId"] ?? id, // Use `id` if `userId` is not provided
      username: json["username"] ?? "No Username",
      role: UserRole.fromString(json["role"] ?? "unknown"),
      email: json["identifier"] ?? "No Email",
      phoneNumber: _getPhoneFromEmail(json["phoneNumber"]),
      paymentMethods: json["paymentMethods"] != null
          ? (json["paymentMethods"] as List<dynamic>)
              .map((method) => PaymentMethods.fromString(method as String))
              .whereType<PaymentMethods>()
              .toList()
          : [],
      createdAt: (json["createdAt"] as Timestamp?)?.toDate(),
      companies:
          json["companies"] != null ? List<String>.from(json["companies"]) : [],
      isActive: json["isActive"] ?? true, // Add this line
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'role': role.toString(),
      'email': email,
      'phoneNumber': phoneNumber,
      'paymentMethods': paymentMethods.map((pm) => pm.toString()).toList(),
      'createdAt': createdAt,
      'companies': companies,
      'isActive': isActive, // Add this line
    };
  }

  static String _getPhoneFromEmail(String? phoneNumber) {
    if (phoneNumber == null) {
      return "No Phone Number";
    }
    return phoneNumber.split("@").first;
  }
}
