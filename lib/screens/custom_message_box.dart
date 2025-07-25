// lib/widgets/custom_message_box.dart
import 'package:flutter/material.dart';

class CustomMessageBox {
  // For simple alerts
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

  // For confirmation dialogs (replaces confirm())
  static Future<bool?> showConfirmation(
      BuildContext context, String title, String message,
      {String confirmText = "Yes", String cancelText = "No"}) async {
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
              },
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
        );
      },
    );
  }
}