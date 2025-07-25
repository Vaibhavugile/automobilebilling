
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  String? id; // Nullable for new items
  String description;
  int quantity;
  double unitPrice;
  double total;
  bool isProduct; // True for products, false for services

  ServiceItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.isProduct = false,
  }) : total = quantity * unitPrice; // Initialize total in constructor

  // Method to recalculate total
  void calculateTotal() {
    total = quantity * unitPrice;
  }

  // Factory constructor to create a ServiceItem from a Map (e.g., from Firestore)
  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'], // ID might not be present for items within a bill
      description: map['description'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      isProduct: map['isProduct'] ?? false,
    )..calculateTotal(); // Calculate total after creation
  }

  // Convert a ServiceItem object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'total': total, // Store calculated total
      'isProduct': isProduct,
    };
  }

  // For Autocomplete display
  @override
  String toString() => description;
}