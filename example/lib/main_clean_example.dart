import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

/// Clean example showing the best way to use the plugin
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Method 1: Initialize with flavor and callbacks (RECOMMENDED)
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(
      'qa', // or get from environment: const String.fromEnvironment('FLAVOR', defaultValue: 'qa')
      appIdentifier: 'files', // or get from environment
    ),
    callbacks: FeedbackCallbacks(
      onStart: (context) {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      },
      onSuccess: (context, data) {
        // Hide loading and navigate to success screen
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => DashboardScreen(
                  deviceId: data.config.deviceId,
                  tenantId: data.config.tenantId,
                ),
          ),
        );
      },
      onFailure: (context, error) {
        // Hide loading and navigate to error screen
        Navigator.of(context).pop(); // Close loading dialog
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorScreen(error: error)),
        );
      },
      onComplete: (context) {
        // Optional: Called after success or failure
        // Useful for cleanup
      },
    ),
  );

  runApp(const MyApp());
}

/// Alternative: From environment variables (AUTOMATIC)
void mainFromEnvironment() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Method 2: Reads FLAVOR and APP_IDENTIFIER from environment
  // Run with: flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromEnvironment(),
    callbacks: FeedbackCallbacks(
      onSuccess: (context, data) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
      onFailure: (context, error) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorScreen(error: error)),
        );
      },
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Halo Feedback Example',
      home: const PreLoginScreen(),
    );
  }
}

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            // Execute feedback - callbacks handle navigation automatically!
            HaloFeedback.instance.executeFeedback(context: context);
          },
          child: const Text('Start Feedback'),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String? deviceId;
  final String? tenantId;

  const DashboardScreen({super.key, this.deviceId, this.tenantId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Device ID: ${deviceId ?? "N/A"}'),
            Text('Tenant ID: ${tenantId ?? "N/A"}'),
          ],
        ),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final FeedbackFailure error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${error.error}'),
            Text('Type: ${error.errorType}'),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
