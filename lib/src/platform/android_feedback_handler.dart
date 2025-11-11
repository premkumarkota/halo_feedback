import 'dart:io';
import 'package:flutter/services.dart';
import '../core/feedback_client.dart';
import '../core/feedback_config.dart';
import '../core/feedback_result.dart';
import '../exceptions/feedback_exceptions.dart';
import '../models/feedback_data.dart';

/// Android Feedback Handler
class AndroidFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  static const MethodChannel _channel = MethodChannel('halo_feedback');

  AndroidFeedbackHandler(this._config, this._client);

  Future<FeedbackResult> execute({String? deviceId}) async {
    try {
      // 1. Get device ID from native
      final nativeData = await _getNativeData();
      final randomId = nativeData['randomId'] as String? ?? deviceId;

      if (randomId == null || randomId.isEmpty) {
        return FeedbackFailure(
          error: 'Missing device ID',
          errorType: FeedbackErrorType.missingDeviceId,
          exception: const MissingDeviceIdException(),
        );
      }

      // 2. Send Android Enterprise feedback (KeyedAppStates)
      await _sendKeyedAppStateFeedback(randomId);

      // 3. Call feedback API
      final code = await _client.getFeedbackCode(
        endpoint: _config.endpoints.androidEndpoint,
        deviceId: randomId,
        appIdentifier: _config.appIdentifier,
      );

      // 4. Login with code
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
        error: 'Android feedback failed: ${e.toString()}',
        errorType: FeedbackErrorType.invalidResponse,
        exception: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  Future<Map<String, dynamic>> _getNativeData() async {
    try {
      final result = await _channel.invokeMethod<Map>('getAndroidData');
      return result?.cast<String, dynamic>() ?? {};
    } catch (e) {
      throw FeedbackException('Failed to get native data: $e', e);
    }
  }

  Future<void> _sendKeyedAppStateFeedback(String randomId) async {
    try {
      await _channel.invokeMethod('sendKeyedAppStateFeedback', {
        'key': 'TTEMM_APP',
        'message': randomId,
      });
    } catch (e) {
      // Log but don't fail - KeyedAppState is optional
      print('Warning: Failed to send KeyedAppState feedback: $e');
    }
  }
}
