/// Base exception for all feedback-related errors
class FeedbackException implements Exception {
  final String message;
  final dynamic cause;

  const FeedbackException(this.message, [this.cause]);

  @override
  String toString() =>
      'FeedbackException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when device is not found in MDM system
class DeviceNotFoundException extends FeedbackException {
  const DeviceNotFoundException([
    super.message = 'Device not found in the system',
  ]);
}

/// Exception thrown when authentication fails
class AuthenticationException extends FeedbackException {
  const AuthenticationException([super.message = 'Authentication failed']);
}

/// Exception thrown when device ID is missing
class MissingDeviceIdException extends FeedbackException {
  const MissingDeviceIdException([super.message = 'Device ID is missing']);
}

/// Exception thrown when platform is not supported
class UnsupportedPlatformException extends FeedbackException {
  const UnsupportedPlatformException([
    super.message = 'Platform is not supported',
  ]);
}

/// Exception thrown when configuration is invalid
class InvalidConfigurationException extends FeedbackException {
  const InvalidConfigurationException([
    super.message = 'Invalid configuration',
  ]);
}

/// Exception thrown when network request fails
class NetworkException extends FeedbackException {
  final int? statusCode;

  const NetworkException(super.message, [this.statusCode]);

  @override
  String toString() =>
      'NetworkException: $message${statusCode != null ? ' (status: $statusCode)' : ''}';
}
