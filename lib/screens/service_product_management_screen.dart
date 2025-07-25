// lib/screens/service_product_management_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motor_service_billing_app/models/service_item.dart';
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/custom_message_box.dart';

class ServiceProductManagementScreen extends StatefulWidget {
  // Add the initialDescription parameter here
  final String? initialDescription;

  const ServiceProductManagementScreen({super.key, this.initialDescription}); // Update the constructor

  @override
  State<ServiceProductManagementScreen> createState() => _ServiceProductManagementScreenState();
}

class _ServiceProductManagementScreenState extends State<ServiceProductManagementScreen> {
  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Services & Products'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ServiceItem>>(
        stream: firestoreService.getServicesAndProductsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No services or products added yet.\nTap + to add one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final items = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  title: Text(
                    item.description,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '₹${item.unitPrice.toStringAsFixed(2)} - ${item.isProduct ? 'Product' : 'Service'}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditItemDialog(context, item: item),
                        tooltip: 'Edit Item',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final bool? confirm = await CustomMessageBox.showConfirmation(
                            context,
                            "Confirm Delete",
                            "Are you sure you want to delete '${item.description}'?",
                          );
                          if (confirm == true) {
                            try {
                              if (item.id != null) { // Ensure ID is not null before deleting
                                // Pass isProduct to deleteServiceProduct
                                await firestoreService.deleteServiceProduct(item.id!);
                                CustomMessageBox.show(context, "Success", "'${item.description}' deleted successfully.");
                              } else {
                                CustomMessageBox.show(context, "Error", "Item ID is missing. Cannot delete.");
                              }
                            } catch (e) {
                              CustomMessageBox.show(context, "Error", "Failed to delete item: $e");
                            }
                          }
                        },
                        tooltip: 'Delete Item',
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
        onPressed: () => _showAddEditItemDialog(context), // Call without initial description for FAB
        backgroundColor: Theme.of(context).primaryColor,
        tooltip: 'Add New Service/Product',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showAddEditItemDialog(BuildContext context, {ServiceItem? item}) {
    final isEditing = item != null;
    // Use widget.initialDescription here if it's not editing
    final _descriptionController = TextEditingController(text: item?.description ?? widget.initialDescription ?? '');
    final _unitPriceController = TextEditingController(text: item?.unitPrice.toStringAsFixed(2));
    bool _isProduct = item?.isProduct ?? false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Item' : 'Add New Item'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(labelText: 'Description'),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    TextField(
                      controller: _unitPriceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Unit Price'),
                    ),
                    Row(
                      children: [
                        const Text('Is Product?'),
                        Checkbox(
                          value: _isProduct,
                          onChanged: (bool? newValue) {
                            setState(() {
                              _isProduct = newValue ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final firestoreService = Provider.of<FirestoreService>(dialogContext, listen: false);
                final description = _descriptionController.text.trim();
                final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

                if (description.isEmpty || unitPrice <= 0) {
                  CustomMessageBox.show(dialogContext, "Error", "Please enter valid description and price.");
                  return;
                }

                try {
                  if (isEditing) {
                    // Update existing item
                    if (item?.id != null) {
                      await firestoreService.updateServiceProduct(
                        item!.id!,
                        description,
                        unitPrice,
                        _isProduct,
                        item.isProduct != _isProduct, // Pass if type changed
                      );
                      CustomMessageBox.show(dialogContext, "Success", "'$description' updated successfully.");
                    } else {
                      CustomMessageBox.show(dialogContext, "Error", "Item ID is missing. Cannot update.");
                    }
                  } else {
                    // Add new item
                    final newItem = ServiceItem(
                      description: description,
                      unitPrice: unitPrice,
                      isProduct: _isProduct,
                      quantity: 1, // Default quantity for a new master item
                    );
                    await firestoreService.addService(newItem);
                    CustomMessageBox.show(dialogContext, "Success", "'$description' added successfully.");
                  }
                  Navigator.of(dialogContext).pop(); // Close dialog
                } catch (e) {
                  CustomMessageBox.show(dialogContext, "Error", "Failed to save item: $e");
                }
              },
              child: Text(isEditing ? 'Update' : 'Add'),
            ),
          ],
        );
      },
    );
  }
}