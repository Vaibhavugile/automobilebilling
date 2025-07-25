// lib/models/bill.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motor_service_billing_app/models/service_item.dart';

class Bill {
  String? id; // Nullable for new bills before saving
  final String tableId;
  final String customerMobile;
  final String numberPlate;
  final List<ServiceItem> serviceItems;
  final double discountPercentage;
  final DateTime timestamp;
  final double grandTotal; // Add grandTotal field to the Bill model

  Bill({
    this.id,
    required this.tableId,
    required this.customerMobile,
    required this.numberPlate,
    required this.serviceItems,
    required this.discountPercentage,
    required this.timestamp,
    required this.grandTotal, // Make it required
  });

  // Factory constructor to create a Bill from a Firestore DocumentSnapshot
  factory Bill.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      tableId: data['tableId'] ?? '',
      customerMobile: data['customerMobile'] ?? '',
      numberPlate: data['numberPlate'] ?? '',
      serviceItems: (data['serviceItems'] as List<dynamic>?) // IMPORTANT: Add <dynamic>?
          ?.map((item) => ServiceItem.fromMap(item as Map<String, dynamic>)) // IMPORTANT: Cast item
          .toList() ?? [], // IMPORTANT: Add fallback to empty list
      discountPercentage: (data['discountPercentage'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      grandTotal: (data['grandTotal'] ?? 0.0).toDouble(), // Retrieve grandTotal
    );
  }

  // Convert a Bill object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'customerMobile': customerMobile,
      'numberPlate': numberPlate,
      'serviceItems': serviceItems.map((item) => item.toMap()).toList(),
      'discountPercentage': discountPercentage,
      'timestamp': Timestamp.fromDate(timestamp),
      'grandTotal': grandTotal, // Store grandTotal
    };
  }
}