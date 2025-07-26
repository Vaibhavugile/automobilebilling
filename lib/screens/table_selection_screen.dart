// lib/screens/table_selection_screen.dart (Add button to AppBar)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:motor_service_billing_app/screens/billing_screen.dart';
import 'package:motor_service_billing_app/screens/payment_history_screen.dart';
import 'package:motor_service_billing_app/screens/service_product_management_screen.dart';
import 'package:motor_service_billing_app/screens/customer_list_screen.dart'; // NEW: Import CustomerListScreen
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/custom_message_box.dart';
import 'package:motor_service_billing_app/utils/extensions.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final int _numberOfTables = 4; // Represents number of service bays/workstations

  @override
  void initState() {
    super.initState();
    _initializeAllTables();
  }

  Future<void> _initializeAllTables() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    for (int i = 1; i <= _numberOfTables; i++) {
      await firestoreService.initializeTable('Table $i');
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Service Bay'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.people), // NEW: Customer management button
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CustomerListScreen()),
              );
            },
            tooltip: 'Manage Customers',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
              );
            },
            tooltip: 'View Payment History',
          ),
          IconButton(
            icon: const Icon(Icons.build),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServiceProductManagementScreen()),
              );
            },
            tooltip: 'Manage Services/Products',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a Service Bay to Start/Continue Billing',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: firestoreService.getTablesStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final tables = snapshot.data ?? [];

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // 2 cards per row
                      crossAxisSpacing: 20.0,
                      mainAxisSpacing: 20.0,
                      childAspectRatio: 1.0, // Make cards square
                    ),
                    itemCount: _numberOfTables,
                    itemBuilder: (context, index) {
                      final tableId = 'Table ${index + 1}';
                      final tableData = tables.firstWhereOrNull((t) => t['id'] == tableId);

                      String status = tableData?['status'] ?? 'empty';
                      Color cardColor;
                      Color textColor;

                      if (status == 'occupied') {
                        cardColor = Colors.orange.shade100;
                        textColor = Colors.orange.shade800;
                      } else if (status == 'completed') { // A bill completed but table not cleared
                        cardColor = Colors.green.shade100;
                        textColor = Colors.green.shade800;
                      } else {
                        cardColor = Colors.blue.shade50;
                        textColor = Colors.blue.shade800;
                      }

                      // Check if there are service items in the bill to determine 'occupied' status
                      final List<dynamic> serviceItems = tableData?['serviceItems'] ?? [];
                      if (serviceItems.isNotEmpty) {
                        status = 'occupied';
                        cardColor = Colors.orange.shade100;
                        textColor = Colors.orange.shade800;
                      } else {
                        status = 'empty';
                        cardColor = Colors.blue.shade50;
                        textColor = Colors.blue.shade800;
                      }


                      return Card(
                        color: cardColor,
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: textColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BillingScreen(tableId: tableId),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(15.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(
                                'Service ${index + 1}\n\n'
                                    '(${status == 'occupied' ? 'Occupied' : 'Empty'})',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                            ),
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
      ),
    );
  }
}