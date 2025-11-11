import 'package:dio/dio.dart';
import '../exceptions/feedback_exceptions.dart';
import '../models/feedback_data.dart';
import 'feedback_config.dart';
import 'feedback_logger.dart';

/// HTTP client for feedback API calls
class FeedbackClient {
  final Dio _dio;
  final FeedbackConfig _config;

  FeedbackClient(this._dio, this._config);

  /// Get feedback code from server
  Future<String> getFeedbackCode({
    required String endpoint,
    required String deviceId,
    String? appIdentifier,
  }) async {
    final queryString = appIdentifier != null ? 'app=$appIdentifier' : null;

    // Log API URL construction
    FeedbackLogger.logApiUrl(
      baseUrl: _config.baseUrl,
      endpoint: endpoint,
      deviceId: deviceId,
      appIdentifier: appIdentifier,
      queryParams: queryString,
      platform: _getPlatformFromEndpoint(endpoint),
    );

    int attempt = 0;
    while (attempt < _config.retryConfig.maxAttempts) {
      try {
        final url = '${_config.baseUrl}/$endpoint/$deviceId';
        final queryParams =
            appIdentifier != null ? {'app': appIdentifier} : null;

        if (attempt > 0) {
          FeedbackLogger.logRetry(
            attempt: attempt + 1,
            maxAttempts: _config.retryConfig.maxAttempts,
            reason: 'Previous attempt failed',
          );
        }

        final response = await _dio.get(url, queryParameters: queryParams);

        // Log API response
        FeedbackLogger.logApiResponse(
          statusCode: response.statusCode,
          response: response.data,
          endpoint: endpoint,
          platform: _getPlatformFromEndpoint(endpoint),
        );

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map &&
              data['status'] == 'success' &&
              data['data'] != null) {
            final code = data['data'].toString();
            FeedbackLogger.logSuccess(
              feedbackCode: code,
              deviceId: deviceId,
              tenantId: null,
              baseUrl: _config.baseUrl,
              platform: null,
            );
            return code;
          }
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is Map &&
              errorData['error'] == 'device not found' &&
              _config.retryConfig.stopOnDeviceNotFound) {
            FeedbackLogger.logFailure(
              error: 'Device not found in the system',
              errorType: 'DeviceNotFound',
              platform: null,
              details: 'Device ID: $deviceId',
            );
            throw const DeviceNotFoundException(
              'Device not found in the system',
            );
          }
        }

        if (attempt < _config.retryConfig.maxAttempts - 1) {
          await Future.delayed(_config.retryConfig.delay);
        } else {
          FeedbackLogger.logFailure(
            error:
                'Failed to fetch feedback code after ${_config.retryConfig.maxAttempts} attempts',
            errorType: 'NetworkError',
            platform: null,
            details: e.toString(),
          );
          throw NetworkException(
            'Failed to fetch feedback code after ${_config.retryConfig.maxAttempts} attempts',
            e is DioException ? e.response?.statusCode : null,
          );
        }
      }
      attempt++;
    }

    throw NetworkException(
      'Failed to fetch feedback code after ${_config.retryConfig.maxAttempts} attempts',
    );
  }

  /// Login with feedback code
  Future<({FeedbackAuthData authData, DeviceConfig config})> loginWithCode(
    String code,
  ) async {
    // Log login API call
    FeedbackLogger.logLoginApi(
      baseUrl: _config.baseUrl,
      endpoint: _config.endpoints.loginEndpoint,
      code: code,
      platform: 'All Platforms', // Login API is same for all platforms
    );

    final url = '${_config.baseUrl}/${_config.endpoints.loginEndpoint}';

    try {
      final response = await _dio.post(
        url,
        data: {'code': code},
        options: Options(headers: {'Content-Type': 'application/json'}),
      );

      // Log API response
      FeedbackLogger.logApiResponse(
        statusCode: response.statusCode,
        response: response.data,
        endpoint: _config.endpoints.loginEndpoint,
        platform: 'All Platforms',
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map && data['status'] == 'success') {
          final responseData = data['data'] as Map<String, dynamic>?;
          if (responseData == null) {
            throw const AuthenticationException(
              'Invalid login response: missing data',
            );
          }

          final authData = FeedbackAuthData.fromJson(responseData);
          // Note: API returns 'conifg' (typo in API), but we handle both
          final configData =
              (responseData['config'] as Map<String, dynamic>?) ??
              (responseData['conifg'] as Map<String, dynamic>?);
          final config =
              configData != null
                  ? DeviceConfig.fromJson(configData)
                  : const DeviceConfig();

          if (authData.accessToken.isEmpty) {
            throw const AuthenticationException(
              'Invalid login response: missing token',
            );
          }

          return (authData: authData, config: config);
        }
      }

      throw const AuthenticationException('Invalid login response');
    } catch (e) {
      if (e is AuthenticationException || e is DeviceNotFoundException) {
        FeedbackLogger.logFailure(
          error: e.toString(),
          errorType: 'AuthenticationFailed',
          platform: null,
          details: 'Login API call failed',
        );
        rethrow;
      }
      FeedbackLogger.logFailure(
        error: 'Login failed: ${e.toString()}',
        errorType: 'NetworkError',
        platform: null,
        details: e.toString(),
      );
      throw AuthenticationException('Login failed: ${e.toString()}');
    }
  }

  /// Helper to determine platform from endpoint
  String? _getPlatformFromEndpoint(String endpoint) {
    if (endpoint.contains('android')) return 'Android';
    if (endpoint.contains('ios')) return 'iOS/macOS';
    if (endpoint.contains('win')) return 'Windows';
    return null;
  }
}
