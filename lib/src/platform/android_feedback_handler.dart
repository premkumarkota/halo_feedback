import 'dart:developer' as developer;
import 'package:flutter/services.dart';
import '../core/feedback_client.dart';
import '../core/feedback_config.dart';
import '../core/feedback_result.dart';
import '../exceptions/feedback_exceptions.dart';
import '../models/feedback_data.dart';

/// Android Feedback Handler
/// Handles both Mobile and TV/IFP flows
class AndroidFeedbackHandler {
  final FeedbackConfig _config;
  final FeedbackClient _client;
  static const MethodChannel _channel = MethodChannel('halo_feedback');

  AndroidFeedbackHandler(this._config, this._client);

  /// Execute feedback flow for Android
  ///
  /// For Mobile: Gets randomId, sends KeyedAppState, calls feedback API, then login
  /// For TV/IFP: Gets token from Content Provider/Intent, skips feedback API
  Future<FeedbackResult> execute({
    String? deviceId,
    Map<String, dynamic>? nativeData,
  }) async {
    try {
      // Get native data if not provided
      final data = nativeData ?? await _getNativeData();
      final deviceType = data['deviceType'] as String?;

      // Handle TV/IFP flow (skip feedback API, use pre-provided token)
      if (deviceType != null && deviceType != 'Mobile') {
        return await _handleTvIfpFlow(data);
      }

      // Handle Mobile flow
      return await _handleMobileFlow(data, deviceId);
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

  /// Handle Mobile Android flow
  Future<FeedbackResult> _handleMobileFlow(
    Map<String, dynamic> nativeData,
    String? deviceId,
  ) async {
    final randomId = nativeData['randomId'] as String? ?? deviceId;

    if (randomId == null || randomId.isEmpty) {
      return FeedbackFailure(
        error: 'Missing device ID',
        errorType: FeedbackErrorType.missingDeviceId,
        exception: const MissingDeviceIdException(),
      );
    }

    // 1. Send Android Enterprise feedback (KeyedAppStates)
    await _sendKeyedAppStateFeedback(randomId);

    // 2. Call feedback API
    final code = await _client.getFeedbackCode(
      endpoint: _config.endpoints.androidEndpoint,
      deviceId: randomId,
      appIdentifier: _config.appIdentifier,
    );

    // 3. Login with code
    final loginResult = await _client.loginWithCode(code);

    return FeedbackSuccess(
      feedbackCode: code,
      authData: loginResult.authData,
      config: loginResult.config,
    );
  }

  /// Handle TV/IFP flow (Content Provider or Intent data)
  Future<FeedbackResult> _handleTvIfpFlow(
    Map<String, dynamic> nativeData,
  ) async {
    // Try intentData first, then contentProviderData
    final intentData = nativeData['intentData'] as Map<dynamic, dynamic>?;
    final contentProviderData =
        nativeData['contentProviderData'] as Map<dynamic, dynamic>?;

    // Get token from intent or content provider
    final token =
        (intentData?['message'] as String?)?.isNotEmpty == true
            ? intentData!['message'] as String
            : contentProviderData?['token'] as String?;

    final deviceId =
        (intentData?['deviceId'] as String?)?.isNotEmpty == true
            ? intentData!['deviceId'] as String
            : contentProviderData?['deviceId'] as String?;

    final baseUrl =
        (intentData?['baseUrl'] as String?)?.isNotEmpty == true
            ? intentData!['baseUrl'] as String
            : contentProviderData?['baseUrl'] as String?;

    final tenant =
        (intentData?['tenant'] as String?)?.isNotEmpty == true
            ? intentData!['tenant'] as String
            : contentProviderData?['tenant'] as String?;

    final refreshToken = contentProviderData?['refreshToken'] as String?;

    if (token == null || token.isEmpty) {
      return FeedbackFailure(
        error: 'Missing authentication token for TV/IFP device',
        errorType: FeedbackErrorType.authenticationFailed,
        exception: const AuthenticationException(
          'Token not found in Content Provider or Intent',
        ),
      );
    }

    // For TV/IFP, we return success with the pre-provided token
    // No need to call feedback API
    return FeedbackSuccess(
      feedbackCode: null, // No feedback code for TV/IFP
      authData: FeedbackAuthData(
        accessToken: token,
        refreshToken: refreshToken,
      ),
      config: DeviceConfig(
        deviceId: deviceId,
        tenantId: tenant,
        baseUrl: baseUrl,
      ),
    );
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
      developer.log(
        'Warning: Failed to send KeyedAppState feedback: $e',
        name: 'HaloFeedback',
      );
    }
  }
}
