// lib/widgets/custom_message_box.dart
import 'package:flutter/material.dart';

class CustomMessageBox {
  // For simple alerts (general purpose)
  static void show(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  // For confirmation dialogs
  static Future<bool?> showConfirmation(
      BuildContext context, String message,
      {String title = "Confirm", String confirmText = "Yes", String cancelText = "No", VoidCallback? onConfirm}) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // User must tap a button
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text(cancelText),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            ElevatedButton(
              child: Text(confirmText),
              onPressed: () {
                Navigator.of(context).pop(true);
                if (onConfirm != null) {
                  onConfirm();
                }
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  // NEW: For showing success messages
  static void showSuccess(BuildContext context, String message, {String title = "Success!"}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Flexible(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  // NEW: For showing error messages
  static void showError(BuildContext context, String message, {String title = "Error!"}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error, color: Colors.red, size: 28),
              SizedBox(width: 10),
              Flexible(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  // NEW: For showing informational messages
  static void showInfo(BuildContext context, String message, {String title = "Information"}) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Flexible(child: Text(title)),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }

  // NEW: For showing a loading indicator (non-dismissible by default)
  static void showLoading(BuildContext context, String message, {bool barrierDismissible = false}) {
    showDialog(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Flexible(child: Text(message)),
            ],
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }
}