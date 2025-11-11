# halo_feedback

[![pub package](https://img.shields.io/pub/v/halo_feedback.svg)](https://pub.dev/packages/halo_feedback)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A cross-platform Flutter plugin for MDM (Mobile Device Management) feedback mechanism. This plugin enables device authentication and configuration retrieval across Android, iOS, macOS, and Windows platforms with a clean, callback-based API.

## Features

- ✅ **Cross-platform support**: Android, iOS, macOS, Windows
- ✅ **Unified API**: Single interface for all platforms
- ✅ **Configurable**: Easy configuration with base URLs and app identifiers
- ✅ **Storage abstraction**: Customizable storage implementations
- ✅ **Error handling**: Comprehensive error types and handling
- ✅ **Retry logic**: Built-in retry mechanism for network requests

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  halo_feedback: ^0.0.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

### 1. Initialize in `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize with flavor and callbacks
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
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
```

### 2. Execute Feedback

```dart
// In your PreLoginScreen
ElevatedButton(
  onPressed: () {
    // Callbacks handle navigation automatically!
    HaloFeedback.instance.executeFeedback(context: context);
  },
  child: const Text('Start Feedback'),
)
```

### 3. Done! 🎉

The plugin automatically handles platform detection, API calls, and navigation.

## Usage

### With Flavor Support

```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
  callbacks: FeedbackCallbacks(...),
);
```

### From Environment Variables

```dart
// Run with: flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromEnvironment(),
  callbacks: FeedbackCallbacks(...),
);
```

### Manual Handling (Without Callbacks)

```dart
final result = await HaloFeedback.instance.executeFeedback();

result.when(
  success: (data) {
    print('Token: ${data.authData.accessToken}');
    print('Device ID: ${data.config.deviceId}');
    Navigator.pushReplacement(...);
  },
  failure: (error) {
    print('Error: ${error.error}');
    showErrorDialog(...);
  },
);
```

### Custom Storage

```dart
class MyCustomStorage implements FeedbackStorage {
  // Implement storage methods
}

await HaloFeedback.instance.initialize(
  config: FeedbackConfig(...),
  storage: MyCustomStorage(),
);
```

## Configuration

### FeedbackConfig

```dart
FeedbackConfig(
  baseUrl: 'https://portal.qa.halofort.com',
  appIdentifier: 'files',
  retryConfig: RetryConfig(
    maxAttempts: 3,
    delay: Duration(seconds: 5),
    stopOnDeviceNotFound: true,
  ),
  endpoints: EndpointConfig(
    androidEndpoint: 'android/v1/devicefeedback',
    iosEndpoint: 'ios/v1/devices/feedback',
    windowsEndpoint: 'win/v1/feedback',
    loginEndpoint: 'idm/v1/auth/feedback/login',
  ),
)
```

## Platform-Specific Implementation

### Android

The plugin automatically:
- Gets device ID from Android ID
- Sends KeyedAppState feedback to Android Enterprise
- Calls feedback API with device ID

### iOS/macOS

The plugin automatically:
- Retrieves MDM config (CERT_ID)
- Calls feedback API with CERT_ID
- Handles retry logic for MDM config retrieval

### Windows

The plugin automatically:
- Reads device ID from Windows Registry
- Calls feedback API with device ID

## Error Handling

```dart
result.when(
  success: (data) {
    // Handle success
  },
  failure: (error) {
    switch (error.errorType) {
      case FeedbackErrorType.deviceNotFound:
        // Device not found in MDM system
        break;
      case FeedbackErrorType.missingDeviceId:
        // Device ID is missing
        break;
      case FeedbackErrorType.networkError:
        // Network error occurred
        break;
      case FeedbackErrorType.authenticationFailed:
        // Authentication failed
        break;
      default:
        // Other errors
    }
  },
);
```

## API Reference

### HaloFeedback

- `initialize()`: Initialize the plugin with configuration
- `executeFeedback()`: Execute the feedback flow
- `getDeviceInfo()`: Get device information
- `clear()`: Clear all stored data
- `isInitialized`: Check if plugin is initialized

### FeedbackResult

- `FeedbackSuccess`: Contains feedback code, auth data, and config
- `FeedbackFailure`: Contains error message and error type

## Native Implementation Required

The plugin requires native implementations for:

### Android
- `getAndroidData()`: Returns device data including randomId
- `sendKeyedAppStateFeedback()`: Sends KeyedAppState feedback

### iOS/macOS
- `getMDMConfig()`: Returns MDM configuration with CERT_ID

### Windows
- `getWindowsDeviceId()`: Reads device ID from registry

## Development

See `FEEDBACK_MECHANISM_DOCUMENTATION.md` and `FLUTTER_FEEDBACK_PLUGIN_PROPOSAL.md` for detailed documentation.

## Documentation

- [Quick Start Guide](QUICK_START_GUIDE.md) - Get started in 3 steps
- [End User Usage Guide](END_USER_USAGE_GUIDE.md) - Complete usage documentation
- [API Summary](API_SUMMARY.md) - API reference

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
