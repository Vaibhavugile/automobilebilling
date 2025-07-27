// lib/models/service_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceItem {
  String? id; // Nullable for new items and for items within a bill
  String description;
  int quantity; // Changed back to int as requested
  double unitPrice;
  double total; // This will be calculated

  bool isProduct; // True for products, false for services
  int? stock; // NEW: Stock quantity for products. Nullable as services don't have stock.

  ServiceItem({
    this.id,
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.isProduct = false,
    this.stock, // NEW: Add stock to constructor
  }) : total = quantity * unitPrice; // Initialize total in constructor


  // Method to recalculate total (can be called internally or externally)
  void calculateTotal() {
    total = quantity * unitPrice;
  }

  // Factory constructor to create a ServiceItem from a Map (e.g., from Firestore)
  factory ServiceItem.fromMap(Map<String, dynamic> map) {
    return ServiceItem(
      id: map['id'], // ID might be present for items within a bill
      description: map['description'] ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 0, // Cast to int
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      isProduct: map['isProduct'] ?? false,
      stock: (map['stock'] as num?)?.toInt(), // NEW: Parse stock from map
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
      'stock': stock, // NEW: Include stock in the map
    };
  }

  // ADD THIS: copyWith method for immutability and easy updates
  ServiceItem copyWith({
    String? id,
    String? description,
    int? quantity, // Changed to int
    double? unitPrice,
    bool? isProduct,
    int? stock, // NEW: Add stock to copyWith
  }) {
    // Create a new ServiceItem instance with updated values
    final newItem = ServiceItem(
      id: id ?? this.id,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      isProduct: isProduct ?? this.isProduct,
      stock: stock ?? this.stock, // NEW: Copy stock
    );
    newItem.calculateTotal(); // Recalculate total for the new instance
    return newItem;
  }
}