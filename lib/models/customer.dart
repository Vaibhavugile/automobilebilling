// lib/models/customer.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Customer {
  String? id; // Document ID from Firestore
  String name;
  String mobileNumber;
  String? email;
  String? address;
  DateTime? lastServiceDate; // To track for reminders
  List<String> vehicleNumberPlates; // A customer can have multiple vehicles

  Customer({
    this.id,
    required this.name,
    required this.mobileNumber,
    this.email,
    this.address,
    this.lastServiceDate,
    this.vehicleNumberPlates = const [],
  });

  // Convert a Customer object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'mobileNumber': mobileNumber,
      'email': email,
      'address': address,
      'lastServiceDate': lastServiceDate != null ? Timestamp.fromDate(lastServiceDate!) : null,
      'vehicleNumberPlates': vehicleNumberPlates,
    };
  }

  // Create a Customer object from a Firestore document snapshot
  factory Customer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Customer(
      id: doc.id,
      name: data['name'] ?? 'N/A',
      mobileNumber: data['mobileNumber'] ?? 'N/A',
      email: data['email'],
      address: data['address'],
      lastServiceDate: (data['lastServiceDate'] as Timestamp?)?.toDate(),
      vehicleNumberPlates: List<String>.from(data['vehicleNumberPlates'] ?? []),
    );
  }

  // Create a Customer object from a Map (e.g., for initial data)
  factory Customer.fromMap(Map<String, dynamic> map, {String? id}) {
    return Customer(
      id: id,
      name: map['name'] ?? 'N/A',
      mobileNumber: map['mobileNumber'] ?? 'N/A',
      email: map['email'],
      address: map['address'],
      lastServiceDate: (map['lastServiceDate'] as Timestamp?)?.toDate(),
      vehicleNumberPlates: List<String>.from(map['vehicleNumberPlates'] ?? []),
    );
  }
}