import 'package:dio/dio.dart';
import '../exceptions/feedback_exceptions.dart';
import '../models/feedback_data.dart';
import 'feedback_config.dart';

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
    final url = '${_config.baseUrl}/$endpoint/$deviceId';
    final queryParams = appIdentifier != null ? {'app': appIdentifier} : null;

    int attempt = 0;
    while (attempt < _config.retryConfig.maxAttempts) {
      try {
        final response = await _dio.get(url, queryParameters: queryParams);

        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map &&
              data['status'] == 'success' &&
              data['data'] != null) {
            return data['data'].toString();
          }
        }
      } catch (e) {
        if (e is DioException && e.response?.statusCode == 400) {
          final errorData = e.response?.data;
          if (errorData is Map &&
              errorData['error'] == 'device not found' &&
              _config.retryConfig.stopOnDeviceNotFound) {
            throw const DeviceNotFoundException(
              'Device not found in the system',
            );
          }
        }

        if (attempt < _config.retryConfig.maxAttempts - 1) {
          await Future.delayed(_config.retryConfig.delay);
        } else {
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
    final url = '${_config.baseUrl}/${_config.endpoints.loginEndpoint}';

    try {
      final response = await _dio.post(
        url,
        data: {'code': code},
        options: Options(headers: {'Content-Type': 'application/json'}),
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
        rethrow;
      }
      throw AuthenticationException('Login failed: ${e.toString()}');
    }
  }
}
