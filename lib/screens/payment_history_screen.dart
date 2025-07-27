// lib/screens/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/bill.dart';
import '../services/firestore_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  @override
  _PaymentHistoryScreenState createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  TextEditingController _searchController = TextEditingController();
  List<Bill> _allBills = [];
  List<Bill> _filteredBills = [];

  @override
  void initState() {
    super.initState();
    // MODIFIED: Use getBillsStream
    _firestoreService.getBillsStream().listen((bills) { // This is line 59 or very close to it
      setState(() {
        _allBills = bills;
        _filterBills(); // Re-filter whenever bill list changes
      });
    });
    _searchController.addListener(_filterBills);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterBills);
    _searchController.dispose();
    super.dispose();
  }

  void _filterBills() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredBills = _allBills.where((bill) {
        return bill.customerMobile.toLowerCase().contains(query) ||
            (bill.numberPlate?.toLowerCase().contains(query) ?? false) ||
            bill.serviceItems.any((item) => item.description.toLowerCase().contains(query));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment History'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by mobile, vehicle plate, or item',
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
      body: _filteredBills.isEmpty && _searchController.text.isEmpty
          ? Center(child: Text('No bills recorded yet.'))
          : _filteredBills.isEmpty && _searchController.text.isNotEmpty
          ? Center(child: Text('No matching bills found.'))
          : ListView.builder(
        itemCount: _filteredBills.length,
        itemBuilder: (context, index) {
          final bill = _filteredBills[index];
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
                  Text('Customer Mobile: ${bill.customerMobile}'),
                  Text('Vehicle: ${bill.numberPlate ?? 'N/A'}'),
                  Text('Grand Total: Rs. ${bill.grandTotal.toStringAsFixed(2)}'),
                  SizedBox(height: 8),
                  Text('Items:'),
                  ...bill.serviceItems.map((item) => Text(
                    '  - ${item.description} (${item.quantity} x Rs. ${item.unitPrice.toStringAsFixed(2)})',
                  )).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}