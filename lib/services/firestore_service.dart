// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:motor_service_billing_app/models/bill.dart';
import 'package:motor_service_billing_app/models/service_item.dart';
import 'package:motor_service_billing_app/models/customer.dart'; // Import the new Customer model

class FirestoreService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Authentication ---
  Future<void> signInWithEmailPassword(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided for that user.');
      } else {
        throw Exception('Login failed: ${e.message}');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred during login: $e');
    }
  }

  // --- User and Initialization ---
  Future<String?> getCurrentUserId() async {
    return _auth.currentUser?.uid;
  }

  Future<void> initializeTable(String tableId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    final tableRef = _db.collection('users').doc(userId).collection('tables').doc(tableId);
    final doc = await tableRef.get();

    if (!doc.exists) {
      await tableRef.set({
        'id': tableId, // Store tableId within the document
        'customerMobile': '',
        'numberPlate': '',
        'serviceItems': [],
        'discountPercentage': 0.0,
        'timestamp': Timestamp.now(),
        'grandTotal': 0.0,
        'status': 'empty', // Add a status field for tables
      });
    }
  }

  Stream<List<Map<String, dynamic>>> getTablesStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]); // Return an empty stream if no user
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('tables')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  // --- Bill Operations ---
  Future<Bill?> getBill(String tableId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('tables')
        .doc(tableId)
        .get();

    if (doc.exists) {
      return Bill.fromFirestore(doc);
    }
    return null;
  }

  Future<void> saveBill(Bill bill) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db
        .collection('users')
        .doc(userId)
        .collection('tables')
        .doc(bill.tableId)
        .set(bill.toMap());
  }

  Future<void> clearBill(String tableId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    // Reset the table data to its initial empty state
    await _db.collection('users').doc(userId).collection('tables').doc(tableId).set({
      'id': tableId,
      'customerMobile': '',
      'numberPlate': '',
      'serviceItems': [],
      'discountPercentage': 0.0,
      'timestamp': Timestamp.now(),
      'grandTotal': 0.0,
      'status': 'empty',
    });
  }

  // --- Customer Management ---
  Future<void> addOrUpdateCustomer(Customer customer) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    final customerRef = _db.collection('users').doc(userId).collection('customers');

    if (customer.id != null) {
      // Update existing customer
      await customerRef.doc(customer.id).update(customer.toMap());
    } else {
      // Add new customer
      await customerRef.add(customer.toMap());
    }
  }

  // Get a stream of all customers
  Stream<List<Customer>> getCustomersStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _db.collection('users').doc(userId).collection('customers')
        .orderBy('name') // Order by name for easy Browse
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Customer.fromFirestore(doc)).toList();
    });
  }

  // Get a single customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final doc = await _db.collection('users').doc(userId).collection('customers').doc(customerId).get();
    if (doc.exists) {
      return Customer.fromFirestore(doc);
    }
    return null;
  }

  // Get a customer by mobile number (useful for searching during billing)
  Future<Customer?> getCustomerByMobileNumber(String mobileNumber) async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final querySnapshot = await _db.collection('users').doc(userId).collection('customers')
        .where('mobileNumber', isEqualTo: mobileNumber)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Customer.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // Get customer by vehicle number plate
  Future<Customer?> getCustomerByVehicleNumberPlate(String numberPlate) async {
    final userId = await getCurrentUserId();
    if (userId == null) return null;

    final querySnapshot = await _db.collection('users').doc(userId).collection('customers')
        .where('vehicleNumberPlates', arrayContains: numberPlate.toUpperCase()) // Store plates as uppercase for consistency
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Customer.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // Delete a customer (be careful with this, as it orphans their payment history)
  Future<void> deleteCustomer(String customerId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('customers').doc(customerId).delete();
  }

  // --- Complete Bill (with Customer Linkage) ---
  Future<void> completeBill(Bill bill) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    // 1. Store in payment history
    final historyRef = await _db
        .collection('users')
        .doc(userId)
        .collection('payment_history')
        .add(bill.toMap());

    // 2. Link bill to customer and update customer's last service date
    if (bill.customerMobile.isNotEmpty) {
      Customer? customer = await getCustomerByMobileNumber(bill.customerMobile);
      if (customer != null) {
        // Update existing customer
        customer.lastServiceDate = DateTime.now();
        if (!customer.vehicleNumberPlates.contains(bill.numberPlate.toUpperCase())) {
          customer.vehicleNumberPlates.add(bill.numberPlate.toUpperCase());
        }
        await addOrUpdateCustomer(customer);
        await historyRef.update({'customerId': customer.id}); // Store actual customer ID
      } else {
        // Create new customer if not found
        final newCustomer = Customer(
          name: 'Customer ${bill.customerMobile}', // You might want to prompt for a name here
          mobileNumber: bill.customerMobile,
          lastServiceDate: DateTime.now(),
          vehicleNumberPlates: [bill.numberPlate.toUpperCase()],
        );
        final newCustomerDocRef = await _db.collection('users').doc(userId).collection('customers').add(newCustomer.toMap());
        await historyRef.update({'customerId': newCustomerDocRef.id});
      }
    }

    // 3. Clear the table data
    await clearBill(bill.tableId);
  }

  Stream<List<Bill>> getPaymentHistoryStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('payment_history')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bill.fromFirestore(doc)).toList();
    });
  }

  // Add a method to get a customer's specific service history
  Stream<List<Bill>> getCustomerServiceHistoryStream(String customerId) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('payment_history')
        .where('customerId', isEqualTo: customerId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Bill.fromFirestore(doc)).toList();
    });
  }

  // --- Service & Product Management ---
  Stream<List<ServiceItem>> getServicesAndProductsStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }
    return _db
        .collection('users')
        .doc(userId)
        .collection('services_products')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ServiceItem.fromMap(doc.data()..['id'] = doc.id)).toList();
    });
  }

  Future<void> addService(ServiceItem item) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('services_products').add(item.toMap());
  }

  Future<void> addProduct(ServiceItem item) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('services_products').add(item.toMap());
  }

  Future<void> updateServiceProduct(String itemId, String description, double unitPrice, bool isProduct, bool typeChanged) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('services_products').doc(itemId).update({
      'description': description,
      'unitPrice': unitPrice,
      'isProduct': isProduct,
    });
  }

  Future<void> deleteServiceProduct(String itemId) async {
    final userId = await getCurrentUserId();
    if (userId == null) return;

    await _db.collection('users').doc(userId).collection('services_products').doc(itemId).delete();
  }
}