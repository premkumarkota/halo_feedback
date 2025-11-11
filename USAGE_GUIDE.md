# Halo Feedback Plugin - Complete Usage Guide

## Table of Contents
1. [Installation](#installation)
2. [Basic Setup](#basic-setup)
3. [Complete Flow Explanation](#complete-flow-explanation)
4. [Platform-Specific Implementation](#platform-specific-implementation)
5. [Success Flow](#success-flow)
6. [Failure Flow](#failure-flow)
7. [Best Practices](#best-practices)
8. [Example Implementation](#example-implementation)

---

## Installation

### Step 1: Add Dependency

Add the plugin to your `pubspec.yaml`:

```yaml
dependencies:
  halo_feedback:
    path: ../halo_feedback  # Local path
    # OR
    # git:
    #   url: https://github.com/your-org/halo_feedback.git
    #   ref: main
```

### Step 2: Install Dependencies

```bash
flutter pub get
```

---

## Basic Setup

### 1. Initialize Plugin in main.dart

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Halo Feedback Plugin
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig(
      baseUrl: 'https://portal.qa.halofort.com',
      appIdentifier: 'files', // Your app identifier
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
```

### 2. Using with Build Flavor

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Get flavor from environment or build config
  const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
  
  await HaloFeedback.instance.initialize(
    config: FeedbackConfig.fromFlavor(flavor),
  );
  
  runApp(const MyApp());
}
```

---

## Complete Flow Explanation

### Overview

The feedback flow is a **device authentication process** that:
1. Identifies the device on the platform
2. Sends device information to MDM server
3. Receives authentication tokens
4. Stores tokens for future API calls

### Flow Diagram

```
┌─────────────────────────────────────────────────────────┐
│              App Starts                                  │
│         PreLoginScreen.initState()                      │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│         Initialize HaloFeedback Plugin                  │
│    HaloFeedback.instance.initialize(config)             │
└─────────────────────────────────────────────────────────┘
                        ↓
┌─────────────────────────────────────────────────────────┐
│         Execute Feedback Flow                            │
│    HaloFeedback.instance.executeFeedback()            │
└─────────────────────────────────────────────────────────┘
                        ↓
        ┌───────────────┴───────────────┐
        ↓                               ↓
┌──────────────────┐          ┌──────────────────┐
│   SUCCESS        │          │    FAILURE       │
│   Flow           │          │    Flow           │
└──────────────────┘          └──────────────────┘
```

---

## Platform-Specific Implementation

### Android Flow

#### Step 1: Native Data Retrieval
```dart
// Plugin automatically calls native method
// Method: getAndroidData()
// Returns: { "randomId": "android_id", "deviceType": "Mobile" }
```

#### Step 2: KeyedAppState Feedback
```dart
// Plugin automatically sends Android Enterprise feedback
// Method: sendKeyedAppStateFeedback("TTEMM_APP", randomId)
```

#### Step 3: API Call
```dart
// Plugin calls: GET {baseUrl}/android/v1/devicefeedback/{randomId}?app=files
// Returns: { "status": "success", "data": "feedback_code" }
```

#### Step 4: Login
```dart
// Plugin calls: POST {baseUrl}/idm/v1/auth/feedback/login
// Body: { "code": "feedback_code" }
// Returns: Authentication tokens and device config
```

### iOS/macOS Flow

#### Step 1: MDM Config Retrieval
```dart
// Plugin automatically calls native method
// Method: getMDMConfig()
// Returns: { "CERT_ID": "device_udid" }
// Retries: 3 attempts with 700ms delay
```

#### Step 2: API Call
```dart
// Plugin calls: GET {baseUrl}/ios/v1/devices/feedback/{certId}?app=files
// Returns: { "status": "success", "data": "feedback_code" }
```

#### Step 3: Login
```dart
// Same as Android - POST to login endpoint
```

### Windows Flow

#### Step 1: Registry Read
```dart
// Plugin automatically reads Windows Registry
// Method: getWindowsDeviceId()
// Reads: HKEY_USERS\.DEFAULT\Software\HaloAgent\DEVICE_ID
// Fallback: HKEY_LOCAL_MACHINE\SOFTWARE\HaloAgent\DEVICE_ID
```

#### Step 2: API Call
```dart
// Plugin calls: GET {baseUrl}/win/v1/feedback/{deviceId}
// Returns: { "status": "success", "data": "feedback_code" }
```

#### Step 3: Login
```dart
// Same as Android/iOS - POST to login endpoint
```

---

## Success Flow

### What Happens on Success

```dart
final result = await HaloFeedback.instance.executeFeedback();

result.when(
  success: (data) {
    // ✅ Feedback code received
    print('Feedback Code: ${data.feedbackCode}');
    
    // ✅ Authentication tokens available
    print('Access Token: ${data.authData.accessToken}');
    print('Refresh Token: ${data.authData.refreshToken}');
    
    // ✅ Device configuration available
    print('Device ID: ${data.config.deviceId}');
    print('Tenant ID: ${data.config.tenantId}');
    print('Enterprise ID: ${data.config.enterpriseId}');
    
    // ✅ Data automatically saved to storage
    // - Token saved
    // - Device ID saved
    // - Tenant ID saved
    // - Device config saved
    
    // ✅ Navigate to next screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const DashboardScreen(),
      ),
    );
  },
  failure: (error) {
    // Handle failure (see Failure Flow below)
  },
);
```

### Success Data Structure

```dart
FeedbackSuccess {
  feedbackCode: String,        // Code received from server
  authData: FeedbackAuthData {
    accessToken: String,       // JWT access token
    refreshToken: String?,     // Refresh token (optional)
    reportingToken: String?,   // Reporting token (optional)
  },
  config: DeviceConfig {
    deviceId: String?,         // Device identifier
    tenantId: String?,         // Tenant identifier
    enterpriseId: String?,     // Enterprise identifier
    userId: String?,           // User identifier
    policy: Map?,              // Device policy
    refs: List<Ref>?,          // References
  }
}
```

### What to Do After Success

1. **Navigate to Main App**
   ```dart
   Navigator.pushReplacement(
     context,
     MaterialPageRoute(builder: (_) => const DashboardScreen()),
   );
   ```

2. **Subscribe to Firebase Topics** (Optional)
   ```dart
   if (data.config.deviceId != null) {
     await firebaseMessaging.subscribeToTopic('device.${data.config.deviceId}');
   }
   ```

3. **Initialize App Services**
   ```dart
   // Initialize your app services with the token
   await initializeAppServices(data.authData.accessToken);
   ```

---

## Failure Flow

### What Happens on Failure

```dart
final result = await HaloFeedback.instance.executeFeedback();

result.when(
  success: (data) {
    // Handle success
  },
  failure: (error) {
    // ❌ Error occurred
    print('Error: ${error.error}');
    print('Error Type: ${error.errorType}');
    
    // Handle based on error type
    switch (error.errorType) {
      case FeedbackErrorType.deviceNotFound:
        _handleDeviceNotFound(context);
        break;
      case FeedbackErrorType.missingDeviceId:
        _handleMissingDeviceId(context);
        break;
      case FeedbackErrorType.networkError:
        _handleNetworkError(context);
        break;
      case FeedbackErrorType.authenticationFailed:
        _handleAuthenticationFailed(context);
        break;
      default:
        _handleGenericError(context, error);
    }
  },
);
```

### Error Types and Handling

#### 1. Device Not Found (400)
```dart
case FeedbackErrorType.deviceNotFound:
  // Device not registered in MDM system
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Device Not Found'),
      content: const Text(
        'This device is not registered in the MDM system. '
        'Please contact your administrator.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  break;
```

#### 2. Missing Device ID
```dart
case FeedbackErrorType.missingDeviceId:
  // Device ID could not be retrieved
  if (Platform.isAndroid) {
    // Show enrollment screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const AndroidEnrollmentScreen(),
      ),
    );
  } else if (Platform.isIOS || Platform.isMacOS) {
    // Show iOS enrollment screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const IosEnrollmentScreen(),
      ),
    );
  } else if (Platform.isWindows) {
    // Show Windows setup screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const WindowsSetupScreen(),
      ),
    );
  }
  break;
```

#### 3. Network Error
```dart
case FeedbackErrorType.networkError:
  // Network request failed
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Network Error'),
      content: const Text(
        'Failed to connect to the server. '
        'Please check your internet connection and try again.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // Retry feedback
            _retryFeedback();
          },
          child: const Text('Retry'),
        ),
      ],
    ),
  );
  break;
```

#### 4. Authentication Failed
```dart
case FeedbackErrorType.authenticationFailed:
  // Login with feedback code failed
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text('Authentication Failed'),
      content: const Text(
        'Failed to authenticate with the server. '
        'Please try again or contact support.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
  break;
```

---

## Complete Example Implementation

### PreLoginScreen Example

```dart
import 'package:flutter/material.dart';
import 'package:halo_feedback/halo_feedback.dart';
import 'dart:io';

class PreLoginScreen extends StatefulWidget {
  const PreLoginScreen({super.key});

  @override
  State<PreLoginScreen> createState() => _PreLoginScreenState();
}

class _PreLoginScreenState extends State<PreLoginScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _executeFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await HaloFeedback.instance.executeFeedback();

      result.when(
        success: (data) {
          // ✅ Success - Navigate to Dashboard
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DashboardScreen(),
            ),
          );
        },
        failure: (error) {
          // ❌ Failure - Handle error
          setState(() {
            _isLoading = false;
            _error = error.error;
          });

          _handleFailure(error);
        },
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _handleFailure(FeedbackFailure error) {
    switch (error.errorType) {
      case FeedbackErrorType.deviceNotFound:
        _showDeviceNotFoundDialog();
        break;
      case FeedbackErrorType.missingDeviceId:
        _navigateToEnrollment();
        break;
      case FeedbackErrorType.networkError:
        _showNetworkErrorDialog();
        break;
      case FeedbackErrorType.authenticationFailed:
        _showAuthFailedDialog();
        break;
      default:
        _showGenericErrorDialog(error.error);
    }
  }

  void _showDeviceNotFoundDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Device Not Found'),
        content: const Text(
          'This device is not registered in the MDM system. '
          'Please contact your administrator.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToEnrollment() {
    if (Platform.isAndroid) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const AndroidEnrollmentScreen(),
        ),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const IosEnrollmentScreen(),
        ),
      );
    } else if (Platform.isWindows) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const WindowsSetupScreen(),
        ),
      );
    }
  }

  void _showNetworkErrorDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Network Error'),
        content: const Text('Please check your internet connection.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _executeFeedback(); // Retry
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _showAuthFailedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Authentication Failed'),
        content: const Text('Failed to authenticate. Please try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showGenericErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Initializing Device...',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _executeFeedback,
                    child: const Text('Start Feedback'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
      ),
    );
  }
}
```

---

## Best Practices

### 1. Initialize Early
```dart
// ✅ Good - Initialize in main() before runApp()
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HaloFeedback.instance.initialize(config: ...);
  runApp(MyApp());
}

// ❌ Bad - Initialize in widget
class MyWidget extends StatefulWidget {
  @override
  void initState() {
    super.initState();
    HaloFeedback.instance.initialize(...); // Too late!
  }
}
```

### 2. Handle Errors Properly
```dart
// ✅ Good - Handle all error types
result.when(
  success: (data) => _handleSuccess(data),
  failure: (error) {
    switch (error.errorType) {
      case FeedbackErrorType.deviceNotFound:
        // Specific handling
        break;
      // ... handle all cases
    }
  },
);

// ❌ Bad - Ignore errors
result.when(
  success: (data) => _handleSuccess(data),
  failure: (error) => print('Error'), // Not helpful!
);
```

### 3. Use Custom Storage for Production
```dart
// ✅ Good - Use custom storage
class SecureStorage implements FeedbackStorage {
  // Implement with secure storage (encrypted)
}

await HaloFeedback.instance.initialize(
  config: config,
  storage: SecureStorage(),
);
```

### 4. Retry Logic
```dart
// ✅ Good - Implement retry with exponential backoff
Future<void> _executeFeedbackWithRetry() async {
  int attempts = 0;
  const maxAttempts = 3;
  
  while (attempts < maxAttempts) {
    final result = await HaloFeedback.instance.executeFeedback();
    
    if (result is FeedbackSuccess) {
      return; // Success!
    }
    
    attempts++;
    if (attempts < maxAttempts) {
      await Future.delayed(Duration(seconds: attempts * 2));
    }
  }
}
```

---

## Platform-Specific Notes

### Android
- Requires Android Enterprise enrollment
- Uses `ANDROID_ID` as device identifier
- Sends KeyedAppState feedback automatically

### iOS/macOS
- Requires MDM profile installation
- Uses `CERT_ID` from MDM config
- Retries MDM config retrieval automatically

### Windows
- Requires HaloAgent installation
- Reads device ID from Windows Registry
- Supports both per-user and system-wide installations

---

## Troubleshooting

### Plugin Not Initialized
```dart
// Error: Plugin not initialized
// Solution: Call initialize() before executeFeedback()
await HaloFeedback.instance.initialize(config: config);
```

### Missing Native Implementation
```dart
// Error: Method not implemented
// Solution: Implement native methods in platform code
// See IMPLEMENTATION_STATUS.md for details
```

### Network Timeout
```dart
// Error: Network timeout
// Solution: Increase retry delay in RetryConfig
RetryConfig(
  maxAttempts: 5,
  delay: Duration(seconds: 10),
)
```

---

## Next Steps

1. **Implement Native Code**: See `IMPLEMENTATION_STATUS.md`
2. **Add Tests**: Write unit and integration tests
3. **Customize Storage**: Implement secure storage if needed
4. **Add Logging**: Integrate with your logging system
5. **Monitor Errors**: Track feedback success/failure rates

