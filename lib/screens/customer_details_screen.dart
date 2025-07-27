// lib/screens/customer_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:intl/intl.dart'; // For date formatting

import '../models/customer.dart';
import '../models/bill.dart'; // Import Bill model
import '../services/firestore_service.dart';
import '../screens/custom_message_box.dart';

class CustomerDetailsScreen extends StatefulWidget {
  final Customer? customer; // Null for new customer
  final bool isNewCustomer;

  CustomerDetailsScreen({this.customer, this.isNewCustomer = false});

  @override
  _CustomerDetailsScreenState createState() => _CustomerDetailsScreenState();
}

class _CustomerDetailsScreenState extends State<CustomerDetailsScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  late TextEditingController _nameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _vehicleNumberPlateController; // For single plate, adjust if multiple

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _mobileNumberController =
        TextEditingController(text: widget.customer?.mobileNumber ?? '');
    _emailController = TextEditingController(text: widget.customer?.email ?? '');
    _addressController = TextEditingController(text: widget.customer?.address ?? '');
    // Assuming you want to display the first plate if editing, or empty for new
    _vehicleNumberPlateController = TextEditingController(
        text: widget.customer?.vehicleNumberPlates.isNotEmpty == true
            ? widget.customer!.vehicleNumberPlates.first
            : '');

    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _vehicleNumberPlateController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    CustomMessageBox.showLoading(context, 'Saving Customer...');

    final Customer customer = Customer(
      id: widget.customer?.id, // Keep ID if editing existing customer
      name: _nameController.text.trim(),
      mobileNumber: _mobileNumberController.text.trim(),
      email: _emailController.text.trim(),
      address: _addressController.text.trim(),
      // For vehicle plates, create a new list or update existing
      vehicleNumberPlates: _vehicleNumberPlateController.text.trim().isEmpty
          ? []
          : [_vehicleNumberPlateController.text.trim()],
    );

    try {
      if (widget.isNewCustomer) {
        await _firestoreService.addCustomer(customer);
        CustomMessageBox.showSuccess(context, 'Customer added successfully!');
      } else {
        // MODIFIED: Use updateCustomer explicitly
        await _firestoreService.updateCustomer(customer);
        CustomMessageBox.showSuccess(context, 'Customer updated successfully!');
      }
      Navigator.pop(context); // Pop loading dialog
      Navigator.pop(context); // Pop customer details screen
    } catch (e) {
      Navigator.pop(context); // Pop loading dialog
      CustomMessageBox.showError(context, 'Failed to save customer: $e');
    }
  }

  Future<void> _deleteCustomer() async {
    if (widget.customer?.id == null) {
      CustomMessageBox.showError(context, 'Cannot delete unsaved customer.');
      return;
    }

    CustomMessageBox.showConfirmation(
      context,
      'Are you sure you want to delete this customer?',
      onConfirm: () async {
        try {
          CustomMessageBox.showLoading(context, 'Deleting Customer...');
          await _firestoreService.deleteCustomer(widget.customer!.id!);
          Navigator.pop(context); // Pop loading dialog
          CustomMessageBox.showSuccess(context, 'Customer deleted successfully!');
          Navigator.pop(context); // Pop customer details screen
        } catch (e) {
          Navigator.pop(context); // Pop loading dialog
          CustomMessageBox.showError(context, 'Failed to delete customer: $e');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isNewCustomer ? 'Add New Customer' : 'Customer Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveCustomer,
            tooltip: 'Save Customer',
          ),
          if (!widget.isNewCustomer) // Only show delete for existing customers
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _deleteCustomer,
              tooltip: 'Delete Customer',
            ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'History'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Details Tab
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Name'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter name';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _mobileNumberController,
                          decoration: InputDecoration(labelText: 'Mobile Number'),
                          keyboardType: TextInputType.phone,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter mobile number';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(labelText: 'Email (Optional)'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: InputDecoration(labelText: 'Address (Optional)'),
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        TextFormField(
                          controller: _vehicleNumberPlateController,
                          decoration: InputDecoration(labelText: 'Vehicle Number Plate'),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter vehicle number plate';
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                // History Tab
                widget.customer?.mobileNumber == null
                    ? Center(child: Text('Save customer to view history.'))
                    : StreamBuilder<List<Bill>>(
                  // MODIFIED: Use getBillsForCustomer
                  stream: _firestoreService.getBillsForCustomer(widget.customer!.mobileNumber),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No service history found for this customer.'));
                    }

                    final bills = snapshot.data!;
                    return ListView.builder(
                      itemCount: bills.length,
                      itemBuilder: (context, index) {
                        final bill = bills[index];
                        return Card(
                          margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Bill ID: ${bill.id?.substring(0, 6) ?? 'N/A'}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Date: ${DateFormat('dd-MMM-yyyy hh:mm a').format(bill.timestamp)}',
                                ),
                                Text('Vehicle: ${bill.numberPlate ?? 'N/A'}'),
                                Text('Grand Total: Rs. ${bill.grandTotal.toStringAsFixed(2)}'),
                                SizedBox(height: 8),
                                Text('Items:'),
                                ...bill.serviceItems.map((item) => Text(
                                  '  - ${item.description} (${item.quantity} x Rs. ${item.unitPrice.toStringAsFixed(2)})',
                                ),
                                ).toList(),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}