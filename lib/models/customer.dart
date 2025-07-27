// lib/models/customer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  String? id; // Nullable for new customers before they are saved
  String name;
  String mobileNumber;
  List<String> vehicleNumberPlates;
  String address;
  String email;

  Customer({
    this.id,
    required this.name,
    required this.mobileNumber,
    this.vehicleNumberPlates = const [],
    this.address = '',
    this.email = '',
  });

  // Factory constructor to create a Customer from a Firestore DocumentSnapshot
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? 'Unnamed Customer',
      mobileNumber: data['mobileNumber'] ?? '',
      vehicleNumberPlates: List<String>.from(data['vehicleNumberPlates'] ?? []),
      address: data['address'] ?? '',
      email: data['email'] ?? '',
    );
  }

  // Method to convert a Customer object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'vehicleNumberPlates': vehicleNumberPlates,
      'address': address,
      'email': email,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
  }

  // copyWith method for immutability and updating specific fields
  Customer copyWith({
    String? id,
    String? name,
    String? mobileNumber,
    List<String>? vehicleNumberPlates,
    String? address,
    String? email,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      vehicleNumberPlates: vehicleNumberPlates ?? this.vehicleNumberPlates,
      address: address ?? this.address,
      email: email ?? this.email,
    );
  }
}