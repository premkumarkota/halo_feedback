import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

/// Complete example showing the best practices for using the plugin
///
/// This example demonstrates:
/// 1. Flavor-based configuration
/// 2. Callback-based navigation
/// 3. Loading state management
/// 4. Error handling
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get flavor and app identifier from environment or use defaults
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
  const appIdentifier = String.fromEnvironment(
    'APP_IDENTIFIER',
    defaultValue: 'files',
  );

  // Initialize plugin with flavor and callbacks
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(flavor, appIdentifier: appIdentifier),
    callbacks: FeedbackCallbacks(
      // Called when feedback starts - show loading
      onStart: (context) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      },
      // Called on success - navigate to dashboard
      onSuccess: (context, data) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to dashboard with device info
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => DashboardScreen(
                  deviceId: data.config.deviceId,
                  tenantId: data.config.tenantId,
                  accessToken: data.authData.accessToken,
                ),
          ),
        );
      },
      // Called on failure - navigate to error screen
      onFailure: (context, error) {
        // Close loading dialog
        Navigator.of(context).pop();

        // Navigate to error screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorScreen(error: error)),
        );
      },
      // Called after completion - optional cleanup
      onComplete: (context) {
        // Optional: Any cleanup needed
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
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const PreLoginScreen(),
    );
  }
}

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Device Setup')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices, size: 80, color: Colors.blue),
            const SizedBox(height: 20),
            const Text(
              'Welcome to Halo Feedback',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tap the button below to initialize your device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Execute feedback - callbacks handle everything!
                HaloFeedback.instance.executeFeedback(context: context);
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Initialize Device'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String? deviceId;
  final String? tenantId;
  final String accessToken;

  const DashboardScreen({
    super.key,
    this.deviceId,
    this.tenantId,
    required this.accessToken,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Clear stored data
              await HaloFeedback.instance.clear();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const PreLoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 80, color: Colors.green),
            const SizedBox(height: 20),
            const Text(
              'Device Initialized Successfully!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            _buildInfoCard('Device ID', deviceId ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoCard('Tenant ID', tenantId ?? 'N/A'),
            const SizedBox(height: 16),
            _buildInfoCard(
              'Access Token',
              '${accessToken.substring(0, 20)}...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 32),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
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
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 80, color: Colors.red),
              const SizedBox(height: 20),
              const Text(
                'Device Initialization Failed',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Error Type:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        error.errorType.toString().split('.').last,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error Message:',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Text(error.error, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Retry feedback
                      HaloFeedback.instance.executeFeedback(context: context);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
