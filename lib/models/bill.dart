// lib/models/bill.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motor_service_billing_app/models/service_item.dart';

class Bill {
  final String id; // Firestore document ID - still final as it's typically set once
  final String tableId;
  String customerMobile; // Made mutable
  String numberPlate;    // Made mutable
  List<ServiceItem> serviceItems; // Made mutable
  double discountPercentage; // Made mutable
  DateTime timestamp;       // Made mutable
  double grandTotal;        // Made mutable
  String? customerId;       // Added for linking to customer

  Bill({
    String? id,
    required this.tableId,
    required this.customerMobile,
    required this.numberPlate,
    required this.serviceItems,
    this.discountPercentage = 0.0, // Default value for easier instantiation
    DateTime? timestamp, // Optional in constructor with a default
    this.grandTotal = 0.0,       // Default value for easier instantiation
    this.customerId,
  })  : id = id ?? FirebaseFirestore.instance.collection('dummy').doc().id, // Generate a dummy ID if not provided
        timestamp = timestamp ?? DateTime.now(); // Default to now if not provided


  Map<String, dynamic> toMap() {
    return {
      'tableId': tableId,
      'customerMobile': customerMobile,
      'numberPlate': numberPlate,
      'serviceItems': serviceItems.map((item) => item.toMap()).toList(),
      'discountPercentage': discountPercentage,
      'timestamp': Timestamp.fromDate(timestamp),
      'grandTotal': grandTotal,
      'customerId': customerId,
    };
  }

  factory Bill.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Bill(
      id: doc.id,
      tableId: data['tableId'] ?? 'unknown',
      customerMobile: data['customerMobile'] ?? '',
      numberPlate: data['numberPlate'] ?? '',
      serviceItems: (data['serviceItems'] as List<dynamic>?)
          ?.map((item) => ServiceItem.fromMap(item as Map<String, dynamic>))
          .toList() ??
          [],
      discountPercentage: (data['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      grandTotal: (data['grandTotal'] as num?)?.toDouble() ?? 0.0,
      customerId: data['customerId'],
    );
  }

  // Add the copyWith method
  Bill copyWith({
    String? id,
    String? tableId,
    String? customerMobile,
    String? numberPlate,
    List<ServiceItem>? serviceItems,
    double? discountPercentage,
    DateTime? timestamp,
    double? grandTotal,
    String? customerId,
  }) {
    return Bill(
      id: id ?? this.id,
      tableId: tableId ?? this.tableId,
      customerMobile: customerMobile ?? this.customerMobile,
      numberPlate: numberPlate ?? this.numberPlate,
      serviceItems: serviceItems ?? this.serviceItems,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      timestamp: timestamp ?? this.timestamp,
      grandTotal: grandTotal ?? this.grandTotal,
      customerId: customerId ?? this.customerId,
    );
  }
}