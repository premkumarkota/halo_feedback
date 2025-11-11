import 'package:flutter/services.dart';
import '../core/feedback_client.dart';
import '../core/feedback_config.dart';
import '../core/feedback_result.dart';
import '../exceptions/feedback_exceptions.dart';

/// iOS/macOS Feedback Handler
class IosFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  static const MethodChannel _channel = MethodChannel('halo_feedback');

  IosFeedbackHandler(this._config, this._client);

  Future<FeedbackResult> execute({String? deviceId}) async {
    try {
      String? certId = deviceId;

      // If deviceId is provided (from saved UDID), use it directly
      // Otherwise, get from MDM config with retry logic (3 attempts, 700ms delay)
      if (certId == null || certId.isEmpty) {
        try {
          final mdmConfig = await _getMdmConfig();
          certId = mdmConfig['CERT_ID'] as String?;
        } catch (e) {
          // If MDM config retrieval fails, return failure
          return FeedbackFailure(
            error: 'Failed to retrieve MDM configuration: ${e.toString()}',
            errorType: FeedbackErrorType.missingDeviceId,
            exception: MissingDeviceIdException('MDM config retrieval failed'),
          );
        }
      }

      if (certId == null || certId.isEmpty) {
        return FeedbackFailure(
          error:
              'Missing CERT_ID or device UDID. Please ensure device is enrolled in MDM.',
          errorType: FeedbackErrorType.missingDeviceId,
          exception: const MissingDeviceIdException(),
        );
      }

      // 2. Call feedback API with retry logic (handled by FeedbackClient)
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.iosEndpoint,
        deviceId: certId,
        appIdentifier: _config.appIdentifier,
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
        error: 'iOS/macOS feedback failed: ${e.toString()}',
        errorType: FeedbackErrorType.invalidResponse,
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<Map<String, dynamic>> _getMdmConfig() async {
    try {
      // Retry logic for MDM config (as per original implementation)
      const int maxAttempts = 3;
      for (int attempt = 1; attempt <= maxAttempts; attempt++) {
        try {
          final result = await _channel.invokeMethod<Map>('getMDMConfig');
          if (result != null) {
            return result.cast<String, dynamic>();
          }
        } catch (e) {
          if (attempt < maxAttempts) {
            await Future.delayed(const Duration(milliseconds: 700));
          } else {
            rethrow;
          }
        }
      }
      return {};
    } catch (e) {
      throw FeedbackException('Failed to get MDM config: $e', e);
    }
  }
}
