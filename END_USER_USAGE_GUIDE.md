# Halo Feedback Plugin - End User Guide

## 🚀 Quick Start (3 Steps)

### Step 1: Initialize in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with flavor and callbacks
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(
      'qa', // Your flavor: 'dev', 'qa', 'uat', 'prod'
      appIdentifier: 'files', // Your app identifier
    ),
    callbacks: FeedbackCallbacks(
      onSuccess: (context, data) {
        // Navigate to success screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      },
      onFailure: (context, error) {
        // Navigate to error screen
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
// In your PreLoginScreen or wherever you need feedback
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
- ✅ Detects platform (Android/iOS/Windows)
- ✅ Gets device ID
- ✅ Calls feedback API
- ✅ Handles success/failure
- ✅ Navigates based on your callbacks
- ✅ Saves tokens and config

---

## 📋 Complete Examples

### Example 1: With Loading Indicator

```dart
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
```

### Example 2: Using Helper (Easiest)

```dart
// Even simpler - uses helper methods
await HaloFeedbackHelper.initializeWithFlavor(
  flavor: 'qa',
  appIdentifier: 'files',
  callbacks: FeedbackCallbacks(
    onSuccess: (context, data) => Navigator.pushReplacement(...),
    onFailure: (context, error) => Navigator.pushReplacement(...),
  ),
);
```

### Example 3: From Environment Variables

```dart
// Reads from --dart-define flags automatically
await HaloFeedbackHelper.initializeFromEnvironment(
  callbacks: FeedbackCallbacks(
    onSuccess: (context, data) => Navigator.pushReplacement(...),
    onFailure: (context, error) => Navigator.pushReplacement(...),
  ),
);

// Run with:
// flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
```

### Example 4: Manual Handling (No Callbacks)

```dart
// If you prefer manual control
final result = await HaloFeedback.instance.executeFeedback();

result.when(
  success: (data) {
    print('Device ID: ${data.config.deviceId}');
    Navigator.pushReplacement(...);
  },
  failure: (error) {
    print('Error: ${error.error}');
    showErrorDialog(...);
  },
);
```

---

## 🎯 Flavor Configuration

### Supported Flavors

```dart
// Predefined flavors with automatic base URLs
'dev'      → https://portal.dev.halofort.com
'qa'       → https://portal.qa.halofort.com
'uat'      → https://portal.uat.halofort.com
'prod'     → https://portal.halofort.com
'ttemmdev' → https://portal.dev.halofort.com
'ttemmqa'  → https://portal.qa.halofort.com
// ... and more
```

### Using Flavors

```dart
// Method 1: Direct
FeedbackConfig.fromFlavor('qa', appIdentifier: 'files')

// Method 2: From environment
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
FeedbackConfig.fromFlavor(flavor, appIdentifier: 'files')

// Method 3: From environment (automatic)
FeedbackConfig.fromEnvironment() // Reads FLAVOR and APP_IDENTIFIER
```

### Running with Flavors

```bash
# Android
flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files

# iOS
flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files

# Build
flutter build apk --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
```

---

## 🎨 Callback Options

### All Available Callbacks

```dart
FeedbackCallbacks(
  // Called when feedback starts
  onStart: (context) {
    // Show loading indicator
  },

  // Called on success
  onSuccess: (context, data) {
    // Navigate to dashboard
    // Access: data.config.deviceId, data.authData.accessToken, etc.
  },

  // Called on failure
  onFailure: (context, error) {
    // Navigate to error screen
    // Access: error.error, error.errorType
  },

  // Called after success or failure
  onComplete: (context) {
    // Cleanup, hide loading, etc.
  },
)
```

### Success Data Available

```dart
onSuccess: (context, data) {
  // data.feedbackCode - The feedback code received
  // data.authData.accessToken - JWT access token
  // data.authData.refreshToken - Refresh token (optional)
  // data.config.deviceId - Device identifier
  // data.config.tenantId - Tenant identifier
  // data.config.enterpriseId - Enterprise identifier
  // data.config.userId - User identifier
  // data.config.policy - Device policy (Map)
}
```

### Failure Error Types

```dart
onFailure: (context, error) {
  switch (error.errorType) {
    case FeedbackErrorType.deviceNotFound:
      // Device not registered in MDM
      break;
    case FeedbackErrorType.missingDeviceId:
      // Device ID could not be retrieved
      break;
    case FeedbackErrorType.networkError:
      // Network request failed
      break;
    case FeedbackErrorType.authenticationFailed:
      // Login with feedback code failed
      break;
    default:
      // Other errors
  }
}
```

---

## 🔧 Advanced Configuration

### Custom Retry Configuration

```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig(
    baseUrl: 'https://portal.qa.halofort.com',
    appIdentifier: 'files',
    retryConfig: RetryConfig(
      maxAttempts: 5,
      delay: Duration(seconds: 10),
      stopOnDeviceNotFound: true,
    ),
  ),
  callbacks: FeedbackCallbacks(...),
);
```

### Custom Storage

```dart
class MySecureStorage implements FeedbackStorage {
  // Implement your secure storage
}

await HaloFeedback.instance.initialize(
  config: FeedbackConfig(...),
  storage: MySecureStorage(),
  callbacks: FeedbackCallbacks(...),
);
```

### Custom Endpoints

```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig(
    baseUrl: 'https://portal.qa.halofort.com',
    appIdentifier: 'files',
    endpoints: EndpointConfig(
      androidEndpoint: 'custom/android/endpoint',
      iosEndpoint: 'custom/ios/endpoint',
      windowsEndpoint: 'custom/windows/endpoint',
      loginEndpoint: 'custom/login/endpoint',
    ),
  ),
  callbacks: FeedbackCallbacks(...),
);
```

---

## 📱 Complete Example App

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Get flavor from environment or use default
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
  const appIdentifier = String.fromEnvironment('APP_IDENTIFIER', defaultValue: 'files');

  // Initialize plugin
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(flavor, appIdentifier: appIdentifier),
    callbacks: FeedbackCallbacks(
      onStart: (context) {
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
          MaterialPageRoute(
            builder: (_) => DashboardScreen(
              deviceId: data.config.deviceId,
              tenantId: data.config.tenantId,
            ),
          ),
        );
      },
      onFailure: (context, error) {
        Navigator.of(context).pop(); // Close loading
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ErrorScreen(error: error),
          ),
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
      title: 'My MDM App',
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
        child: ElevatedButton(
          onPressed: () {
            // Execute feedback - callbacks handle everything!
            HaloFeedback.instance.executeFeedback(context: context);
          },
          child: const Text('Initialize Device'),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  final String? deviceId;
  final String? tenantId;

  const DashboardScreen({
    super.key,
    this.deviceId,
    this.tenantId,
  });

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
```

---

## 🎯 Best Practices

### 1. Initialize Early

```dart
// ✅ Good - Initialize in main() before runApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HaloFeedback.instance.initialize(...);
  runApp(MyApp());
}

// ❌ Bad - Don't initialize in widget
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    HaloFeedback.instance.initialize(...); // Too late!
  }
}
```

### 2. Use Callbacks for Navigation

```dart
// ✅ Good - Use callbacks
callbacks: FeedbackCallbacks(
  onSuccess: (context, data) => Navigator.pushReplacement(...),
)

// ❌ Bad - Manual handling (more code)
final result = await HaloFeedback.instance.executeFeedback();
if (result is FeedbackSuccess) {
  Navigator.pushReplacement(...);
}
```

### 3. Handle Loading States

```dart
// ✅ Good - Show/hide loading in callbacks
callbacks: FeedbackCallbacks(
  onStart: (context) => showLoading(),
  onComplete: (context) => hideLoading(),
)
```

### 4. Use Flavors for Different Environments

```dart
// ✅ Good - Use flavors
FeedbackConfig.fromFlavor('qa', appIdentifier: 'files')

// ❌ Bad - Hardcoded URLs
FeedbackConfig(baseUrl: 'https://portal.qa.halofort.com', ...)
```

---

## 🐛 Troubleshooting

### Callbacks Not Called?

Make sure you pass `context` to `executeFeedback()`:

```dart
// ✅ Good
HaloFeedback.instance.executeFeedback(context: context);

// ❌ Bad - No context, callbacks won't work
HaloFeedback.instance.executeFeedback();
```

### Navigation Not Working?

Check that you're using the correct context:

```dart
// ✅ Good - Use context from widget
onSuccess: (context, data) {
  Navigator.pushReplacement(context, ...);
}

// ❌ Bad - Using wrong context
onSuccess: (context, data) {
  Navigator.pushReplacement(globalContext, ...); // Might not work
}
```

---

## 📚 API Reference

### HaloFeedback

- `instance` - Singleton instance
- `initialize()` - Initialize plugin
- `executeFeedback()` - Execute feedback flow
- `getDeviceInfo()` - Get device information
- `clear()` - Clear stored data
- `isInitialized` - Check initialization status

### FeedbackConfig

- `fromFlavor()` - Create config from flavor
- `fromEnvironment()` - Create config from environment

### FeedbackCallbacks

- `onStart` - Called when feedback starts
- `onSuccess` - Called on success
- `onFailure` - Called on failure
- `onComplete` - Called after completion

### HaloFeedbackHelper

- `initializeWithFlavor()` - Initialize with flavor
- `initializeFromEnvironment()` - Initialize from environment
- `executeWithNavigation()` - Execute with navigation

---

## 🎉 That's It!

The plugin is designed to be **simple, clean, and easy to use**. Just:

1. Initialize with flavor and callbacks
2. Call `executeFeedback(context: context)`
3. Done! Callbacks handle the rest

Happy coding! 🚀

