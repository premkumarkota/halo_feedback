# Halo Feedback Plugin - Quick Start Guide

## 🎯 The Simplest Way to Use (3 Steps)

### Step 1: Initialize in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get flavor and app identifier (from environment or hardcode)
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
  const appIdentifier = String.fromEnvironment('APP_IDENTIFIER', defaultValue: 'files');

  // Initialize with callbacks for automatic navigation
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(flavor, appIdentifier: appIdentifier),
    callbacks: FeedbackCallbacks(
      onSuccess: (context, data) {
        // Navigate to your dashboard/home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
      onFailure: (context, error) {
        // Navigate to your error/enrollment screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorScreen(error: error)),
        );
      },
    ),
  );

  runApp(const MyApp());
}
```

### Step 2: Execute Feedback

```dart
// In your PreLoginScreen or wherever
ElevatedButton(
  onPressed: () {
    // That's it! Callbacks handle navigation automatically
    HaloFeedback.instance.executeFeedback(context: context);
  },
  child: const Text('Start Feedback'),
)
```

### Step 3: Done! 🎉

The plugin automatically:
- ✅ Detects platform
- ✅ Gets device ID
- ✅ Calls API
- ✅ Handles success/failure
- ✅ Navigates based on your callbacks
- ✅ Saves all data

---

## 📱 Complete Example

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
    callbacks: FeedbackCallbacks(
      onStart: (context) {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator()),
        );
      },
      onSuccess: (context, data) {
        Navigator.of(context).pop(); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
      onFailure: (context, error) {
        Navigator.of(context).pop(); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ErrorScreen(error: error)),
        );
      },
    ),
  );

  runApp(const MyApp());
}

class PreLoginScreen extends StatelessWidget {
  const PreLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            HaloFeedback.instance.executeFeedback(context: context);
          },
          child: const Text('Start Feedback'),
        ),
      ),
    );
  }
}
```

---

## 🎨 Flavor Support

### Using Flavors

```dart
// Method 1: Direct flavor
FeedbackConfig.fromFlavor('qa', appIdentifier: 'files')

// Method 2: From environment
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
FeedbackConfig.fromFlavor(flavor, appIdentifier: 'files')

// Method 3: Automatic from environment
FeedbackConfig.fromEnvironment() // Reads FLAVOR and APP_IDENTIFIER
```

### Running with Flavors

```bash
flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
```

---

## 🔄 Callback Options

```dart
FeedbackCallbacks(
  onStart: (context) {
    // Called when feedback starts - show loading
  },
  onSuccess: (context, data) {
    // Called on success - navigate to dashboard
    // data.config.deviceId, data.authData.accessToken available
  },
  onFailure: (context, error) {
    // Called on failure - navigate to error screen
    // error.error, error.errorType available
  },
  onComplete: (context) {
    // Called after success or failure - cleanup
  },
)
```

---

## 🎯 That's It!

The plugin is designed to be **simple and clean**. Just:
1. Initialize with flavor and callbacks
2. Call `executeFeedback(context: context)`
3. Done!

See `END_USER_USAGE_GUIDE.md` for more details.

