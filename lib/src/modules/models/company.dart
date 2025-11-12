import 'package:cloud_firestore/cloud_firestore.dart';

class Company {
  final String id;
  final String name;
  final String? description;
  final String? email;
  final String? phone;
  final String? website;
  final String? address;
  final List<String> paymentMethods; // Change from List<PaymentMethods>
  final DateTime? createdAt;
  final bool isActive;

  const Company({
    required this.id,
    required this.name,
    this.description,
    this.email,
    this.phone,
    this.website,
    this.address,
    required this.paymentMethods,
    this.createdAt,
    this.isActive = true,
  });

  factory Company.fromJson(Map<String, dynamic> json, String id) {
    return Company(
      id: id,
      name: json['name'] ?? 'No Name',
      description: json['description'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      address: json['address'],
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
      if (description != null) 'description': description,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (website != null) 'website': website,
      if (address != null) 'address': address,
      'paymentMethods': paymentMethods,
      'createdAt': createdAt,
      'isActive': isActive,
    };
  }
}
