import 'dart:io';
import 'package:flutter/services.dart';
import '../core/feedback_client.dart';
import '../core/feedback_config.dart';
import '../core/feedback_result.dart';
import '../exceptions/feedback_exceptions.dart';
import '../models/feedback_data.dart';

/// iOS/macOS Feedback Handler
class IosFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  static const MethodChannel _channel = MethodChannel('halo_feedback');

  IosFeedbackHandler(this._config, this._client);

  Future<FeedbackResult> execute({String? deviceId}) async {
    try {
      // 1. Get MDM config
      final mdmConfig = await _getMdmConfig();
      final certId = mdmConfig['CERT_ID'] as String? ?? deviceId;

      if (certId == null || certId.isEmpty) {
        return FeedbackFailure(
          error: 'Missing CERT_ID',
          errorType: FeedbackErrorType.missingDeviceId,
          exception: const MissingDeviceIdException(),
        );
      }

      // 2. Call feedback API
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
