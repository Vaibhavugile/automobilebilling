// lib/screens/table_selection_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For DocumentSnapshot
import '../services/firestore_service.dart';
import 'billing_screen.dart';
import 'payment_history_screen.dart';
import 'service_product_management_screen.dart';
import 'customer_list_screen.dart';
import '../screens/custom_message_box.dart';

class TableSelectionScreen extends StatefulWidget {
  @override
  _TableSelectionScreenState createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final List<String> _tableIds = List.generate(10, (index) => 'Table ${index + 1}'); // Example tables

  @override
  void initState() {
    super.initState();
    // Initialize tables in Firestore if they don't exist
    _tableIds.forEach((tableId) {
      _firestoreService.initializeTable(tableId);
    });
  }

  void _navigateToBillingScreen(String tableId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillingScreen(tableId: tableId),
      ),
    );
  }

  void _navigateToPaymentHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentHistoryScreen(),
      ),
    );
  }

  void _navigateToServiceProductManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceProductManagementScreen(),
      ),
    );
  }

  void _navigateToCustomerList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CustomerListScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    CustomMessageBox.showConfirmation(context, 'Are you sure you want to log out?',
        onConfirm: () async {
          try {
            CustomMessageBox.showLoading(context, 'Logging out...');
            await _firestoreService.signOut();
            Navigator.pop(context); // Pop loading dialog
            // Navigate back to login screen, remove all previous routes
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
          } catch (e) {
            Navigator.pop(context); // Pop loading dialog
            CustomMessageBox.showError(context, 'Logout failed: $e');
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Table Selection'),
        actions: [
          IconButton(
            icon: Icon(Icons.people),
            onPressed: _navigateToCustomerList,
            tooltip: 'Customer List',
          ),
          IconButton(
            icon: Icon(Icons.history),
            onPressed: _navigateToPaymentHistory,
            tooltip: 'Payment History',
          ),
          IconButton(
            icon: Icon(Icons.manage_accounts),
            onPressed: _navigateToServiceProductManagement,
            tooltip: 'Service/Product Management',
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _firestoreService.getTablesStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No tables found.'));
          }

          final tableStatuses = { for (var item in snapshot.data!) item['id'] : item['status'] };

          return GridView.builder( // Line 71 is likely here, or within its direct children.
            padding: const EdgeInsets.all(16.0),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
            ),
            itemCount: _tableIds.length,
            itemBuilder: (context, index) {
              final tableId = _tableIds[index];
              final status = tableStatuses[tableId] ?? 'empty'; // Default to empty if no status found

              Color cardColor;
              String statusText;
              switch (status) {
                case 'occupied':
                  cardColor = Colors.orange.shade100;
                  statusText = 'Occupied';
                  break;
                case 'billing':
                  cardColor = Colors.red.shade100;
                  statusText = 'Billing In Progress';
                  break;
                case 'empty':
                default:
                  cardColor = Colors.green.shade100;
                  statusText = 'Empty';
                  break;
              }

              return GestureDetector(
                onTap: () => _navigateToBillingScreen(tableId),
                child: Card(
                  color: cardColor,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          tableId,
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          statusText,
                          style: TextStyle(fontSize: 16, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}