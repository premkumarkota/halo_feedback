import '../models/feedback_data.dart';

/// Result type for feedback operations
sealed class FeedbackResult {
  const FeedbackResult();

  /// Pattern matching helper
  T when<T>({
    required T Function(FeedbackSuccess) success,
    required T Function(FeedbackFailure) failure,
  }) {
    return switch (this) {
      FeedbackSuccess s => success(s),
      FeedbackFailure f => failure(f),
    };
  }
}

/// Success result containing feedback data
class FeedbackSuccess extends FeedbackResult {
  final String? feedbackCode; // Nullable for TV/IFP flow (no feedback code)
  final FeedbackAuthData authData;
  final DeviceConfig config;

  const FeedbackSuccess({
    this.feedbackCode,
    required this.authData,
    required this.config,
  });
}

/// Failure result containing error information
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

/// Error types for feedback operations
enum FeedbackErrorType {
  deviceNotFound,
  networkError,
  invalidResponse,
  missingDeviceId,
  unsupportedPlatform,
  authenticationFailed,
}
