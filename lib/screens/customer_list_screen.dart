// lib/screens/customer_list_screen.dart
import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../services/firestore_service.dart';
import 'customer_details_screen.dart';

class CustomerListScreen extends StatefulWidget {
  @override
  _CustomerListScreenState createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  TextEditingController _searchController = TextEditingController();
  List<Customer> _allCustomers = [];
  List<Customer> _filteredCustomers = [];

  @override
  void initState() {
    super.initState();
    _firestoreService.getCustomersStream().listen((customers) {
      setState(() {
        _allCustomers = customers;
        _filterCustomers(); // Re-filter whenever customer list changes
      });
    });
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  void _filterCustomers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredCustomers = _allCustomers.where((customer) {
        return customer.name.toLowerCase().contains(query) ||
            customer.mobileNumber.toLowerCase().contains(query) ||
            customer.vehicleNumberPlates.any((plate) => plate.toLowerCase().contains(query));
      }).toList();
    });
  }

  void _navigateToCustomerDetails({Customer? customer, bool isNew = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        // Line 50 might be around here. Ensure no 'const' if CustomerDetailsScreen
        // constructor is not const or its arguments are dynamic.
        builder: (context) => CustomerDetailsScreen(
          customer: customer,
          isNewCustomer: isNew,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Customer List'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, mobile, or vehicle plate',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: _filteredCustomers.isEmpty && _searchController.text.isEmpty
          ? Center(child: Text('No customers added yet.'))
          : _filteredCustomers.isEmpty && _searchController.text.isNotEmpty
          ? Center(child: Text('No matching customers found.'))
          : ListView.builder(
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return Card(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: ListTile(
              title: Text(customer.name),
              subtitle: Text(
                  'Mobile: ${customer.mobileNumber}\n'
                      'Vehicle: ${customer.vehicleNumberPlates.join(', ')}'
              ),
              onTap: () => _navigateToCustomerDetails(customer: customer),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCustomerDetails(isNew: true),
        child: Icon(Icons.add),
        tooltip: 'Add New Customer',
      ),
    );
  }
}