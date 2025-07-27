// lib/screens/service_product_management_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import '../models/service_item.dart';
import '../services/firestore_service.dart';
import '../screens/custom_message_box.dart'; // Assuming this exists

class ServiceProductManagementScreen extends StatefulWidget {
  @override
  _ServiceProductManagementScreenState createState() =>
      _ServiceProductManagementScreenState();
}

class _ServiceProductManagementScreenState
    extends State<ServiceProductManagementScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service & Product Management'),
      ),
      body: StreamBuilder<List<ServiceItem>>(
        stream: _firestoreService.getServicesAndProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No services or products added yet.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(item.description),
                  subtitle: Text(
                      'Unit Price: Rs. ${item.unitPrice.toStringAsFixed(2)} ' +
                          (item.isProduct
                              ? '| Product | Stock: ${item.stock ?? 'N/A'}' // MODIFIED: Display stock
                              : '| Service')),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () => _showServiceProductDialog(item: item),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _confirmDelete(item.id!),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showServiceProductDialog(),
        child: Icon(Icons.add),
        tooltip: 'Add New Service/Product',
      ),
    );
  }

  void _showServiceProductDialog({ServiceItem? item}) {
    final TextEditingController _descriptionController =
    TextEditingController(text: item?.description ?? '');
    final TextEditingController _unitPriceController =
    TextEditingController(text: item?.unitPrice.toStringAsFixed(2) ?? '0.00');
    final TextEditingController _stockController = // NEW: Stock Controller
    TextEditingController(text: item?.stock?.toString() ?? '0');
    bool _isProduct = item?.isProduct ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder( // Use StatefulBuilder to update dialog state
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text(item == null ? 'Add Service/Product' : 'Edit Service/Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      decoration: InputDecoration(labelText: 'Description'),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _unitPriceController,
                      decoration: InputDecoration(labelText: 'Unit Price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text('Is Product?'),
                        Checkbox(
                          value: _isProduct,
                          onChanged: (bool? value) {
                            setStateSB(() {
                              _isProduct = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                    // NEW: Stock field, only visible if 'Is Product' is checked
                    if (_isProduct) ...[
                      SizedBox(height: 10),
                      TextField(
                        controller: _stockController,
                        decoration: InputDecoration(labelText: 'Stock Quantity'),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final String description = _descriptionController.text.trim();
                    final double unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
                    final int stock = _isProduct ? (int.tryParse(_stockController.text) ?? 0) : 0; // NEW: Get stock value

                    if (description.isEmpty || unitPrice <= 0) {
                      CustomMessageBox.showError(context, 'Please fill all fields correctly.');
                      return;
                    }
                    if (_isProduct && stock < 0) { // Basic validation for stock
                      CustomMessageBox.showError(context, 'Stock quantity cannot be negative.');
                      return;
                    }

                    CustomMessageBox.showLoading(context, 'Saving...');

                    final ServiceItem newItem = ServiceItem(
                      id: item?.id, // Keep ID if editing
                      description: description,
                      quantity: 1, // Default quantity for display in list
                      unitPrice: unitPrice,
                      isProduct: _isProduct,
                      stock: _isProduct ? stock : null, // NEW: Pass stock based on isProduct
                    );

                    try {
                      if (item == null) {
                        // Add new item
                        await _firestoreService.addService(newItem);
                        CustomMessageBox.showSuccess(context, 'Service/Product added successfully!');
                      } else {
                        // Update existing item
                        await _firestoreService.updateServiceProduct(newItem);
                        CustomMessageBox.showSuccess(context, 'Service/Product updated successfully!');
                      }
                      Navigator.pop(context); // Pop loading dialog
                      Navigator.pop(context); // Pop dialog itself
                    } catch (e) {
                      Navigator.pop(context); // Pop loading dialog
                      CustomMessageBox.showError(context, 'Failed to save: $e');
                    }
                  },
                  child: Text(item == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(String itemId) {
    CustomMessageBox.showConfirmation(
      context,
      'Are you sure you want to delete this item?',
      onConfirm: () async {
        try {
          CustomMessageBox.showLoading(context, 'Deleting...');
          await _firestoreService.deleteServiceProduct(itemId);
          Navigator.pop(context); // Pop loading dialog
          CustomMessageBox.showSuccess(context, 'Item deleted successfully!');
        } catch (e) {
          Navigator.pop(context); // Pop loading dialog
          CustomMessageBox.showError(context, 'Failed to delete item: $e');
        }
      },
    );
  }
}