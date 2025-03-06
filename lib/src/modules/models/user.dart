import 'package:cloud_firestore/cloud_firestore.dart';

import '../../config/enums/payment_methods.dart';
import '../../config/enums/user_role.dart';

class User {
  final String userId;
  final String username;
  final UserRole role;
  final String email;
  final String phoneNumber;
  final List<PaymentMethods> paymentMethods;
  final DateTime? createdAt;
  final List<String> companies;

  const User({
    required this.userId,
    required this.username,
    required this.role,
    required this.email,
    required this.phoneNumber,
    required this.paymentMethods,
    required this.createdAt,
    required this.companies,
  });

  factory User.fromJson(Map<String, dynamic> json, String userId) {
    return User(
      userId: userId,
      username: json["username"] ?? "No Username",
      role: UserRole.fromString(json["role"] ?? "unknown"),
      email: json["email"] ?? "No Email",
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
    };
  }

  static String _getPhoneFromEmail(String? phoneNumber) {
    if (phoneNumber == null) {
      return "No Phone Number";
    }
    return phoneNumber.split("@").first;
  }
}
