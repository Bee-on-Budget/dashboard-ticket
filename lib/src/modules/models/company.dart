import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String? email;
  final String? phone;
  final List<String> paymentMethods;  // Change from List<PaymentMethods>
  final DateTime? createdAt;
  final bool isActive;

  const Company({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    required this.paymentMethods,
    this.createdAt,
    this.isActive = true,
  });

  factory Company.fromJson(Map<String, dynamic> json, String id) {
    return Company(
      id: id,
      name: json['name'] ?? 'No Name',
      email: json['email'],
      phone: json['phone'],
      paymentMethods: json['paymentMethods'] != null
          ? List<String>.from(json['paymentMethods'])
          : [],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate(),
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      'paymentMethods': paymentMethods,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}