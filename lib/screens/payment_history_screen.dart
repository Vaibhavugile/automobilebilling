// lib/screens/payment_history_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motor_service_billing_app/models/bill.dart';
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:intl/intl.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
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
        title: const Text('Payment History'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by Customer Mobile or Number Plate',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Bill>>(
              stream: firestoreService.getPaymentHistoryStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No payment history found.'));
                }

                final bills = snapshot.data!.where((bill) {
                  final matchesMobile = bill.customerMobile.toLowerCase().contains(_searchText);
                  final matchesNumberPlate = bill.numberPlate.toLowerCase().contains(_searchText);
                  return matchesMobile || matchesNumberPlate;
                }).toList();

                if (bills.isEmpty && _searchText.isNotEmpty) {
                  return const Center(child: Text('No matching bills found.'));
                } else if (bills.isEmpty) {
                  return const Center(child: Text('No payment history found.'));
                }

                return ListView.builder(
                  itemCount: bills.length,
                  itemBuilder: (context, index) {
                    final bill = bills[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bill ID: ${bill.id?.substring(0, 8) ?? 'N/A'}', // Display a short ID
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  DateFormat('dd MMM yyyy, hh:mm a').format(bill.timestamp),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            const Divider(),
                            Text('Customer Mobile: ${bill.customerMobile}', style: const TextStyle(fontSize: 15)),
                            Text('Number Plate: ${bill.numberPlate}', style: const TextStyle(fontSize: 15)),
                            Text('Discount: ${bill.discountPercentage.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 15)),
                            Text(
                              'Grand Total: ₹${bill.grandTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                            const SizedBox(height: 10),
                            // Service Details
                            ExpansionTile(
                              title: const Text('View Service Details'),
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
            ),
          ),
        ],
      ),
    );
  }
}