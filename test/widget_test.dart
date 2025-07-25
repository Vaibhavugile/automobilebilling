import 'package:flutter_test/flutter_test.dart';
import 'package:motor_service_billing_app/main.dart'; // Import your new main file

void main() {
  testWidgets('App starts without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // Note: For a real test with Firebase, you'd need to mock Firebase dependencies.
    // This test primarily checks if the app builds and renders its initial screen.
    await tester.pumpWidget(const MotorServiceBillingApp());

    // Verify that the initial screen's title appears
    expect(find.text('Motor Service Billing'), findsOneWidget);
    expect(find.text('Your User ID:'), findsOneWidget); // Check for the User ID display
  });
}