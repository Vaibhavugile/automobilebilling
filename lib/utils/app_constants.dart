// lib/utils/app_constants.dart
import 'dart:convert';

// Global variables provided by the Canvas environment
// These are accessed as environment variables during build time.
// Provide default values for local development if not set.
class AppConstants {
  static const String appId = String.fromEnvironment('APP_ID', defaultValue: 'default-app-id');
  static const String firebaseConfig = String.fromEnvironment('FIREBASE_CONFIG', defaultValue: '{}');
  static const String initialAuthToken = String.fromEnvironment('INITIAL_AUTH_TOKEN', defaultValue: '');
}