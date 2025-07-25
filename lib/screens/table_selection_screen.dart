// lib/screens/table_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// import 'dart:convert'; // Not directly used in this simplified version, can be removed if not used elsewhere
// import 'package:motor_service_billing_app/models/service_item.dart'; // Not directly used for display in simplified cards
import 'package:motor_service_billing_app/screens/billing_screen.dart';
import 'package:motor_service_billing_app/screens/payment_history_screen.dart';
import 'package:motor_service_billing_app/screens/service_product_management_screen.dart';
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/custom_message_box.dart';
import 'package:motor_service_billing_app/utils/extensions.dart'; // Still used for firstWhereOrNull, keep this

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
    _initializeTables();
  }

  Future<void> _initializeTables() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    for (int i = 1; i <= _numberOfTables; i++) {
      final tableId = 'table_$i';
      await firestoreService.initializeTable(tableId);
    }
  }

  void _copyUserId(String userId) {
    Clipboard.setData(ClipboardData(text: userId));
    CustomMessageBox.show(context, "Copied!", "User ID copied to clipboard.");
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Service '), // Simplified title
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Payment History',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PaymentHistoryScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.build),
            tooltip: 'Manage Services & Products',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ServiceProductManagementScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FutureBuilder<String?>(
              future: firestoreService.getCurrentUserId(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final userId = snapshot.data;
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Your User ID: ${userId ?? 'N/A'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (userId != null)
                          IconButton(
                            icon: const Icon(Icons.copy, size: 20),
                            onPressed: () => _copyUserId(userId),
                            tooltip: 'Copy User ID',
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
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
                      crossAxisCount: 2,
                      crossAxisSpacing: 16.0,
                      mainAxisSpacing: 16.0,
                      childAspectRatio: 1.0, // Set to square, given minimal content
                    ),
                    itemCount: _numberOfTables,
                    itemBuilder: (context, index) {
                      final tableId = 'table_${index + 1}';
                      final tableData = tables.firstWhereOrNull((t) => t['id'] == tableId) ?? {};

                      // Determine if the bay is "occupied" based on any existing data
                      // (customerMobile, numberPlate, or serviceItems not being empty)
                      // No need to parse full ServiceItem objects here if not displaying them.
                      final isOccupied = (tableData['customerMobile'] as String? ?? '').isNotEmpty ||
                          (tableData['numberPlate'] as String? ?? '').isNotEmpty ||
                          (tableData['serviceItems'] as List<dynamic>? ?? []).isNotEmpty;

                      Color cardBorderColor = isOccupied ? Theme.of(context).primaryColor.withOpacity(0.5) : Colors.green.shade300;
                      Color textColor = isOccupied ? Theme.of(context).primaryColor : Colors.green.shade700;

                      return Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                          side: BorderSide(
                            color: cardBorderColor,
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
                            child: Center( // Center the content within the card
                              child: Text(
                                'Service ${index + 1}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 24, // Larger font for prominence
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