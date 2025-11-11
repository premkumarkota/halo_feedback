# Halo Feedback Plugin - API Summary

## 🎯 Clean & Simple API for End Users

### Initialization (One Line with Flavor)

```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
  callbacks: FeedbackCallbacks(
    onSuccess: (context, data) => Navigator.pushReplacement(...),
    onFailure: (context, error) => Navigator.pushReplacement(...),
  ),
);
```

### Execution (One Line)

```dart
HaloFeedback.instance.executeFeedback(context: context);
```

---

## 📋 Complete API Reference

### 1. Initialization

#### Basic Initialization
```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig(
    baseUrl: 'https://portal.qa.halofort.com',
    appIdentifier: 'files',
  ),
);
```

#### With Flavor (Recommended)
```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor(
    'qa', // or 'dev', 'uat', 'prod'
    appIdentifier: 'files',
  ),
);
```

#### From Environment (Automatic)
```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromEnvironment(), // Reads FLAVOR and APP_IDENTIFIER
);
```

#### With Callbacks (Best Practice)
```dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
  callbacks: FeedbackCallbacks(
    onStart: (context) => showLoading(),
    onSuccess: (context, data) => navigateToDashboard(),
    onFailure: (context, error) => navigateToError(),
    onComplete: (context) => hideLoading(),
  ),
);
```

### 2. Execute Feedback

#### With Callbacks (Automatic Navigation)
```dart
// Callbacks handle navigation automatically
HaloFeedback.instance.executeFeedback(context: context);
```

#### Manual Handling
```dart
final result = await HaloFeedback.instance.executeFeedback();

result.when(
  success: (data) {
    // Handle success
    Navigator.pushReplacement(...);
  },
  failure: (error) {
    // Handle failure
    showErrorDialog(...);
  },
);
```

### 3. Callbacks

```dart
FeedbackCallbacks(
  // Called when feedback starts
  onStart: (BuildContext context) {
    // Show loading indicator
  },
  
  // Called on success
  onSuccess: (BuildContext context, FeedbackSuccess data) {
    // Navigate to dashboard
    // Access: data.config.deviceId, data.authData.accessToken
  },
  
  // Called on failure
  onFailure: (BuildContext context, FeedbackFailure error) {
    // Navigate to error screen
    // Access: error.error, error.errorType
  },
  
  // Called after completion
  onComplete: (BuildContext context) {
    // Cleanup, hide loading
  },
)
```

### 4. Configuration

#### Flavor Configuration
```dart
// Supported flavors
'dev'      → https://portal.dev.halofort.com
'qa'       → https://portal.qa.halofort.com
'uat'      → https://portal.uat.halofort.com
'prod'     → https://portal.halofort.com
'ttemmdev' → https://portal.dev.halofort.com
'ttemmqa'  → https://portal.qa.halofort.com
// ... and more
```

#### Custom Configuration
```dart
FeedbackConfig(
  baseUrl: 'https://custom.url.com',
  appIdentifier: 'myapp',
  retryConfig: RetryConfig(
    maxAttempts: 5,
    delay: Duration(seconds: 10),
  ),
)
```

---

## 🎨 Usage Patterns

### Pattern 1: Simple (Recommended)

```dart
// Initialize once in main.dart
await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
  callbacks: FeedbackCallbacks(
    onSuccess: (context, data) => Navigator.pushReplacement(...),
    onFailure: (context, error) => Navigator.pushReplacement(...),
  ),
);

// Execute anywhere
HaloFeedback.instance.executeFeedback(context: context);
```

### Pattern 2: With Loading

```dart
callbacks: FeedbackCallbacks(
  onStart: (context) => showDialog(...),
  onSuccess: (context, data) {
    Navigator.pop(context); // Close loading
    Navigator.pushReplacement(...);
  },
  onFailure: (context, error) {
    Navigator.pop(context); // Close loading
    Navigator.pushReplacement(...);
  },
)
```

### Pattern 3: Environment-Based

```dart
// In main.dart
const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
const appId = String.fromEnvironment('APP_IDENTIFIER', defaultValue: 'files');

await HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor(flavor, appIdentifier: appId),
  callbacks: FeedbackCallbacks(...),
);

// Run with:
// flutter run --dart-define=FLAVOR=qa --dart-define=APP_IDENTIFIER=files
```

---

## ✅ Benefits

1. **Simple**: Just 2 lines of code
2. **Clean**: Callbacks handle navigation automatically
3. **Flexible**: Supports flavors, environment variables, custom configs
4. **Type-Safe**: Strong typing throughout
5. **Error Handling**: Comprehensive error types
6. **Automatic**: Saves tokens and config automatically

---

## 📚 See Also

- `QUICK_START_GUIDE.md` - Quick 3-step guide
- `END_USER_USAGE_GUIDE.md` - Complete usage guide
- `example/lib/main_complete_example.dart` - Full working example

