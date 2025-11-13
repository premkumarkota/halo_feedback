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

  /// Factory for creating config from environment variables (optional)
  ///
  /// Note: Flavor-to-URL mapping should be handled by the app, not the plugin.
  /// This factory is provided for convenience but apps should prefer passing
  /// baseUrl directly from their own flavor logic.
  ///
  /// Example:
  /// ```dart
  /// // Preferred: Get baseUrl from app's flavor logic
  /// final baseUrl = ApiConstants.getDynamicBaseUrl();
  /// FeedbackConfig(baseUrl: baseUrl, appIdentifier: 'files')
  ///
  /// // Alternative: Use environment variable
  /// FeedbackConfig.fromEnvironment()
  /// ```
  factory FeedbackConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'BASE_URL',
      defaultValue: 'https://portal.qa.halofort.com',
    );
    const appIdentifier = String.fromEnvironment(
      'APP_IDENTIFIER',
      defaultValue: 'files',
    );
    return FeedbackConfig(baseUrl: baseUrl, appIdentifier: appIdentifier);
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
