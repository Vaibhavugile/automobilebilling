// lib/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motor_service_billing_app/models/customer.dart';
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/customer_details_screen.dart'; // Will create this next
import 'package:motor_service_billing_app/screens/custom_message_box.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const CustomerDetailsScreen(), // For adding new customer
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search Customers',
                hintText: 'By name, mobile, or vehicle number',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Customer>>(
              stream: firestoreService.getCustomersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No customers found. Add a new customer!'));
                }

                final customers = snapshot.data!.where((customer) {
                  final lowerSearchText = _searchText.toLowerCase();
                  return customer.name.toLowerCase().contains(lowerSearchText) ||
                      customer.mobileNumber.contains(lowerSearchText) ||
                      customer.vehicleNumberPlates.any((plate) => plate.toLowerCase().contains(lowerSearchText));
                }).toList();

                if (customers.isEmpty && _searchText.isNotEmpty) {
                  return const Center(child: Text('No matching customers found.'));
                }

                return ListView.builder(
                  itemCount: customers.length,
                  itemBuilder: (context, index) {
                    final customer = customers[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.blueAccent),
                        title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Mobile: ${customer.mobileNumber}'),
                            if (customer.vehicleNumberPlates.isNotEmpty)
                              Text('Vehicles: ${customer.vehicleNumberPlates.join(', ')}'),
                            if (customer.lastServiceDate != null)
                              Text('Last Service: ${_formatDate(customer.lastServiceDate!)}'),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () async {
                            final confirm = await CustomMessageBox.showConfirmation(
                              context,
                              "Delete Customer",
                              "Are you sure you want to delete ${customer.name}? This will NOT delete their past service records.",
                            );
                            if (confirm == true) {
                              try {
                                await firestoreService.deleteCustomer(customer.id!);
                                if (mounted) {
                                  CustomMessageBox.show(context, "Success", "${customer.name} deleted.");
                                }
                              } catch (e) {
                                if (mounted) {
                                  CustomMessageBox.show(context, "Error", "Failed to delete customer: $e");
                                }
                              }
                            }
                          },
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CustomerDetailsScreen(customer: customer),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}