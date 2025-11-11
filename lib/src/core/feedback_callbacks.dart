import 'package:flutter/material.dart';
import '../core/feedback_result.dart';

/// Callbacks for feedback flow navigation and handling
class FeedbackCallbacks {
  /// Called when feedback succeeds
  /// Provides the success data and BuildContext for navigation
  final void Function(BuildContext context, FeedbackSuccess data)? onSuccess;

  /// Called when feedback fails
  /// Provides the failure data and BuildContext for navigation
  final void Function(BuildContext context, FeedbackFailure failure)? onFailure;

  /// Called before feedback execution starts
  /// Useful for showing loading indicators
  final void Function(BuildContext context)? onStart;

  /// Called when feedback execution completes (success or failure)
  /// Useful for hiding loading indicators
  final void Function(BuildContext context)? onComplete;

  const FeedbackCallbacks({
    this.onSuccess,
    this.onFailure,
    this.onStart,
    this.onComplete,
  });

  /// Empty callbacks (no navigation)
  const FeedbackCallbacks.empty()
    : onSuccess = null,
      onFailure = null,
      onStart = null,
      onComplete = null;
}
