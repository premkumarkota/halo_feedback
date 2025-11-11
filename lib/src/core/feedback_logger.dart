import 'dart:developer' as developer;

/// Comprehensive logging utility for Halo Feedback Plugin
/// All logs are prefixed with [HaloFeedback] for easy filtering
class FeedbackLogger {
  static const String _tag = 'HaloFeedback';

  /// Enable/disable verbose logging (default: true)
  static bool verboseLogging = true;

  /// Log plugin initialization
  static void logInitialization({
    required String baseUrl,
    required String? appIdentifier,
    String? flavor,
  }) {
    if (!verboseLogging) return;
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🚀 HALO FEEDBACK PLUGIN INITIALIZED', name: _tag);
    developer.log('Base URL: $baseUrl', name: _tag);
    if (appIdentifier != null) {
      developer.log('App Identifier: $appIdentifier', name: _tag);
    }
    if (flavor != null) {
      developer.log('Flavor: $flavor', name: _tag);
    }
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    // Also print to console for visibility
    print(
      '🚀 [HaloFeedback] Plugin initialized - Base URL: $baseUrl, Flavor: $flavor',
    );
  }

  /// Log platform detection
  static void logPlatformDetection(String platform) {
    if (!verboseLogging) return;
    developer.log('📱 Platform Detected: $platform', name: _tag);
    print('📱 [HaloFeedback] Platform: $platform');
  }

  /// Log Android-specific data
  static void logAndroidData({
    required String? randomId,
    required String? androidId,
    required String? deviceType,
    Map<String, dynamic>? nativeData,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🤖 ANDROID DEVICE DATA', name: _tag);
    developer.log('Random ID: ${randomId ?? "N/A"}', name: _tag);
    developer.log('Android ID: ${androidId ?? "N/A"}', name: _tag);
    developer.log('Device Type: ${deviceType ?? "N/A"}', name: _tag);

    if (nativeData != null) {
      developer.log(
        'Native Data Keys: ${nativeData.keys.join(", ")}',
        name: _tag,
      );

      // Log Content Provider Data
      final contentProviderData = nativeData['contentProviderData'];
      if (contentProviderData != null) {
        developer.log('📦 Content Provider Data:', name: _tag);
        developer.log(
          '  Token: ${contentProviderData['token'] != null ? "✓ Present" : "✗ Missing"}',
          name: _tag,
        );
        developer.log(
          '  Device ID: ${contentProviderData['deviceId'] ?? "N/A"}',
          name: _tag,
        );
        developer.log(
          '  Base URL: ${contentProviderData['baseUrl'] ?? "N/A"}',
          name: _tag,
        );
        developer.log(
          '  Tenant: ${contentProviderData['tenant'] ?? "N/A"}',
          name: _tag,
        );
        developer.log(
          '  Refresh Token: ${contentProviderData['refreshToken'] != null ? "✓ Present" : "✗ Missing"}',
          name: _tag,
        );
      }

      // Log Intent Data
      final intentData = nativeData['intentData'];
      if (intentData != null) {
        developer.log('📨 Intent Data:', name: _tag);
        developer.log(
          '  Message: ${intentData['message'] != null ? "✓ Present" : "✗ Missing"}',
          name: _tag,
        );
        developer.log(
          '  Device ID: ${intentData['deviceId'] ?? "N/A"}',
          name: _tag,
        );
        developer.log(
          '  Base URL: ${intentData['baseUrl'] ?? "N/A"}',
          name: _tag,
        );
        developer.log('  Tenant: ${intentData['tenant'] ?? "N/A"}', name: _tag);
      }
    }
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log iOS/macOS MDM config
  static void logIosMdmConfig({
    required Map<String, dynamic>? mdmConfig,
    required String? deviceId,
    int? attempt,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🍎 iOS/macOS MDM CONFIG', name: _tag);
    if (attempt != null) {
      developer.log('Attempt: $attempt', name: _tag);
    }
    developer.log('Device ID (UDID): ${deviceId ?? "N/A"}', name: _tag);
    if (mdmConfig != null) {
      developer.log(
        'MDM Config Keys: ${mdmConfig.keys.join(", ")}',
        name: _tag,
      );
      final certId = mdmConfig['CERT_ID'];
      developer.log('CERT_ID: ${certId ?? "N/A"}', name: _tag);
    } else {
      developer.log('MDM Config: Not available', name: _tag);
    }
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log Windows registry data
  static void logWindowsRegistry({required String? deviceId}) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🪟 WINDOWS REGISTRY DATA', name: _tag);
    developer.log('Device ID: ${deviceId ?? "N/A"}', name: _tag);
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log API URL construction
  static void logApiUrl({
    required String baseUrl,
    required String endpoint,
    required String deviceId,
    String? appIdentifier,
    String? queryParams,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🌐 FEEDBACK API REQUEST', name: _tag);
    developer.log('Base URL: $baseUrl', name: _tag);
    developer.log('Endpoint: $endpoint', name: _tag);
    developer.log('Device ID: $deviceId', name: _tag);
    if (appIdentifier != null) {
      developer.log('App Identifier: $appIdentifier', name: _tag);
    }
    final fullUrl =
        '$baseUrl/$endpoint/$deviceId${queryParams != null ? "?$queryParams" : ""}';
    developer.log('Full URL: $fullUrl', name: _tag);
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log API response
  static void logApiResponse({
    required int? statusCode,
    required dynamic response,
    String? endpoint,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('📥 API RESPONSE', name: _tag);
    if (endpoint != null) {
      developer.log('Endpoint: $endpoint', name: _tag);
    }
    developer.log('Status Code: ${statusCode ?? "N/A"}', name: _tag);
    developer.log('Response: $response', name: _tag);
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log KeyedAppState feedback
  static void logKeyedAppState({
    required String key,
    required String message,
    bool success = true,
    String? error,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('📤 KEYED APP STATE FEEDBACK', name: _tag);
    developer.log('Key: $key', name: _tag);
    developer.log('Message: $message', name: _tag);
    if (success) {
      developer.log('Status: ✓ Sent successfully', name: _tag);
    } else {
      developer.log('Status: ✗ Failed', name: _tag);
      if (error != null) {
        developer.log('Error: $error', name: _tag);
      }
    }
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log login API call
  static void logLoginApi({
    required String baseUrl,
    required String endpoint,
    required String code,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('🔐 LOGIN API REQUEST', name: _tag);
    developer.log('Base URL: $baseUrl', name: _tag);
    developer.log('Endpoint: $endpoint', name: _tag);
    developer.log('Code: $code', name: _tag);
    final fullUrl = '$baseUrl/$endpoint';
    developer.log('Full URL: $fullUrl', name: _tag);
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
  }

  /// Log success result
  static void logSuccess({
    required String? feedbackCode,
    required String? deviceId,
    required String? tenantId,
    required String? baseUrl,
    String? platform,
  }) {
    if (!verboseLogging) return;
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('✅ FEEDBACK SUCCESS', name: _tag);
    if (platform != null) {
      developer.log('Platform: $platform', name: _tag);
    }
    if (feedbackCode != null) {
      developer.log('Feedback Code: $feedbackCode', name: _tag);
    } else {
      developer.log('Feedback Code: N/A (TV/IFP flow)', name: _tag);
    }
    developer.log('Device ID: ${deviceId ?? "N/A"}', name: _tag);
    developer.log('Tenant ID: ${tenantId ?? "N/A"}', name: _tag);
    developer.log('Base URL: ${baseUrl ?? "N/A"}', name: _tag);
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    print(
      '✅ [HaloFeedback] SUCCESS - Device: ${deviceId ?? "N/A"}, Code: ${feedbackCode ?? "N/A (TV/IFP)"}',
    );
  }

  /// Log failure result
  static void logFailure({
    required String error,
    required String errorType,
    String? platform,
    String? details,
  }) {
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    developer.log('❌ FEEDBACK FAILURE', name: _tag);
    if (platform != null) {
      developer.log('Platform: $platform', name: _tag);
    }
    developer.log('Error Type: $errorType', name: _tag);
    developer.log('Error: $error', name: _tag);
    if (details != null) {
      developer.log('Details: $details', name: _tag);
    }
    developer.log(
      '═══════════════════════════════════════════════════════════',
      name: _tag,
    );
    print('❌ [HaloFeedback] FAILURE - Type: $errorType, Error: $error');
    if (details != null) {
      print('❌ [HaloFeedback] Details: $details');
    }
  }

  /// Log retry attempt
  static void logRetry({
    required int attempt,
    required int maxAttempts,
    required String? reason,
  }) {
    developer.log('🔄 Retry Attempt: $attempt/$maxAttempts', name: _tag);
    if (reason != null) {
      developer.log('Reason: $reason', name: _tag);
    }
  }

  /// Log flow type
  static void logFlowType(String flowType) {
    if (!verboseLogging) return;
    developer.log('🔄 Flow Type: $flowType', name: _tag);
    print('🔄 [HaloFeedback] $flowType');
  }
}
