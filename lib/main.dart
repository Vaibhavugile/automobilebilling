// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:motor_service_billing_app/firebase_options.dart'; // Ensure this file is correctly generated
import 'package:motor_service_billing_app/screens/login_screen.dart'; // Import your new LoginScreen
import 'package:motor_service_billing_app/services/firestore_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using options from DefaultFirebaseOptions.currentPlatform
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        // Provide FirestoreService: It initializes its own Firebase instances internally,
        // so no arguments are passed here.
        Provider<FirestoreService>(
          create: (_) => FirestoreService(),
        ),
      ],
      child: const MotorServiceBillingApp(),
    ),
  );
}

class MotorServiceBillingApp extends StatefulWidget {
  const MotorServiceBillingApp({super.key});

  @override
  State<MotorServiceBillingApp> createState() => _MotorServiceBillingAppState();
}

class _MotorServiceBillingAppState extends State<MotorServiceBillingApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Motor Service Billing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          elevation: 4,
          titleTextStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            elevation: 5,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
        ),
      ),
      home: const LoginScreen(), // Set LoginScreen as the initial screen
    );
  }
}