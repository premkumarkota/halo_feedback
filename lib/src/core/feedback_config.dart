import 'dart:io';

/// Configuration for feedback operations
class FeedbackConfig {
  /// Base URL for API calls
  final String baseUrl;

  /// App identifier (e.g., "files", "contacts")
  final String appIdentifier;

  /// Retry configuration
  final RetryConfig retryConfig;

  /// API endpoint paths (customizable)
  final EndpointConfig endpoints;

  const FeedbackConfig({
    required this.baseUrl,
    required this.appIdentifier,
    this.retryConfig = const RetryConfig(),
    this.endpoints = const EndpointConfig(),
  });

  /// Factory for common configurations based on flavor
  ///
  /// Example:
  /// ```dart
  /// FeedbackConfig.fromFlavor('qa', appIdentifier: 'files')
  /// ```
  factory FeedbackConfig.fromFlavor(String flavor, {String? appIdentifier}) {
    final baseUrl = _getBaseUrlForFlavor(flavor);
    return FeedbackConfig(
      baseUrl: baseUrl,
      appIdentifier: appIdentifier ?? _getAppIdentifierForFlavor(flavor),
    );
  }

  /// Create configuration from environment variables
  ///
  /// Reads FLAVOR and APP_IDENTIFIER from environment
  factory FeedbackConfig.fromEnvironment() {
    const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'qa');
    const appIdentifier = String.fromEnvironment(
      'APP_IDENTIFIER',
      defaultValue: 'files',
    );
    return FeedbackConfig.fromFlavor(flavor, appIdentifier: appIdentifier);
  }

  static String _getBaseUrlForFlavor(String flavor) {
    return switch (flavor.toLowerCase()) {
      'ttemmdev' => 'https://portal.dev.halofort.com',
      'ttemmdemo' => 'https://portal.emmdemo.tectoro.com',
      'ttemmqa' => 'https://portal.qa.halofort.com',
      'ttemmuat' => 'https://portal.uat.halofort.com',
      'haloprod' => 'https://portal.halofort.com',
      'multiprod' => 'https://portal.mdm.tectoro.com',
      'mdmps1' => 'https://portal.mdmps1.tectoro.com',
      'dev' => 'https://portal.dev.halofort.com',
      'qa' => 'https://portal.qa.halofort.com',
      'uat' => 'https://portal.uat.halofort.com',
      'prod' => 'https://portal.halofort.com',
      _ => 'https://portal.qa.halofort.com',
    };
  }

  static String _getAppIdentifierForFlavor(String flavor) {
    // Default app identifier based on flavor if needed
    return 'files';
  }
}

/// Retry configuration for API calls
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

/// API endpoint configuration
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
