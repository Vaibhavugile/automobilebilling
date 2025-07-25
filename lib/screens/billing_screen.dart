// lib/screens/billing_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For TextInputFormatter
import 'package:provider/provider.dart';
import 'dart:convert';
import 'dart:async'; // For Timer
import 'dart:typed_data'; // For Uint8List

import 'package:motor_service_billing_app/models/bill.dart';
import 'package:motor_service_billing_app/models/service_item.dart';
import 'package:motor_service_billing_app/services/firestore_service.dart';
import 'package:motor_service_billing_app/screens/custom_message_box.dart';
// Removed: import 'package:motor_service_billing_app/screens/service_product_management_screen.dart'; // No longer navigated from here
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:motor_service_billing_app/utils/extensions.dart'; // Import the new extensions file

class BillingScreen extends StatefulWidget {
  final String tableId;
  const BillingScreen({super.key, required this.tableId});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _numberPlateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final List<ServiceItem> _serviceItems = [];
  double _discountPercentage = 0.0;
  List<ServiceItem> _allAvailableServices = []; // For autocomplete
  Map<String, ServiceItem> _serviceProductMap = {}; // Map for quick lookup

  // ScrollController for the entire SingleChildScrollView
  final ScrollController _overallScrollController = ScrollController();

  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;

  Timer? _saveTimer;
  final Duration _debounceDuration = const Duration(milliseconds: 700); // Debounce duration

  @override
  void initState() {
    super.initState();
    _loadBillData();
    _discountController.addListener(_updateDiscount); // This already calls setState, which affects _discountPercentage.
    // _debounceSaveBill is added directly to the controller below.
    _loadAvailableServices();

    // Add listeners to controllers to trigger debounced save
    _mobileNumberController.addListener(_debounceSaveBill);
    _numberPlateController.addListener(_debounceSaveBill);
    _discountController.addListener(_debounceSaveBill);
  }

  @override
  void dispose() {
    // Remove listeners to prevent memory leaks
    _mobileNumberController.removeListener(_debounceSaveBill);
    _numberPlateController.removeListener(_debounceSaveBill);
    _discountController.removeListener(_debounceSaveBill);

    _mobileNumberController.dispose();
    _numberPlateController.dispose();
    _discountController.dispose();
    _overallScrollController.dispose();

    _saveTimer?.cancel(); // Cancel any pending save when screen is disposed
    super.dispose();
  }

  void _debounceSaveBill() {
    _saveTimer?.cancel(); // Cancel previous timer if exists
    _saveTimer = Timer(_debounceDuration, () {
      _saveBill(); // Schedule new save
    });
  }

  Future<void> _saveBill() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final bill = Bill(
      tableId: widget.tableId,
      customerMobile: _mobileNumberController.text,
      numberPlate: _numberPlateController.text,
      serviceItems: _serviceItems, // Use the current state of _serviceItems
      discountPercentage: _discountPercentage,
      timestamp: DateTime.now(), // Update timestamp on each save for pending bills
      grandTotal: _calculateGrandTotal(), // Calculate grand total for saving
    );
    try {
      await firestoreService.saveBill(bill);
      // print('Bill for table ${widget.tableId} saved successfully.'); // For debugging
    } catch (e) {
      // print('Error saving bill for table ${widget.tableId}: $e'); // For debugging
      // Optionally show a silent error message or log it
    }
  }

  Future<void> _loadAvailableServices() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    firestoreService.getServicesAndProductsStream().listen((items) {
      setState(() {
        _allAvailableServices = items;
        _serviceProductMap = {for (var item in items) item.description.toLowerCase(): item};
      });
    });
  }

  Future<void> _loadBillData() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final bill = await firestoreService.getBill(widget.tableId);
    if (bill != null) {
      setState(() {
        _mobileNumberController.text = bill.customerMobile;
        _numberPlateController.text = bill.numberPlate;
        _discountController.text = bill.discountPercentage.toStringAsFixed(0);
        _discountPercentage = bill.discountPercentage;
        _serviceItems.clear();
        _serviceItems.addAll(bill.serviceItems);
      });
    }
  }

  void _updateDiscount() {
    setState(() {
      _discountPercentage = double.tryParse(_discountController.text) ?? 0.0;
      if (_discountPercentage < 0) _discountPercentage = 0;
      if (_discountPercentage > 100) _discountPercentage = 100;
    });
    // No explicit _debounceSaveBill() here, as _discountController's listener already calls it.
  }

  void _addServiceItem([ServiceItem? itemToAdd]) {
    setState(() {
      _serviceItems.add(itemToAdd ?? ServiceItem(description: '', quantity: 1, unitPrice: 0.0, isProduct: false));
    });
    _debounceSaveBill(); // Trigger save after adding an item
    // Scroll the entire SingleChildScrollView to the end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_overallScrollController.hasClients) {
        _overallScrollController.animateTo(
          _overallScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeServiceItem(int index) {
    setState(() {
      _serviceItems.removeAt(index);
    });
    _debounceSaveBill(); // Trigger save after removing an item
  }

  void _updateServiceItemDescription(int index, String description) {
    setState(() {
      _serviceItems[index].description = description;
      // Autopopulate price if a matching service/product is found
      final matchingItem = _serviceProductMap[description.toLowerCase()];
      if (matchingItem != null) {
        _serviceItems[index].unitPrice = matchingItem.unitPrice;
        _serviceItems[index].isProduct = matchingItem.isProduct;
        _serviceItems[index].calculateTotal(); // Recalculate total
      }
    });
    // _debounceSaveBill() will be called from the parent's ListView.builder callback
  }

  void _updateServiceItemQuantity(int index, int quantity) {
    setState(() {
      _serviceItems[index].quantity = quantity;
      _serviceItems[index].calculateTotal();
    });
    // _debounceSaveBill() will be called from the parent's ListView.builder callback
  }

  void _updateServiceItemUnitPrice(int index, double price) {
    setState(() {
      _serviceItems[index].unitPrice = price;
      _serviceItems[index].calculateTotal();
    });
    // _debounceSaveBill() will be called from the parent's ListView.builder callback
  }

  double _calculateSubTotal() {
    return _serviceItems.fold(0.0, (sum, item) => sum + item.total);
  }

  double _calculateGrandTotal() {
    double subTotal = _calculateSubTotal();
    double discountAmount = subTotal * (_discountPercentage / 100);
    return subTotal - discountAmount;
  }

  Future<void> _completeBill() async {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);

    if (_serviceItems.isEmpty) {
      CustomMessageBox.show(context, "Error", "Cannot complete an empty bill. Please add service items.");
      return;
    }
    if (_mobileNumberController.text.isEmpty || _numberPlateController.text.isEmpty) {
      CustomMessageBox.show(context, "Error", "Customer Mobile and Number Plate are required to complete a bill.");
      return;
    }

    final bool? confirm = await CustomMessageBox.showConfirmation(
      context,
      "Confirm Completion",
      "Are you sure you want to complete this bill?",
    );

    if (confirm == true) {
      try {
        final bill = Bill(
          tableId: widget.tableId,
          customerMobile: _mobileNumberController.text,
          numberPlate: _numberPlateController.text,
          serviceItems: _serviceItems,
          discountPercentage: _discountPercentage,
          timestamp: DateTime.now(),
          grandTotal: _calculateGrandTotal(), // Pass grandTotal
        );
        await firestoreService.completeBill(bill);
        await _clearBill(silent: true); // Clear the bill after completion

        CustomMessageBox.show(context, "Success", "Bill for Table ${widget.tableId} completed and cleared!");
        Navigator.of(context).pop(); // Go back to table selection
      } catch (e) {
        CustomMessageBox.show(context, "Error", "Failed to complete bill: $e");
      }
    }
  }

  Future<void> _clearBill({bool silent = false}) async {
    bool? confirm = true; // Assume confirmed if silent
    if (!silent) {
      confirm = await CustomMessageBox.showConfirmation(
        context,
        "Confirm Clear",
        "Are you sure you want to clear all data for this bill?",
      );
    }

    if (confirm == true) {
      setState(() {
        _mobileNumberController.clear();
        _numberPlateController.clear();
        _discountController.clear();
        _discountPercentage = 0.0;
        _serviceItems.clear();
      });
      final firestoreService = Provider.of<FirestoreService>(context, listen: false);
      try {
        await firestoreService.clearBill(widget.tableId);
        if (!silent) { // Only show success message if not silent
          CustomMessageBox.show(context, "Success", "Bill for Table ${widget.tableId} cleared!");
        }
      } catch (e) {
        // Always show error if clearing fails, even if silent
        CustomMessageBox.show(context, "Error", "Failed to clear bill: $e");
      }
    }
  }

  Future<void> _connectToPrinter() async {
    try {
      // Find connected devices
      List<BluetoothDevice> connectedDevices = await FlutterBluePlus.connectedDevices;
      _connectedDevice = connectedDevices.firstWhereOrNull((d) => d.advName.contains("Printer")); // Or by specific ID
      if (_connectedDevice == null) {
        // Scan for devices if not already connected
        CustomMessageBox.show(context, "Printer", "Scanning for Bluetooth printers...");
        // Start scanning and collect results
        await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
        List<ScanResult> scanResults = await FlutterBluePlus.scanResults.first; // Get first batch of results
        for (ScanResult result in scanResults) {
          if (result.device.advName.contains("Printer")) { // Replace with your printer's name or a more robust check
            _connectedDevice = result.device;
            break;
          }
        }
        await FlutterBluePlus.stopScan();
      }

      if (_connectedDevice != null) {
        CustomMessageBox.show(context, "Printer", "Connecting to ${_connectedDevice!.advName}...");
        await _connectedDevice!.connect();
        List<BluetoothService> services = await _connectedDevice!.discoverServices();
        for (var service in services) {
          for (var characteristic in service.characteristics) {
            // Usually, printer characteristics have write property
            if (characteristic.properties.write) {
              _writeCharacteristic = characteristic;
              CustomMessageBox.show(context, "Printer", "Connected to printer: ${_connectedDevice!.advName}");
              return;
            }
          }
        }
        CustomMessageBox.show(context, "Error", "Could not find a writable characteristic on the printer.");
      } else {
        CustomMessageBox.show(context, "Error", "No Bluetooth printer found. Make sure it's discoverable.");
      }
    } catch (e) {
      CustomMessageBox.show(context, "Error", "Bluetooth connection failed: $e");
    }
  }

  Future<void> _printReceipt() async {
    if (_connectedDevice == null || _writeCharacteristic == null) {
      CustomMessageBox.show(context, "Printer Error", "No printer connected. Please connect a printer first.");
      await _connectToPrinter(); // Try to connect if not already
      if (_connectedDevice == null || _writeCharacteristic == null) return;
    }

    try {
      String receiptText = _generateReceiptText();
      List<int> bytes = utf8.encode(receiptText); // Convert text to bytes

      // Split large data into chunks for Bluetooth (usually max 20 bytes per write)
      const int chunkSize = 20;
      for (int i = 0; i < bytes.length; i += chunkSize) {
        final chunk = bytes.sublist(i, i + chunkSize > bytes.length ? bytes.length : i + chunkSize);
        await _writeCharacteristic!.write(Uint8List.fromList(chunk), withoutResponse: true);
        await Future.delayed(const Duration(milliseconds: 50)); // Small delay between chunks
      }
      CustomMessageBox.show(context, "Success", "Receipt sent to printer!");
    } catch (e) {
      CustomMessageBox.show(context, "Error", "Failed to print receipt: $e");
    }
  }

  String _generateReceiptText() {
    final subTotal = _calculateSubTotal();
    final grandTotal = _calculateGrandTotal();

    String receipt = "--- MOTOR SERVICING BILL ---\n";
    receipt += "Table ID: ${widget.tableId}\n";
    receipt += "Date: ${DateTime.now().toLocal().toString().split(' ')[0]}\n";
    receipt += "Time: ${DateTime.now().toLocal().toString().split(' ')[1].substring(0, 5)}\n";
    receipt += "---------------------------\n";
    receipt += "Customer Mobile: ${_mobileNumberController.text}\n";
    receipt += "Number Plate: ${_numberPlateController.text}\n";
    receipt += "---------------------------\n";
    receipt += "Description       Qty  Price    Total\n";
    receipt += "---------------------------\n";
    for (var item in _serviceItems) {
      receipt += "${item.description.padRight(18).substring(0, 18)} "
          "${item.quantity.toString().padLeft(3)} "
          "${item.unitPrice.toStringAsFixed(2).padLeft(7)} "
          "${item.total.toStringAsFixed(2).padLeft(7)}\n";
    }
    receipt += "---------------------------\n";
    receipt += "Sub Total: ₹${subTotal.toStringAsFixed(2)}\n";
    if (_discountPercentage > 0) {
      receipt += "Discount (${_discountPercentage.toStringAsFixed(0)}%): ₹${(subTotal * (_discountPercentage / 100)).toStringAsFixed(2)}\n";
    }
    receipt += "Grand Total: ₹${grandTotal.toStringAsFixed(2)}\n";
    receipt += "---------------------------\n";
    receipt += "THANK YOU! VISIT AGAIN!\n";
    receipt += "---------------------------\n\n\n"; // Add extra newlines for proper cutting

    return receipt;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Billing for Table ${widget.tableId}'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear Bill',
            onPressed: _clearBill,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _overallScrollController,
        child: Column(
          children: [
            // Customer & Vehicle Details Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Customer & Vehicle Details',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _mobileNumberController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Customer Mobile Number',
                          hintText: 'e.g., 9876543210',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _numberPlateController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Number Plate',
                          hintText: 'e.g., MH12AB1234',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _discountController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Discount',
                          hintText: '0-100',
                          suffixText: '%',
                          prefixIcon: Icon(Icons.discount),
                          border: OutlineInputBorder(),
                          isDense: true,
                          helperText: 'Enter percentage discount (0-100)',
                          helperMaxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // List of service items
            ListView.builder(
              shrinkWrap: true, // Allows ListView to take only necessary space
              physics: const NeverScrollableScrollPhysics(), // Disables ListView's own scrolling
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: _serviceItems.length,
              itemBuilder: (context, index) {
                return ServiceItemRow(
                  serviceItem: _serviceItems[index],
                  allAvailableServices: _allAvailableServices,
                  onDescriptionChanged: (desc) {
                    _updateServiceItemDescription(index, desc);
                    _debounceSaveBill(); // Trigger save after description change
                  },
                  onQuantityChanged: (qty) {
                    _updateServiceItemQuantity(index, qty);
                    _debounceSaveBill(); // Trigger save after quantity change
                  },
                  onUnitPriceChanged: (price) {
                    _updateServiceItemUnitPrice(index, price);
                    _debounceSaveBill(); // Trigger save after unit price change
                  },
                  onRemove: () {
                    _removeServiceItem(index);
                    _debounceSaveBill(); // Trigger save after removal
                  },
                );
              },
            ),
            // Add Service Item Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () => _addServiceItem(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Service Item'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
            // Payment Summary and Action Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Sub Total:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                          Text(
                            '₹${_calculateSubTotal().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.normal),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Grand Total:',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₹${_calculateGrandTotal().toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _completeBill,
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Complete Bill'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: _printReceipt,
                        icon: const Icon(Icons.print),
                        label: const Text('Print Receipt (Bluetooth)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ServiceItemRow (updated to include direct "Add" button logic and unit price formatting)
// lib/screens/billing_screen.dart (only the ServiceItemRow class, rest of the file remains same)
// ... (rest of your BillingScreenState class and imports)

// ServiceItemRow (updated to correctly display loaded description)
class ServiceItemRow extends StatefulWidget {
  final ServiceItem serviceItem;
  final List<ServiceItem> allAvailableServices;
  final ValueChanged<String> onDescriptionChanged;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onUnitPriceChanged;
  final VoidCallback onRemove;

  const ServiceItemRow({
    super.key,
    required this.serviceItem,
    required this.allAvailableServices,
    required this.onDescriptionChanged,
    required this.onQuantityChanged,
    required this.onUnitPriceChanged,
    required this.onRemove,
  });

  @override
  State<ServiceItemRow> createState() => _ServiceItemRowState();
}

class _ServiceItemRowState extends State<ServiceItemRow> {
  late TextEditingController _descriptionController;
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  bool _showAddButton = false; // State to control add button visibility

  @override
  void initState() {
    super.initState();
    // Format unit price: 0 decimal places if whole number, else 2 decimal places
    _unitPriceController = TextEditingController(
        text: widget.serviceItem.unitPrice.toStringAsFixed(
            widget.serviceItem.unitPrice.truncateToDouble() == widget.serviceItem.unitPrice ? 0 : 2));
    _descriptionController = TextEditingController(text: widget.serviceItem.description);
    _quantityController = TextEditingController(text: widget.serviceItem.quantity.toString());

    _quantityController.addListener(() {
      final qty = int.tryParse(_quantityController.text) ?? 0;
      if (qty < 0) _quantityController.text = '0'; // Prevent negative quantity
      widget.onQuantityChanged(qty);
    });
    _unitPriceController.addListener(() {
      final price = double.tryParse(_unitPriceController.text) ?? 0.0;
      if (price < 0) _unitPriceController.text = '0.00'; // Prevent negative price
      widget.onUnitPriceChanged(price);
    });

    _descriptionController.addListener(_checkDescriptionExistence);
    _checkDescriptionExistence(); // Initial check
  }

  void _checkDescriptionExistence() {
    final text = _descriptionController.text.trim().toLowerCase();
    final exists = widget.allAvailableServices.any((item) => item.description.toLowerCase() == text);
    setState(() {
      _showAddButton = text.isNotEmpty && !exists;
    });
  }

  @override
  void dispose() {
    _descriptionController.removeListener(_checkDescriptionExistence); // Remove listener
    _descriptionController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ServiceItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    bool descriptionChangedExternally = false;
    if (widget.serviceItem.description != _descriptionController.text) {
      _descriptionController.text = widget.serviceItem.description;
      descriptionChangedExternally = true;
    }
    if (widget.serviceItem.quantity.toString() != _quantityController.text) {
      _quantityController.text = widget.serviceItem.quantity.toString();
    }
    // Update unit price text with new formatting logic
    String newUnitPriceText = widget.serviceItem.unitPrice.toStringAsFixed(
        widget.serviceItem.unitPrice.truncateToDouble() == widget.serviceItem.unitPrice ? 0 : 2);
    if (newUnitPriceText != _unitPriceController.text) {
      _unitPriceController.text = newUnitPriceText;
    }

    if (descriptionChangedExternally) {
      _checkDescriptionExistence(); // Re-check if description changed from outside
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<ServiceItem>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      if (textEditingValue.text == '') {
                        return const Iterable<ServiceItem>.empty();
                      }
                      return widget.allAvailableServices.where((ServiceItem item) {
                        return item.description.toLowerCase().contains(textEditingValue.text.toLowerCase());
                      });
                    },
                    displayStringForOption: (ServiceItem option) => option.description,
                    fieldViewBuilder: (BuildContext context, TextEditingController textEditingController, FocusNode focusNode, VoidCallback onFieldSubmitted) {
                      // ***************************************************************
                      // IMPORTANT FIX: Initialize Autocomplete's controller with the loaded description
                      // This ensures the displayed text matches the loaded data
                      if (textEditingController.text != widget.serviceItem.description) {
                        textEditingController.text = widget.serviceItem.description;
                      }
                      // Ensure the internal _descriptionController is linked to Autocomplete's controller
                      // This part was already there, but now it will receive the correctly initialized text
                      if (_descriptionController.text != textEditingController.text) {
                        _descriptionController.text = textEditingController.text;
                      }
                      // ***************************************************************

                      // Ensure listener is added/removed here if the controller instance changes, though usually it doesn't
                      if (!_descriptionController.hasListeners) {
                        _descriptionController.addListener(_checkDescriptionExistence);
                      }
                      return TextFormField(
                        controller: textEditingController, // Use Autocomplete's provided controller
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Service/Product Description',
                          prefixIcon: Icon(Icons.description),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          widget.onDescriptionChanged(value);
                          _checkDescriptionExistence(); // Re-check on every change
                        },
                        textCapitalization: TextCapitalization.sentences,
                      );
                    },
                    onSelected: (ServiceItem selection) {
                      _descriptionController.text = selection.description; // Update internal controller
                      widget.onDescriptionChanged(selection.description);
                      widget.onUnitPriceChanged(selection.unitPrice); // Auto-fill unit price
                      _checkDescriptionExistence(); // Re-check after selection
                    },
                  ),
                ),
                if (_showAddButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.blue),
                      tooltip: 'Add new service/product',
                      onPressed: () async {
                        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
                        final description = _descriptionController.text.trim();
                        final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;

                        if (description.isEmpty) {
                          CustomMessageBox.show(context, "Error", "Description cannot be empty.");
                          return;
                        }

                        final newItem = ServiceItem(
                          description: description,
                          unitPrice: unitPrice,
                          isProduct: false, // Defaulting to service
                          quantity: 1, // Explicitly provide quantity
                        );

                        try {
                          await firestoreService.addService(newItem);
                          CustomMessageBox.show(context, "Success", "'$description' added to services.");
                          // The _checkDescriptionExistence will automatically hide the button
                          // as the new item will be in _allAvailableServices.
                        } catch (e) {
                          CustomMessageBox.show(context, "Error", "Failed to add service: $e");
                        }
                      },
                    ),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove Item',
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      prefixIcon: Icon(Icons.format_list_numbered),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 4,
                  child: TextFormField(
                    controller: _unitPriceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    'Total: ₹${widget.serviceItem.total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}