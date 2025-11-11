# Flutter Feedback Plugin - Architecture Proposal

## Overview

This document proposes a **reusable Flutter plugin** for the MDM Feedback Mechanism that can be integrated across all apps, eliminating code duplication and simplifying maintenance.

## Plugin Name

**`mdm_feedback`** or **`halo_feedback`**

---

## Architecture Design

### Plugin Structure

```
mdm_feedback/
├── lib/
│   ├── mdm_feedback.dart                    # Main plugin class
│   ├── src/
│   │   ├── core/
│   │   │   ├── feedback_client.dart         # Core feedback client
│   │   │   ├── feedback_config.dart        # Configuration
│   │   │   └── feedback_result.dart        # Result models
│   │   ├── platform/
│   │   │   ├── android_feedback_handler.dart
│   │   │   ├── ios_feedback_handler.dart
│   │   │   └── windows_feedback_handler.dart
│   │   ├── models/
│   │   │   ├── feedback_data.dart
│   │   │   ├── feedback_request.dart
│   │   │   └── feedback_response.dart
│   │   ├── storage/
│   │   │   └── feedback_storage.dart       # Abstract storage interface
│   │   └── exceptions/
│   │       └── feedback_exceptions.dart
│   └── mdm_feedback_platform_interface.dart # Platform interface
├── android/
│   ├── src/main/kotlin/
│   │   └── com/example/mdm_feedback/
│   │       ├── MdmFeedbackPlugin.kt
│   │       ├── KeyedAppStatesUtil.kt
│   │       └── DeviceInfoHelper.kt
│   └── build.gradle
├── ios/
│   ├── Classes/
│   │   ├── MdmFeedbackPlugin.swift
│   │   └── MDMConfigHelper.swift
│   └── mdm_feedback.podspec
├── windows/
│   ├── mdm_feedback_plugin.cpp
│   ├── mdm_feedback_plugin.h
│   └── registry_helper.cpp
├── pubspec.yaml
└── README.md
```

---

## Core Design Principles

### 1. **Platform Abstraction**
- Single Dart API for all platforms
- Platform-specific implementations hidden
- Consistent error handling

### 2. **Configuration-Based**
- Base URL configuration
- App identifier configuration
- Retry policy configuration
- Storage implementation injection

### 3. **Extensible**
- Custom storage implementations
- Custom notification handlers
- Plugin hooks for customization

### 4. **Type-Safe**
- Strong typing with models
- Result types (Success/Failure)
- Exception hierarchy

---

## API Design

### Main Plugin Class

```dart
class MdmFeedback {
  static MdmFeedback? _instance;
  static MdmFeedback get instance => _instance ??= MdmFeedback._();
  
  MdmFeedback._();
  
  // Configuration
  late final FeedbackConfig _config;
  FeedbackStorage? _storage;
  NotificationHandler? _notificationHandler;
  
  /// Initialize the plugin
  Future<void> initialize({
    required FeedbackConfig config,
    FeedbackStorage? storage,
    NotificationHandler? notificationHandler,
  }) async {
    _config = config;
    _storage = storage ?? DefaultFeedbackStorage();
    _notificationHandler = notificationHandler;
    await _platformHandler.initialize();
  }
  
  /// Execute feedback flow
  Future<FeedbackResult> executeFeedback({
    String? deviceId,
    Map<String, dynamic>? customData,
  }) async {
    // Platform detection and routing
    if (Platform.isAndroid) {
      return await _androidHandler.execute(deviceId: deviceId);
    } else if (Platform.isIOS || Platform.isMacOS) {
      return await _iosHandler.execute(deviceId: deviceId);
    } else if (Platform.isWindows) {
      return await _windowsHandler.execute();
    } else {
      throw UnsupportedPlatformException();
    }
  }
  
  /// Get device information
  Future<DeviceInfo> getDeviceInfo() async {
    return await _platformHandler.getDeviceInfo();
  }
}
```

### Configuration Class

```dart
class FeedbackConfig {
  /// Base URL for API calls
  final String baseUrl;
  
  /// App identifier (e.g., "files", "contacts")
  final String appIdentifier;
  
  /// Retry configuration
  final RetryConfig retryConfig;
  
  /// API endpoint paths (customizable)
  final EndpointConfig endpoints;
  
  /// Platform-specific settings
  final Map<Platform, PlatformConfig> platformConfigs;
  
  const FeedbackConfig({
    required this.baseUrl,
    required this.appIdentifier,
    this.retryConfig = const RetryConfig(),
    this.endpoints = const EndpointConfig(),
    this.platformConfigs = const {},
  });
  
  /// Factory for common configurations
  factory FeedbackConfig.fromFlavor(String flavor) {
    final baseUrl = _getBaseUrlForFlavor(flavor);
    return FeedbackConfig(
      baseUrl: baseUrl,
      appIdentifier: 'files', // Default, can be overridden
    );
  }
}

class RetryConfig {
  final int maxAttempts;
  final Duration delay;
  final bool stopOnDeviceNotFound;
  
  const RetryConfig({
    this.maxAttempts = 3,
    this.delay = const Duration(seconds: 5),
    this.stopOnDeviceNotFound = true,
  });
}

class EndpointConfig {
  final String androidEndpoint;
  final String iosEndpoint;
  final String windowsEndpoint;
  final String loginEndpoint;
  
  const EndpointConfig({
    this.androidEndpoint = 'android/v1/devicefeedback',
    this.iosEndpoint = 'ios/v1/devices/feedback',
    this.windowsEndpoint = 'win/v1/feedback',
    this.loginEndpoint = 'idm/v1/auth/feedback/login',
  });
}
```

### Result Models

```dart
/// Result type for feedback operations
sealed class FeedbackResult {
  const FeedbackResult();
}

class FeedbackSuccess extends FeedbackResult {
  final String feedbackCode;
  final FeedbackAuthData authData;
  final DeviceConfig config;
  
  const FeedbackSuccess({
    required this.feedbackCode,
    required this.authData,
    required this.config,
  });
}

class FeedbackFailure extends FeedbackResult {
  final String error;
  final FeedbackErrorType errorType;
  final Exception? exception;
  
  const FeedbackFailure({
    required this.error,
    required this.errorType,
    this.exception,
  });
}

enum FeedbackErrorType {
  deviceNotFound,
  networkError,
  invalidResponse,
  missingDeviceId,
  unsupportedPlatform,
  authenticationFailed,
}

/// Authentication data from feedback login
class FeedbackAuthData {
  final String accessToken;
  final String? refreshToken;
  final String? reportingToken;
  
  const FeedbackAuthData({
    required this.accessToken,
    this.refreshToken,
    this.reportingToken,
  });
}

/// Device configuration from feedback response
class DeviceConfig {
  final String? deviceId;
  final String? tenantId;
  final String? enterpriseId;
  final String? userId;
  final Map<String, dynamic>? policy;
  final List<Ref>? refs;
  
  const DeviceConfig({
    this.deviceId,
    this.tenantId,
    this.enterpriseId,
    this.userId,
    this.policy,
    this.refs,
  });
}
```

### Storage Interface

```dart
/// Abstract storage interface for feedback data
abstract class FeedbackStorage {
  /// Save authentication token
  Future<void> saveToken(String token);
  
  /// Get authentication token
  Future<String?> getToken();
  
  /// Save refresh token
  Future<void> saveRefreshToken(String? refreshToken);
  
  /// Get refresh token
  Future<String?> getRefreshToken();
  
  /// Save device ID
  Future<void> saveDeviceId(String deviceId);
  
  /// Get device ID
  Future<String?> getDeviceId();
  
  /// Save tenant ID
  Future<void> saveTenantId(String? tenantId);
  
  /// Get tenant ID
  Future<String?> getTenantId();
  
  /// Save base URL
  Future<void> saveBaseUrl(String baseUrl);
  
  /// Get base URL
  Future<String?> getBaseUrl();
  
  /// Save device configuration
  Future<void> saveDeviceConfig(DeviceConfig config);
  
  /// Get device configuration
  Future<DeviceConfig?> getDeviceConfig();
  
  /// Clear all stored data
  Future<void> clear();
}

/// Default implementation using shared_preferences
class DefaultFeedbackStorage implements FeedbackStorage {
  final SharedPreferences _prefs;
  
  DefaultFeedbackStorage(this._prefs);
  
  // Implementation...
}
```

### Platform Handlers

```dart
/// Android Feedback Handler
class AndroidFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  
  Future<FeedbackResult> execute({String? deviceId}) async {
    try {
      // 1. Get device ID from native
      final nativeData = await _getNativeData();
      final randomId = nativeData['randomId'] as String?;
      
      if (randomId == null || randomId.isEmpty) {
        return FeedbackFailure(
          error: 'Missing device ID',
          errorType: FeedbackErrorType.missingDeviceId,
        );
      }
      
      // 2. Send Android Enterprise feedback
      await _sendKeyedAppStateFeedback(randomId);
      
      // 3. Call feedback API
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.androidEndpoint,
        deviceId: randomId,
        appIdentifier: _config.appIdentifier,
      );
      
      // 4. Login with code
      final authData = await _client.loginWithCode(code);
      
      return FeedbackSuccess(
        feedbackCode: code,
        authData: authData,
        config: authData.config,
      );
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> _getNativeData() async {
    // Method channel call to native
  }
  
  Future<void> _sendKeyedAppStateFeedback(String randomId) async {
    // Native call to KeyedAppStatesUtil
  }
}

/// iOS/macOS Feedback Handler
class IosFeedbackHandler {
  Future<FeedbackResult> execute({String? deviceId}) async {
    try {
      // 1. Get MDM config
      final mdmConfig = await _getMdmConfig();
      final certId = mdmConfig['CERT_ID'] as String?;
      
      if (certId == null || certId.isEmpty) {
        return FeedbackFailure(
          error: 'Missing CERT_ID',
          errorType: FeedbackErrorType.missingDeviceId,
        );
      }
      
      // 2. Call feedback API
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.iosEndpoint,
        deviceId: certId,
        appIdentifier: _config.appIdentifier,
      );
      
      // 3. Login with code
      final authData = await _client.loginWithCode(code);
      
      return FeedbackSuccess(
        feedbackCode: code,
        authData: authData,
        config: authData.config,
      );
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> _getMdmConfig() async {
    // Method channel call to native
  }
}

/// Windows Feedback Handler
class WindowsFeedbackHandler {
  Future<FeedbackResult> execute() async {
    try {
      // 1. Read device ID from registry
      final deviceId = await _readDeviceIdFromRegistry();
      
      if (deviceId == null || deviceId.isEmpty) {
        return FeedbackFailure(
          error: 'Device ID not found in registry',
          errorType: FeedbackErrorType.missingDeviceId,
        );
      }
      
      // 2. Call feedback API
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.windowsEndpoint,
        deviceId: deviceId,
      );
      
      // 3. Login with code
      final authData = await _client.loginWithCode(code);
      
      return FeedbackSuccess(
        feedbackCode: code,
        authData: authData,
        config: authData.config,
      );
    } catch (e) {
      return _handleError(e);
    }
  }
  
  Future<String?> _readDeviceIdFromRegistry() async {
    // Windows registry access
  }
}
```

### Feedback Client

```dart
/// HTTP client for feedback API calls
class FeedbackClient {
  final Dio _dio;
  final FeedbackConfig _config;
  
  FeedbackClient(this._dio, this._config);
  
  /// Get feedback code from server
  Future<String> getFeedbackCode({
    required String endpoint,
    required String deviceId,
    String? appIdentifier,
  }) async {
    final url = '${_config.baseUrl}/$endpoint/$deviceId';
    final queryParams = appIdentifier != null 
        ? {'app': appIdentifier} 
        : null;
    
    int attempt = 0;
    while (attempt < _config.retryConfig.maxAttempts) {
      try {
        final response = await _dio.get(url, queryParameters: queryParams);
        
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map && data['status'] == 'success') {
            return data['data'].toString();
          }
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is Map && 
              errorData['error'] == 'device not found' &&
              _config.retryConfig.stopOnDeviceNotFound) {
            throw DeviceNotFoundException('Device not found');
          }
        }
        
        if (attempt < _config.retryConfig.maxAttempts - 1) {
          await Future.delayed(_config.retryConfig.delay);
        }
      }
      attempt++;
    }
    
    throw FeedbackException('Failed after ${_config.retryConfig.maxAttempts} attempts');
  }
  
  /// Login with feedback code
  Future<FeedbackAuthData> loginWithCode(String code) async {
    final url = '${_config.baseUrl}/${_config.endpoints.loginEndpoint}';
    
    final response = await _dio.post(
      url,
      data: {'code': code},
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    
    if (response.statusCode == 200) {
      final data = response.data;
      if (data is Map && data['status'] == 'success') {
        final responseData = data['data'] as Map<String, dynamic>;
        final configData = responseData['conifg'] as Map<String, dynamic>?;
        
        return FeedbackAuthData(
          accessToken: responseData['token'] as String,
          refreshToken: responseData['refreshToken'] as String?,
          reportingToken: responseData['reportingToken'] as String?,
          config: DeviceConfig.fromJson(configData ?? {}),
        );
      }
    }
    
    throw AuthenticationException('Invalid login response');
  }
}
```

---

## Usage Example

### Basic Usage

```dart
import 'package:mdm_feedback/mdm_feedback.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize plugin
  await MdmFeedback.instance.initialize(
    config: FeedbackConfig(
      baseUrl: 'https://portal.qa.halofort.com',
      appIdentifier: 'files',
    ),
    storage: MyCustomStorage(), // Optional: custom storage
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FeedbackScreen(),
    );
  }
}

class FeedbackScreen extends StatefulWidget {
  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isLoading = false;
  String? _error;
  
  Future<void> _executeFeedback() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final result = await MdmFeedback.instance.executeFeedback();
    
    setState(() {
      _isLoading = false;
    });
    
    result.when(
      success: (data) {
        // Handle success
        print('Token: ${data.authData.accessToken}');
        print('Device ID: ${data.config.deviceId}');
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => DashboardScreen(),
        ));
      },
      failure: (error) {
        // Handle failure
        setState(() {
          _error = error.error;
        });
      },
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _executeFeedback,
                    child: Text('Execute Feedback'),
                  ),
                  if (_error != null)
                    Text(_error!, style: TextStyle(color: Colors.red)),
                ],
              ),
      ),
    );
  }
}
```

### Advanced Usage with Custom Storage

```dart
class MyCustomStorage implements FeedbackStorage {
  final MyDatabase _db;
  
  MyCustomStorage(this._db);
  
  @override
  Future<void> saveToken(String token) async {
    await _db.save('token', token);
  }
  
  @override
  Future<String?> getToken() async {
    return await _db.get('token');
  }
  
  // Implement other methods...
}

// Initialize with custom storage
await MdmFeedback.instance.initialize(
  config: FeedbackConfig.fromFlavor('qa'),
  storage: MyCustomStorage(myDatabase),
);
```

### Usage with BLoC

```dart
class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  final MdmFeedback _feedback = MdmFeedback.instance;
  
  FeedbackBloc() : super(FeedbackInitial()) {
    on<ExecuteFeedbackEvent>(_onExecuteFeedback);
  }
  
  Future<void> _onExecuteFeedback(
    ExecuteFeedbackEvent event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(FeedbackLoading());
    
    final result = await _feedback.executeFeedback();
    
    result.when(
      success: (data) {
        emit(FeedbackSuccess(data: data));
      },
      failure: (error) {
        emit(FeedbackFailure(error: error.error));
      },
    );
  }
}
```

---

## Migration Guide

### Step 1: Add Plugin Dependency

```yaml
# pubspec.yaml
dependencies:
  mdm_feedback:
    git:
      url: https://github.com/your-org/mdm_feedback.git
      ref: main
```

### Step 2: Replace Existing Code

**Before:**
```dart
// Old code
context.read<FeedbackBloc>().add(SendFeedbackEvent(randomId));
```

**After:**
```dart
// New code
final result = await MdmFeedback.instance.executeFeedback();
```

### Step 3: Update Storage

**Before:**
```dart
await UserDataStorage.saveToken(token);
```

**After:**
```dart
// Plugin handles storage automatically
// Or use custom storage implementation
await customStorage.saveToken(token);
```

### Step 4: Remove Old Files

Remove:
- `lib/src/presentation/bloc/feedback_watcher/`
- `lib/src/domain/usecase/feedback.dart`
- `lib/src/domain/usecase/WindowsFeedbackUseCase.dart`
- `lib/src/data/datasource/feedback_remote_data_source.dart`
- `lib/src/data/repository/feedback_repository_impl.dart`

Keep (if needed):
- Native implementations (can be moved to plugin)
- Custom storage implementations

---

## Plugin Benefits

### 1. **Code Reusability**
- Single implementation for all apps
- Consistent behavior across apps
- Reduced maintenance burden

### 2. **Easier Testing**
- Isolated plugin code
- Mock implementations
- Unit test coverage

### 3. **Simplified Integration**
- Simple API
- Configuration-based setup
- Minimal boilerplate

### 4. **Better Error Handling**
- Unified error types
- Consistent error messages
- Better debugging

### 5. **Extensibility**
- Custom storage implementations
- Plugin hooks
- Custom notification handlers

---

## Implementation Phases

### Phase 1: Core Plugin (Week 1-2)
- [ ] Create plugin structure
- [ ] Implement core classes
- [ ] Android implementation
- [ ] Basic tests

### Phase 2: Platform Support (Week 3-4)
- [ ] iOS/macOS implementation
- [ ] Windows implementation
- [ ] Platform-specific tests

### Phase 3: Integration (Week 5)
- [ ] Storage interface
- [ ] Notification integration
- [ ] Documentation
- [ ] Example app

### Phase 4: Migration (Week 6)
- [ ] Migrate first app
- [ ] Test in production
- [ ] Fix issues
- [ ] Migrate remaining apps

---

## Testing Strategy

### Unit Tests
```dart
void main() {
  group('FeedbackClient', () {
    test('should get feedback code successfully', () async {
      // Test implementation
    });
    
    test('should handle device not found error', () async {
      // Test implementation
    });
  });
}
```

### Integration Tests
```dart
void main() {
  group('MdmFeedback Integration', () {
    testWidgets('should execute feedback flow', (tester) async {
      // Test implementation
    });
  });
}
```

### Platform Tests
- Android: Test KeyedAppStatesUtil
- iOS: Test MDM config retrieval
- Windows: Test registry access

---

## Dependencies

### pubspec.yaml
```yaml
name: mdm_feedback
description: MDM Feedback Plugin for Flutter
version: 1.0.0

dependencies:
  flutter:
    sdk: flutter
  dio: ^5.0.0
  shared_preferences: ^2.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  mockito: ^5.0.0

flutter:
  plugin:
    platforms:
      android:
        package: com.example.mdm_feedback
        pluginClass: MdmFeedbackPlugin
      ios:
        pluginClass: MdmFeedbackPlugin
      windows:
        pluginClass: MdmFeedbackPlugin
```

---

## Conclusion

This plugin architecture provides:
- ✅ **Reusability**: Use across all apps
- ✅ **Simplicity**: Easy to integrate
- ✅ **Flexibility**: Customizable storage and handlers
- ✅ **Maintainability**: Single source of truth
- ✅ **Testability**: Isolated, testable code

The plugin follows Flutter best practices and provides a clean, type-safe API for MDM feedback operations.

