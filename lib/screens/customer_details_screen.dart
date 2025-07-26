// lib/screens/customer_details_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motor_service_billing_app/models/customer.dart';
import 'package:motor_service_billing_app/models/bill.dart'; // Import Bill model
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/custom_message_box.dart';
import 'package:intl/intl.dart'; // For date formatting

class CustomerDetailsScreen extends StatefulWidget {
  final Customer? customer; // Null if adding a new customer

  const CustomerDetailsScreen({super.key, this.customer});

  @override
  State<CustomerDetailsScreen> createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _newVehiclePlateController;

  List<String> _vehiclePlates = [];

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _mobileController = TextEditingController(text: widget.customer?.mobileNumber ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    _newVehiclePlateController = TextEditingController();

    if (_isEditing) {
      _vehiclePlates = List.from(widget.customer!.vehicleNumberPlates);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _newVehiclePlateController.dispose();
    super.dispose();
  }

  void _saveCustomer() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final firestoreService = Provider.of<FirestoreService>(context, listen: false);

      try {
        final customer = Customer(
          id: widget.customer?.id,
          name: _nameController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          lastServiceDate: widget.customer?.lastServiceDate, // Preserve existing last service date
          vehicleNumberPlates: _vehiclePlates.map((e) => e.toUpperCase()).toList(),
        );

        await firestoreService.addOrUpdateCustomer(customer);

        if (mounted) {
          CustomMessageBox.show(context, "Success", "Customer ${customer.name} saved successfully!");
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          CustomMessageBox.show(context, "Error", "Failed to save customer: $e");
        }
      }
    }
  }

  void _addVehiclePlate() {
    final plate = _newVehiclePlateController.text.trim().toUpperCase();
    if (plate.isNotEmpty && !_vehiclePlates.contains(plate)) {
      setState(() {
        _vehiclePlates.add(plate);
      });
      _newVehiclePlateController.clear();
    } else if (plate.isNotEmpty && _vehiclePlates.contains(plate)) {
      CustomMessageBox.show(context, "Duplicate Plate", "This vehicle number plate already exists for this customer.");
    }
  }

  void _removeVehiclePlate(String plate) {
    setState(() {
      _vehiclePlates.remove(plate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return DefaultTabController(
      length: _isEditing ? 2 : 1, // Only show history tab if editing
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit Customer' : 'Add New Customer'),
          centerTitle: true,
          bottom: _isEditing
              ? const TabBar(
            tabs: [
              Tab(text: 'Details', icon: Icon(Icons.info_outline)),
              Tab(text: 'Service History', icon: Icon(Icons.history)),
            ],
          )
              : null,
        ),
        body: TabBarView(
          children: _isEditing
              ? [
            _buildDetailsTab(firestoreService),
            _buildServiceHistoryTab(firestoreService),
          ]
              : [
            _buildDetailsTab(firestoreService),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsTab(FirestoreService firestoreService) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter customer name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _mobileController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile Number',
                prefixIcon: Icon(Icons.phone),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter mobile number';
                }
                // Basic validation for 10 digits
                if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  return 'Please enter a valid 10-digit mobile number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email (Optional)',
                prefixIcon: Icon(Icons.email),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _addressController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Address (Optional)',
                prefixIcon: Icon(Icons.location_on),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Vehicle Number Plates',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _newVehiclePlateController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'New Vehicle Number Plate',
                      hintText: 'e.g., MH12AB1234',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addVehiclePlate,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: _vehiclePlates.map((plate) {
                return Chip(
                  label: Text(plate),
                  onDeleted: () => _removeVehiclePlate(plate),
                  deleteIcon: const Icon(Icons.cancel),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveCustomer,
                child: Text(_isEditing ? 'Update Customer' : 'Add Customer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceHistoryTab(FirestoreService firestoreService) {
    if (!_isEditing || widget.customer!.id == null) {
      return const Center(child: Text('Cannot load history for new customer. Save first.'));
    }

    return StreamBuilder<List<Bill>>(
      stream: firestoreService.getCustomerServiceHistoryStream(widget.customer!.id!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading history: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No service history found for this customer.'));
        }

        final bills = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: bills.length,
          itemBuilder: (context, index) {
            final bill = bills[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bill ID: ${bill.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text('Vehicle: ${bill.numberPlate}', style: const TextStyle(fontSize: 15)),
                    Text('Date: ${DateFormat('dd-MMM-yyyy hh:mm a').format(bill.timestamp)}', style: const TextStyle(fontSize: 15)),
                    Text('Grand Total: ₹${bill.grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green)),
                    ExpansionTile(
                      title: const Text('View Services/Products', style: TextStyle(fontSize: 15)),
                      children: bill.serviceItems.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.description} (x${item.quantity})',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              Text('₹${item.total.toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}