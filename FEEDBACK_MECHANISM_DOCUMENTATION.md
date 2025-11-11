# Feedback Mechanism - Complete Documentation

## Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Platform-Specific Implementations](#platform-specific-implementations)
4. [Data Flow](#data-flow)
5. [API Endpoints](#api-endpoints)
6. [Code Documentation](#code-documentation)
7. [Error Handling](#error-handling)
8. [Dependencies](#dependencies)

---

## Overview

The Feedback Mechanism is a cross-platform device authentication system that enables MDM (Mobile Device Management) apps to authenticate devices with the server and retrieve configuration data. It supports **Android**, **iOS/macOS**, and **Windows** platforms.

### Purpose
- Authenticate devices with MDM server
- Retrieve device-specific configuration
- Obtain authentication tokens (access token, refresh token)
- Subscribe to Firebase Cloud Messaging topics for push notifications

---

## Architecture

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────┐
│         Presentation Layer (BLoC)              │
│  - FeedbackBloc                                │
│  - FeedbackEvent/State                         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│         Domain Layer                            │
│  - FeedbackRepository (Interface)              │
│  - FeedbackUseCase                              │
│  - WindowsFeedbackUseCase                       │
│  - FeedbackLoginUseCase                         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│         Data Layer                              │
│  - FeedbackRepositoryImpl                       │
│  - FeedbackRemoteDataSource                     │
│  - FeedbackData (Model)                         │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│         Native Layer                            │
│  - Android: MainActivity.kt                     │
│  - Android: KeyedAppStatesUtil.kt               │
│  - iOS: Method Channel (getMDMConfig)           │
│  - Windows: WindowsRegistry.dart                │
└─────────────────────────────────────────────────┘
```

---

## Platform-Specific Implementations

### 1. Android Mobile

#### Native Side (MainActivity.kt)

**Method Channel: `my_native_plugin`**

**Method: `getData`**
- **Purpose**: Retrieves device information and generates device ID
- **Location**: `MainActivity.kt:75-164`
- **Process**:
  1. Detects device type using `getDeviceType()` (Mobile/TV/IFP)
  2. For Mobile devices:
     - Generates `randomId` using `Settings.Secure.ANDROID_ID`
     - Calls `KeyedAppStatesUtil.appFeedback()` to send feedback to Android Enterprise
  3. Returns data map with:
     - `deviceType`: "Mobile"
     - `randomId`: Android ID string
     - `managedConfig`: App restrictions (baseURL, etc.)

**KeyedAppStatesUtil.kt**
- **Purpose**: Sends feedback to Android Enterprise using KeyedAppStatesReporter
- **Location**: `KeyedAppStatesUtil.kt:12-35`
- **Implementation**:
  ```kotlin
  KeyedAppStatesReporter.create(context)
      .setStatesImmediate(setOf(KeyedAppState))
  ```
- **Key**: "TTEMM_APP"
- **Message**: randomId (Android ID)

#### Flutter Side

**Entry Point**: `PreLoginScreen._handleAndroidFlow()`
- **Location**: `PreLoginScreen.dart:134-158`
- **Process**:
  1. Receives native data from `getData` method channel
  2. Saves device type to storage
  3. Routes to `_handleMobileAndroidFlow()` for Mobile devices

**Mobile Flow**: `PreLoginScreen._handleMobileAndroidFlow()`
- **Location**: `PreLoginScreen.dart:281-329`
- **Process**:
  1. Extracts `randomId` and `baseUrl` from native data
  2. Saves base URL to storage
  3. Dispatches `SetBaseUrlEvent` to FeedbackBloc
  4. Shows loading dialog
  5. Dispatches `SendFeedbackEvent(randomId)` to FeedbackBloc

**Feedback API Call**:
- **UseCase**: `FeedbackUseCase.feedbackExecute(emmId, baseUrl)`
- **Repository**: `FeedbackRepositoryImpl.sendFeedback()`
- **DataSource**: `FeedbackRemoteDataSourceImpl.feedbackLog()`
- **Endpoint**: `GET {baseUrl}/android/v1/devicefeedback/{randomId}?app=files`
- **Retries**: 3 attempts with 5-second delays
- **Response**: `{"status": "success", "data": "feedback_code"}`

**Feedback Login**:
- **Endpoint**: `POST {baseUrl}/idm/v1/auth/feedback/login`
- **Body**: `{"code": "feedback_code"}`
- **Response**: `FeedbackData` containing:
  - `token`: Access token
  - `refreshToken`: Refresh token
  - `configData`: Device configuration (deviceId, tenant, policy, etc.)

---

### 2. Android TV/IFP

#### Native Side

**Content Provider Access**
- **URI**: `content://com.example.providerapp.provider/data`
- **Location**: `MainActivity.kt:537-617`
- **Process**:
  1. Queries content provider for authentication data
  2. Reads columns: `token`, `refreshToken`, `deviceId`, `baseUrl`, `tenant`
  3. Returns `ContentProviderData` object

**Intent Data (Alternative)**
- **Location**: `MainActivity.kt:421-453`
- **Process**:
  1. Checks for intent extras: `EXTRA_TEXT` (token), `device_id`, `base_url`, `tenant`
  2. Returns intent data map

#### Flutter Side

**TV Flow**: `PreLoginScreen._handleTvFlow()`
- **Location**: `PreLoginScreen.dart:331-443`
- **Process**:
  1. Checks `intentData` first, then `contentProviderData`
  2. If token exists:
     - Saves token, deviceId, baseUrl, tenant to storage
     - Navigates directly to Dashboard (skips feedback API)
  3. If token missing:
     - Shows detailed error dialog with diagnostic information

**Note**: TV/IFP devices skip the feedback API flow and use pre-provided tokens.

---

### 3. iOS/macOS

#### Native Side

**Method Channel: `my_native_plugin`**

**Method: `getMDMConfig`**
- **Purpose**: Retrieves MDM configuration from iOS/macOS device
- **Location**: Called from Flutter via method channel
- **Process**:
  1. Accesses MDM profile configuration
  2. Extracts `CERT_ID` (UDID) from MDM config
  3. Returns config map with `CERT_ID`

#### Flutter Side

**Entry Point**: `PreLoginScreen.getConfigForIosApp()`
- **Location**: `PreLoginScreen.dart:161-278`
- **Process**:
  1. Calls native `getMDMConfig` with retry logic (3 attempts, 700ms delay)
  2. Extracts `CERT_ID` (device UDID)
  3. Gets base URL from `ApiConstants.getDynamicBaseUrl()`
  4. Dispatches `SetBaseUrlEvent`
  5. If `CERT_ID` exists:
     - Shows loading dialog
     - Dispatches `SendIosMacFeedbackEvent(deviceUdid)`
  6. If `CERT_ID` missing:
     - Checks for saved UDID from QR enrollment flow
     - If saved UDID exists, uses it
     - Otherwise, shows enrollment screen

**Feedback API Call**:
- **UseCase**: `FeedbackUseCase.feedbackExecuteIosMacOs(emmId, baseUrl)`
- **Repository**: `FeedbackRepositoryImpl.sendFeedbackForIOSMacOS()`
- **DataSource**: `FeedbackRemoteDataSourceImpl.getFeedbackStringForIOSAndMacOs()`
- **Endpoint**: `GET {baseUrl}/ios/v1/devices/feedback/{emmId}?app=files`
- **Retries**: 3 attempts with 5-second delays
- **Response**: `{"status": "success", "data": "feedback_code"}`

**Feedback Login**: Same as Android (POST to `/idm/v1/auth/feedback/login`)

---

### 4. Windows

#### Native Side

**Windows Registry Access**
- **Location**: `WindowsRegistry.dart`
- **Process**:
  1. Reads from Windows Registry:
     - Primary: `HKEY_USERS\.DEFAULT\Software\HaloAgent`
     - Fallback: `HKEY_LOCAL_MACHINE\SOFTWARE\HaloAgent`
  2. Extracts `DEVICE_ID` from registry
  3. Uses `win32` package for registry access

**App Info Registry**
- **Location**: `FeedbackRemoteDataSourceImpl.fetchRegistryValuesAndSendFeedback()`
- **Process**:
  1. Enumerates subkeys in `SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall`
  2. Finds matching subkey with `Publisher == "Tectoro"` and `DisplayName == "Halo Files"`
  3. Saves app info to storage

#### Flutter Side

**Entry Point**: `PreLoginScreen._handleWindowsFlow()`
- **Location**: `PreLoginScreen.dart:446-473`
- **Process**:
  1. Gets base URL from `ApiConstants.getDynamicBaseUrl()` (flavor-based)
  2. Shows loading dialog
  3. Dispatches `SetBaseUrlEvent`
  4. Dispatches `SendWindowsFeedbackEvent()`

**Feedback API Call**:
- **UseCase**: `WindowsFeedbackUseCase.feedbackWindowsExecute()`
- **Repository**: `FeedbackRepositoryImpl.getWindowsFeedbackCode()`
- **DataSource**: `FeedbackRemoteDataSourceImpl.fetchRegistryValuesAndSendFeedback()`
- **Process**:
  1. Reads `DEVICE_ID` from Windows Registry
  2. Calls API: `GET {baseUrl}/win/v1/feedback/{deviceId}`
  3. Retries: 3 attempts with 5-second delays
  4. Response: `{"status": "success", "data": "feedback_code"}`

**Feedback Login**: Same as Android/iOS (POST to `/idm/v1/auth/feedback/login`)

---

## Data Flow

### Complete Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    App Initialization                        │
│                  PreLoginScreen.initState()                  │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Fetch Native Data                               │
│  Android: getData() → randomId/ContentProvider              │
│  iOS: getMDMConfig() → CERT_ID                              │
│  Windows: Read Registry → DEVICE_ID                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Platform Detection & Routing                    │
│  _handlePlatformLogic() → Platform-specific handler         │
└─────────────────────────────────────────────────────────────┘
                            ↓
        ┌───────────────────┴───────────────────┐
        ↓                   ↓                   ↓
┌──────────────┐   ┌──────────────┐   ┌──────────────┐
│   Android    │   │  iOS/macOS    │   │   Windows     │
│   Mobile     │   │               │   │               │
└──────────────┘   └──────────────┘   └──────────────┘
        ↓                   ↓                   ↓
┌─────────────────────────────────────────────────────────────┐
│              Dispatch Feedback Event                        │
│  SendFeedbackEvent(randomId)                               │
│  SendIosMacFeedbackEvent(certId)                           │
│  SendWindowsFeedbackEvent()                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              FeedbackBloc Processing                        │
│  1. Validate platform                                      │
│  2. Check base URL                                         │
│  3. Call UseCase → Repository → DataSource                 │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              API Call: Get Feedback Code                    │
│  GET {baseUrl}/{platform}/v1/feedback/{deviceId}?app=files│
│  Retries: 3 attempts, 5-second delays                       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Receive Feedback Code                          │
│  Response: {"status": "success", "data": "code"}           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Feedback Login API Call                        │
│  POST {baseUrl}/idm/v1/auth/feedback/login                 │
│  Body: {"code": "feedback_code"}                            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Receive Authentication Data                     │
│  FeedbackData:                                              │
│    - token (access token)                                   │
│    - refreshToken                                           │
│    - configData (deviceId, tenant, policy, etc.)           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Save Data & Subscribe                         │
│  1. Save tokens to UserDataStorage                         │
│  2. Save device config                                      │
│  3. Subscribe to Firebase topics (device, user, enterprise)│
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│              Navigate to Next Screen                        │
│  FeedbackSuccess → PrivacyPolicyScreen                     │
│  FeedbackFailure → Error/Enrollment Screen                 │
└─────────────────────────────────────────────────────────────┘
```

---

## API Endpoints

### Base URL Configuration

**Android/iOS/macOS**: Determined by app flavor
- `ttemmdev` → `https://portal.dev.halofort.com`
- `ttemmdemo` → `https://portal.emmdemo.tectoro.com`
- `ttemmqa` → `https://portal.qa.halofort.com`
- `ttemmuat` → `https://portal.uat.halofort.com`
- `haloprod` → `https://portal.halofort.com`
- `multiprod` → `https://portal.mdm.tectoro.com`
- `mdmps1` → `https://portal.mdmps1.tectoro.com`

**Windows**: Determined by build define `FLAVOR`
- Same mapping as above
- Default: `https://portal.qa.halofort.com`

### Endpoints

#### 1. Android Feedback
- **Method**: `GET`
- **Path**: `{baseUrl}/android/v1/devicefeedback/{emmId}?app=files`
- **Parameters**:
  - `emmId`: Android ID (randomId)
  - `app`: Application identifier (default: "files")
- **Response**:
  ```json
  {
    "status": "success",
    "data": "feedback_code_string"
  }
  ```
- **Error Response** (400):
  ```json
  {
    "error": "device not found"
  }
  ```

#### 2. iOS/macOS Feedback
- **Method**: `GET`
- **Path**: `{baseUrl}/ios/v1/devices/feedback/{emmId}?app=files`
- **Parameters**:
  - `emmId`: CERT_ID (UDID from MDM config)
  - `app`: Application identifier (default: "files")
- **Response**: Same as Android

#### 3. Windows Feedback
- **Method**: `GET`
- **Path**: `{baseUrl}/win/v1/feedback/{deviceId}`
- **Parameters**:
  - `deviceId`: DEVICE_ID from Windows Registry
- **Response**: Same as Android

#### 4. Feedback Login (All Platforms)
- **Method**: `POST`
- **Path**: `{baseUrl}/idm/v1/auth/feedback/login`
- **Headers**: `Content-Type: application/json`
- **Body**:
  ```json
  {
    "code": "feedback_code_from_step_1"
  }
  ```
- **Response**:
  ```json
  {
    "status": "success",
    "data": {
      "token": "access_token",
      "refreshToken": "refresh_token",
      "reportingToken": "reporting_token",
      "conifg": {
        "app": "files",
        "device": "device_id",
        "tenant": "tenant_id",
        "enterprise": "enterprise_id",
        "user": "user_id",
        "policy": { ... },
        "refs": [ ... ]
      }
    }
  }
  ```

---

## Code Documentation

### FeedbackBloc

**Location**: `lib/src/presentation/bloc/feedback_watcher/feedback_bloc.dart`

**Purpose**: Manages feedback flow state and business logic

**Dependencies**:
- `FeedbackUseCase`: Android/iOS feedback
- `WindowsFeedbackUseCase`: Windows feedback
- `FeedbackLoginUseCase`: Login with feedback code
- `FirebaseNotificationService`: Subscribe to topics

**Events**:
1. `SendFeedbackEvent(emmId)`: Android Mobile feedback
2. `SendWindowsFeedbackEvent()`: Windows feedback
3. `SendIosMacFeedbackEvent(emmId)`: iOS/macOS feedback
4. `SetBaseUrlEvent(baseUrl)`: Set base URL

**States**:
1. `FeedbackInitial`: Initial state
2. `FeedbackLoading`: Loading state
3. `FeedbackSuccess(data)`: Success with data
4. `FeedbackFailure(error)`: Failure with error message

**Key Methods**:
- `onSendFeedback()`: Handles Android feedback
- `onSendWindowsFeedback()`: Handles Windows feedback
- `onSendIosMacOsFeedback()`: Handles iOS/macOS feedback
- `_handleFeedbackLogin()`: Handles login after receiving feedback code

### FeedbackRepository

**Location**: `lib/src/domain/repositories/feedback_repository.dart`

**Interface Methods**:
- `sendFeedback(emmId, baseUrl)`: Android feedback
- `sendFeedbackForIOSMacOS(certId, baseUrl)`: iOS/macOS feedback
- `getWindowsFeedbackCode()`: Windows feedback
- `loginWithFeedbackCode(code)`: Login with code

### FeedbackRemoteDataSource

**Location**: `lib/src/data/datasource/feedback_remote_data_source.dart`

**Key Methods**:
- `feedbackLog(emmId, baseUrl)`: Android API call
- `getFeedbackStringForIOSAndMacOs(emmId, baseUrl)`: iOS/macOS API call
- `fetchRegistryValuesAndSendFeedback()`: Windows registry read + API call
- `feedbackLogin(code)`: Login API call

**Retry Logic**:
- Max retries: 3
- Delay: 5 seconds
- Stops on "device not found" error (400)

### FeedbackData Model

**Location**: `lib/src/model/FeedbackData.dart`

**Structure**:
```
FeedbackData
  ├── status: String
  └── data: Data
      ├── token: String
      ├── refreshToken: String
      ├── reportingToken: String
      └── conifg: Config
          ├── app: String
          ├── device: String
          ├── tenant: String
          ├── enterprise: String
          ├── user: String
          ├── policy: Policy
          └── refs: List<Ref>
```

---

## Error Handling

### Error Types

1. **Device Not Found (400)**
   - **Cause**: Device not registered in MDM system
   - **Action**: Stop retries, show error message
   - **Location**: `FeedbackRemoteDataSourceImpl`

2. **Missing Device ID**
   - **Android**: Missing randomId
   - **iOS**: Missing CERT_ID
   - **Windows**: Missing DEVICE_ID in registry
   - **Action**: Show enrollment screen

3. **Network Errors**
   - **Action**: Retry up to 3 times with 5-second delays
   - **Location**: All data source methods

4. **Invalid Response**
   - **Action**: Emit `FeedbackFailure` state
   - **Location**: FeedbackBloc

### Error Flow

```
API Error
  ↓
Catch Exception
  ↓
Check Error Type
  ↓
┌─────────────────┬─────────────────┬─────────────────┐
│ Device Not Found│ Network Error   │ Invalid Response│
│ (400)           │                 │                 │
│                 │                 │                 │
│ Stop Retries    │ Retry (3x)      │ Emit Failure    │
│ Show Error      │                 │                 │
└─────────────────┴─────────────────┴─────────────────┘
```

---

## Dependencies

### Flutter Packages
- `dio`: HTTP client
- `flutter_bloc`: State management
- `dartz`: Functional programming (Either type)
- `equatable`: Value equality
- `win32`: Windows registry access (Windows only)
- `firebase_messaging`: Push notifications
- `flutter_local_notifications`: Local notifications

### Native Dependencies

**Android**:
- `androidx.enterprise:enterprise-feedback`: KeyedAppStatesReporter

**iOS/macOS**:
- MDM profile configuration access

**Windows**:
- Windows Registry API (via win32 package)

---

## Storage

### UserDataStorage Methods Used

- `saveToken(token)`: Save access token
- `saveRefreshToken(refreshToken)`: Save refresh token
- `saveDeviceId(deviceId)`: Save device ID
- `saveTenantId(tenant)`: Save tenant ID
- `saveBaseUrl(baseUrl)`: Save base URL
- `saveDeviceData(configData)`: Save device configuration
- `saveDeviceType(deviceType)`: Save device type (Mobile/TV/IFP)

---

## Firebase Integration

### Topic Subscription

After successful feedback login, the app subscribes to Firebase topics:

1. **Device Topic**: `device.{deviceId}`
2. **User Topic**: `user.{userId}` (if available)
3. **Enterprise Topic**: `enterprise.{enterpriseId}` (if available)

**Location**: `FeedbackBloc._handleFeedbackLogin()`

**Service**: `FirebaseNotificationService.subscribeToDeviceTopic()`

---

## Testing Considerations

### Unit Tests
- FeedbackUseCase
- FeedbackRepository
- FeedbackRemoteDataSource
- FeedbackBloc

### Integration Tests
- End-to-end feedback flow
- Error handling scenarios
- Retry logic

### Platform-Specific Tests
- Android: KeyedAppStatesUtil
- iOS: MDM config retrieval
- Windows: Registry access

---

## Future Improvements

1. **Centralized Error Handling**: Unified error handling strategy
2. **Offline Support**: Queue feedback requests when offline
3. **Analytics**: Track feedback success/failure rates
4. **Caching**: Cache feedback codes for retry scenarios
5. **Plugin Architecture**: Extract to reusable plugin (see plugin proposal)

---

## Conclusion

The Feedback Mechanism is a critical component for MDM device authentication. It handles platform-specific complexities while maintaining a unified interface through the BLoC pattern. The implementation follows clean architecture principles with clear separation of concerns.

