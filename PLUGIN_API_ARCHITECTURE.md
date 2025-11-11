# Halo Feedback Plugin - API Architecture Explanation

## How APIs Work in the Plugin (Without RemoteDataSource or Bloc)

### Overview

The `halo_feedback` plugin handles all API calls **internally** using a clean, self-contained architecture. End-users don't need to create `RemoteDataSource`, `Repository`, `UseCase`, or `Bloc` classes - the plugin handles everything automatically.

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    End-User Application                     │
│  (PreLoginScreen.dart - Just calls executeFeedback())      │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│              HaloFeedback (Main Plugin Class)               │
│  • Singleton instance                                       │
│  • Routes to platform-specific handlers                     │
│  • Manages callbacks for UI navigation                      │
└──────────────────────┬──────────────────────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Android    │ │     iOS      │ │   Windows    │
│   Handler    │ │   Handler    │ │   Handler    │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │
       └────────────────┼────────────────┘
                        │
                        ▼
              ┌──────────────────┐
              │ FeedbackClient   │
              │ (HTTP Client)    │
              │ • Dio instance   │
              │ • Retry logic     │
              │ • Error handling │
              └────────┬─────────┘
                       │
                       ▼
              ┌──────────────────┐
              │   API Server     │
              │ (Feedback & Login)│
              └──────────────────┘
```

---

## Step-by-Step Flow

### 1. **End-User Calls Plugin**

```dart
// In PreLoginScreen.dart
await halo_feedback.HaloFeedback.instance.executeFeedback(
  context: context,
);
```

**What happens:**
- User just calls one method
- No need to create API clients, repositories, or state management
- Plugin handles everything internally

---

### 2. **Plugin Routes to Platform Handler**

```dart
// In lib/halo_feedback.dart
if (Platform.isAndroid) {
  result = await _androidHandler!.execute();
} else if (Platform.isIOS || Platform.isMacOS) {
  result = await _iosHandler!.execute(deviceId: deviceId);
} else if (Platform.isWindows) {
  result = await _windowsHandler!.execute();
}
```

**What happens:**
- Plugin detects platform automatically
- Routes to appropriate handler (Android/iOS/Windows)
- Each handler has platform-specific logic

---

### 3. **Platform Handler Gets Device ID**

#### **Android:**
```dart
// In android_feedback_handler.dart
final data = await _getNativeData(); // Calls native Kotlin code
final randomId = data['randomId'];
final deviceType = data['deviceType'];
```

#### **iOS:**
```dart
// In ios_feedback_handler.dart
final mdmConfig = await _getMdmConfig(); // Calls native Swift code
final certId = mdmConfig['CERT_ID'];
```

#### **Windows:**
```dart
// In windows_feedback_handler.dart
final deviceId = await _readDeviceIdFromRegistry(); // Calls native C++ code
```

**What happens:**
- Each platform handler calls native code via MethodChannel
- Gets device-specific identifier (randomId, CERT_ID, DEVICE_ID)
- No need for end-user to handle native code

---

### 4. **Platform Handler Calls FeedbackClient**

```dart
// In android_feedback_handler.dart (Mobile flow)
final code = await _client.getFeedbackCode(
  endpoint: _config.endpoints.androidEndpoint, // 'android/v1/devicefeedback'
  deviceId: randomId,
  appIdentifier: _config.appIdentifier,
);
```

**What happens:**
- Handler uses `FeedbackClient` (internal HTTP client)
- Passes endpoint, device ID, and app identifier
- `FeedbackClient` handles all HTTP communication

---

### 5. **FeedbackClient Makes HTTP Request**

```dart
// In feedback_client.dart
final url = '${_config.baseUrl}/$endpoint/$deviceId';
// Example: https://portal.qa.halofort.com/android/v1/devicefeedback/abc123?app=files

final response = await _dio.get(url, queryParameters: queryParams);
```

**What happens:**
- `FeedbackClient` uses `Dio` (HTTP client library) internally
- Constructs full URL from base URL + endpoint + device ID
- Makes GET request to feedback API
- Handles retry logic (3 attempts, 5 seconds delay)
- Handles errors (device not found, network errors, etc.)

**Logs:**
```
🌐 [HaloFeedback] FEEDBACK API - Platform: Android
🌐 [HaloFeedback] URL: https://portal.qa.halofort.com/android/v1/devicefeedback/abc123?app=files
```

---

### 6. **FeedbackClient Calls Login API**

```dart
// In feedback_client.dart
final loginResult = await _client.loginWithCode(code);

// Internally:
final url = '${_config.baseUrl}/${_config.endpoints.loginEndpoint}';
// Example: https://portal.qa.halofort.com/idm/v1/auth/feedback/login

final response = await _dio.post(
  url,
  data: {'code': code},
);
```

**What happens:**
- After getting feedback code, calls login API
- Makes POST request with feedback code
- Gets authentication token and device config
- Returns `FeedbackAuthData` and `DeviceConfig`

**Logs:**
```
🔐 [HaloFeedback] LOGIN API - Platform: All Platforms
🔐 [HaloFeedback] URL: https://portal.qa.halofort.com/idm/v1/auth/feedback/login
🔐 [HaloFeedback] Code: 123456
```

---

### 7. **Platform Handler Returns Result**

```dart
// In android_feedback_handler.dart
final result = FeedbackSuccess(
  feedbackCode: code,
  authData: loginResult.authData,
  config: loginResult.config,
);

return result;
```

**What happens:**
- Handler wraps result in `FeedbackSuccess` or `FeedbackFailure`
- Returns to main plugin class
- Plugin invokes callbacks for UI navigation

---

### 8. **Plugin Invokes Callbacks**

```dart
// In lib/halo_feedback.dart
if (result is FeedbackSuccess) {
  _callbacks?.onSuccess(context, result);
} else if (result is FeedbackFailure) {
  _callbacks?.onFailure(context, result);
}
```

**What happens:**
- Plugin calls user-provided callbacks
- End-user handles navigation in callbacks
- No need for Bloc or state management

---

## Key Components

### 1. **FeedbackClient** (`lib/src/core/feedback_client.dart`)

**Purpose:** Internal HTTP client for all API calls

**Responsibilities:**
- Makes HTTP requests using `Dio`
- Handles retry logic (3 attempts, 5 seconds delay)
- Handles errors (device not found, network errors)
- Logs all API requests and responses
- Returns structured data (`FeedbackAuthData`, `DeviceConfig`)

**Why not RemoteDataSource?**
- `FeedbackClient` IS the data source
- It's internal to the plugin
- End-users don't need to create their own

---

### 2. **Platform Handlers** (`lib/src/platform/*_feedback_handler.dart`)

**Purpose:** Platform-specific logic for each OS

**Responsibilities:**
- Get device ID from native code
- Call `FeedbackClient` with correct endpoint
- Handle platform-specific flows (e.g., TV/IFP for Android)
- Return `FeedbackResult` (Success or Failure)

**Why not Repository?**
- Platform handlers ARE the repository
- They orchestrate data flow
- End-users don't need to create their own

---

### 3. **HaloFeedback** (`lib/halo_feedback.dart`)

**Purpose:** Main plugin class (singleton)

**Responsibilities:**
- Initialize plugin with configuration
- Route to platform handlers
- Invoke callbacks for UI navigation
- Save data to storage

**Why not Bloc?**
- Plugin uses callbacks instead of events/states
- Simpler API for end-users
- No need for state management boilerplate

---

## API Endpoints by Platform

### Android Mobile:
```
GET https://portal.qa.halofort.com/android/v1/devicefeedback/{randomId}?app=files
```

### iOS/macOS:
```
GET https://portal.qa.halofort.com/ios/v1/devices/feedback/{certId}?app=files
```

### Windows:
```
GET https://portal.qa.halofort.com/win/v1/feedback/{deviceId}
```

### Login (All Platforms):
```
POST https://portal.qa.halofort.com/idm/v1/auth/feedback/login
Body: {"code": "123456"}
```

---

## Logging

All API calls are automatically logged:

### Feedback API:
```
🌐 [HaloFeedback] FEEDBACK API - Platform: Android
🌐 [HaloFeedback] URL: https://portal.qa.halofort.com/android/v1/devicefeedback/abc123?app=files
```

### Login API:
```
🔐 [HaloFeedback] LOGIN API - Platform: All Platforms
🔐 [HaloFeedback] URL: https://portal.qa.halofort.com/idm/v1/auth/feedback/login
🔐 [HaloFeedback] Code: 123456
```

### API Response:
```
📥 API RESPONSE
Status Code: 200
Response: {"status": "success", "data": "123456"}
```

---

## Comparison: Old vs. Plugin Approach

### **Old Approach (With Bloc/Repository):**

```dart
// End-user had to create:
1. FeedbackRemoteDataSource (API calls)
2. FeedbackRepository (Business logic)
3. FeedbackUseCase (Orchestration)
4. FeedbackBloc (State management)
5. FeedbackEvent (Events)
6. FeedbackState (States)

// Usage:
BlocProvider.of<FeedbackBloc>(context).add(ExecuteFeedbackEvent());
BlocListener<FeedbackBloc, FeedbackState>(
  listener: (context, state) {
    if (state is FeedbackSuccess) { ... }
    if (state is FeedbackFailure) { ... }
  },
)
```

### **New Approach (With Plugin):**

```dart
// End-user just calls:
await HaloFeedback.instance.executeFeedback(context: context);

// With callbacks:
HaloFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa'),
  callbacks: FeedbackCallbacks(
    onSuccess: (context, data) => Navigator.pushReplacement(...),
    onFailure: (context, error) => Navigator.pushReplacement(...),
  ),
);
```

**Benefits:**
- ✅ No boilerplate code
- ✅ No state management needed
- ✅ No repository/data source classes
- ✅ Simple callback-based API
- ✅ All API logic handled internally
- ✅ Automatic logging
- ✅ Automatic error handling
- ✅ Automatic retry logic

---

## Summary

**The plugin handles all API calls internally:**

1. **FeedbackClient** = Your RemoteDataSource (but internal)
2. **Platform Handlers** = Your Repository (but internal)
3. **HaloFeedback** = Your UseCase + Bloc (but simpler with callbacks)

**End-users just need to:**
- Initialize plugin with config
- Call `executeFeedback()`
- Handle navigation in callbacks

**No need for:**
- ❌ RemoteDataSource
- ❌ Repository
- ❌ UseCase
- ❌ Bloc
- ❌ State management
- ❌ API client setup
- ❌ Error handling boilerplate
- ❌ Retry logic

Everything is handled by the plugin automatically! 🎉

