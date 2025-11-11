import 'package:flutter/services.dart';
import '../core/feedback_client.dart';
import '../core/feedback_config.dart';
import '../core/feedback_result.dart';
import '../exceptions/feedback_exceptions.dart';

/// Windows Feedback Handler
class WindowsFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  static const MethodChannel _channel = MethodChannel('halo_feedback');

  WindowsFeedbackHandler(this._config, this._client);

  Future<FeedbackResult> execute() async {
    try {
      // 1. Read device ID from registry
      final deviceId = await _readDeviceIdFromRegistry();

      if (deviceId == null || deviceId.isEmpty) {
        return FeedbackFailure(
          error: 'Device ID not found in registry',
          errorType: FeedbackErrorType.missingDeviceId,
          exception: const MissingDeviceIdException(),
        );
      }

      // 2. Call feedback API
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.windowsEndpoint,
        deviceId: deviceId,
      );

      // 3. Login with code
      final loginResult = await _client.loginWithCode(code);

      return FeedbackSuccess(
        feedbackCode: code,
        authData: loginResult.authData,
        config: loginResult.config,
      );
    } on DeviceNotFoundException catch (e) {
      return FeedbackFailure(
        error: e.message,
        errorType: FeedbackErrorType.deviceNotFound,
        exception: e,
      );
    } on NetworkException catch (e) {
      return FeedbackFailure(
        error: e.message,
        errorType: FeedbackErrorType.networkError,
        exception: e,
      );
    } on AuthenticationException catch (e) {
      return FeedbackFailure(
        error: e.message,
        errorType: FeedbackErrorType.authenticationFailed,
        exception: e,
      );
    } catch (e) {
      return FeedbackFailure(
        error: 'Windows feedback failed: ${e.toString()}',
        errorType: FeedbackErrorType.invalidResponse,
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<String?> _readDeviceIdFromRegistry() async {
    try {
      final result = await _channel.invokeMethod<String>('getWindowsDeviceId');
      return result;
    } catch (e) {
      throw FeedbackException('Failed to read device ID from registry: $e', e);
    }
  }
}
