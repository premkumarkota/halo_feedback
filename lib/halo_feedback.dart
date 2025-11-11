import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Core - Import for internal use
import 'src/core/feedback_config.dart';
import 'src/core/feedback_result.dart';
import 'src/core/feedback_client.dart';
import 'src/core/feedback_callbacks.dart';

// Models
import 'src/models/feedback_data.dart';

// Storage
import 'src/storage/feedback_storage.dart';

// Platform Handlers
import 'src/platform/android_feedback_handler.dart';
import 'src/platform/ios_feedback_handler.dart';
import 'src/platform/windows_feedback_handler.dart';

// Exceptions
import 'src/exceptions/feedback_exceptions.dart';

// Export for public API
export 'src/core/feedback_config.dart';
export 'src/core/feedback_result.dart';
export 'src/core/feedback_client.dart';
export 'src/core/feedback_callbacks.dart';
export 'src/models/feedback_data.dart';
export 'src/storage/feedback_storage.dart';
export 'src/platform/android_feedback_handler.dart';
export 'src/platform/ios_feedback_handler.dart';
export 'src/platform/windows_feedback_handler.dart';
export 'src/exceptions/feedback_exceptions.dart';

/// Main plugin class for Halo Feedback
class HaloFeedback {
  static HaloFeedback? _instance;
  static HaloFeedback get instance => _instance ??= HaloFeedback._();

  HaloFeedback._();

  // Configuration
  FeedbackConfig? _config;
  FeedbackStorage? _storage;
  FeedbackCallbacks? _callbacks;
  bool _initialized = false;

  // Platform handlers
  AndroidFeedbackHandler? _androidHandler;
  IosFeedbackHandler? _iosHandler;
  WindowsFeedbackHandler? _windowsHandler;

  /// Initialize the plugin
  ///
  /// [config] - Configuration with base URL and app identifier
  /// [storage] - Optional custom storage implementation
  /// [callbacks] - Optional callbacks for navigation and UI updates
  ///
  /// Example:
  /// ```dart
  /// await HaloFeedback.instance.initialize(
  ///   config: FeedbackConfig.fromFlavor('qa', appIdentifier: 'files'),
  ///   callbacks: FeedbackCallbacks(
  ///     onSuccess: (context, data) => Navigator.pushReplacement(...),
  ///     onFailure: (context, error) => Navigator.pushReplacement(...),
  ///   ),
  /// );
  /// ```
  Future<void> initialize({
    required FeedbackConfig config,
    FeedbackStorage? storage,
    FeedbackCallbacks? callbacks,
  }) async {
    if (_initialized) {
      throw InvalidConfigurationException('Plugin already initialized');
    }

    _config = config;
    _storage =
        storage ??
        DefaultFeedbackStorage(await SharedPreferences.getInstance());
    _callbacks = callbacks;

    // Initialize Dio client
    final dio = Dio();

    // Initialize platform handlers
    if (Platform.isAndroid) {
      _androidHandler = AndroidFeedbackHandler(
        config,
        FeedbackClient(dio, config),
      );
    } else if (Platform.isIOS || Platform.isMacOS) {
      _iosHandler = IosFeedbackHandler(config, FeedbackClient(dio, config));
    } else if (Platform.isWindows) {
      _windowsHandler = WindowsFeedbackHandler(
        config,
        FeedbackClient(dio, config),
      );
    }

    // Save base URL
    await _storage!.saveBaseUrl(config.baseUrl);

    _initialized = true;
  }

  /// Execute feedback flow
  ///
  /// [context] - BuildContext for navigation callbacks (optional)
  /// [deviceId] - Optional device ID override
  /// [nativeData] - Optional native data (for Android TV/IFP flow)
  /// [customData] - Optional custom data to pass
  ///
  /// Returns [FeedbackResult] which can be handled with `.when()` pattern
  ///
  /// If callbacks are configured, they will be called automatically.
  /// Otherwise, handle the result manually using `.when()`.
  ///
  /// Example with callbacks:
  /// ```dart
  /// await HaloFeedback.instance.executeFeedback(context: context);
  /// ```
  ///
  /// Example without callbacks:
  /// ```dart
  /// final result = await HaloFeedback.instance.executeFeedback();
  /// result.when(
  ///   success: (data) => Navigator.pushReplacement(...),
  ///   failure: (error) => showErrorDialog(...),
  /// );
  /// ```
  Future<FeedbackResult> executeFeedback({
    BuildContext? context,
    String? deviceId,
    Map<String, dynamic>? nativeData,
    Map<String, dynamic>? customData,
  }) async {
    if (!_initialized || _config == null) {
      throw InvalidConfigurationException(
        'Plugin not initialized. Call initialize() first.',
      );
    }

    // Call onStart callback if provided
    if (context != null && _callbacks?.onStart != null) {
      _callbacks!.onStart!(context);
    }

    FeedbackResult result;

    try {
      // Platform detection and routing
      if (Platform.isAndroid) {
        if (_androidHandler == null) {
          throw UnsupportedPlatformException('Android handler not initialized');
        }
        result = await _androidHandler!.execute(
          deviceId: deviceId,
          nativeData: nativeData,
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        if (_iosHandler == null) {
          throw UnsupportedPlatformException(
            'iOS/macOS handler not initialized',
          );
        }
        result = await _iosHandler!.execute(deviceId: deviceId);
      } else if (Platform.isWindows) {
        if (_windowsHandler == null) {
          throw UnsupportedPlatformException('Windows handler not initialized');
        }
        result = await _windowsHandler!.execute();
      } else {
        throw UnsupportedPlatformException(
          'Platform ${Platform.operatingSystem} is not supported',
        );
      }

      // Handle success (save data)
      await _handleSuccess(result);

      // Call callbacks if provided
      if (context != null && context.mounted) {
        result.when(
          success: (data) {
            if (context.mounted) {
              _callbacks?.onSuccess?.call(context, data);
            }
          },
          failure: (error) {
            if (context.mounted) {
              _callbacks?.onFailure?.call(context, error);
            }
          },
        );
      }

      // Call onComplete callback
      if (context != null &&
          context.mounted &&
          _callbacks?.onComplete != null) {
        _callbacks!.onComplete!(context);
      }

      return result;
    } catch (e) {
      // Create failure result for exceptions
      result = FeedbackFailure(
        error: e.toString(),
        errorType: FeedbackErrorType.invalidResponse,
        exception: e is Exception ? e : Exception(e.toString()),
      );

      // Call failure callback
      if (context != null && context.mounted) {
        _callbacks?.onFailure?.call(context, result as FeedbackFailure);
      }

      // Call onComplete callback
      if (context != null &&
          context.mounted &&
          _callbacks?.onComplete != null) {
        _callbacks!.onComplete!(context);
      }

      return result;
    }
  }

  /// Handle successful feedback result
  Future<void> _handleSuccess(FeedbackResult result) async {
    if (result is FeedbackSuccess && _storage != null) {
      // Save authentication data
      await _storage!.saveToken(result.authData.accessToken);
      if (result.authData.refreshToken != null) {
        await _storage!.saveRefreshToken(result.authData.refreshToken);
      }

      // Save device configuration
      if (result.config.deviceId != null) {
        await _storage!.saveDeviceId(result.config.deviceId!);
      }
      if (result.config.tenantId != null) {
        await _storage!.saveTenantId(result.config.tenantId);
      }
      if (result.config.baseUrl != null) {
        await _storage!.saveBaseUrl(result.config.baseUrl!);
      }
      await _storage!.saveDeviceConfig(result.config);
    }
  }

  /// Get device information
  Future<DeviceInfo> getDeviceInfo() async {
    if (!_initialized) {
      throw InvalidConfigurationException('Plugin not initialized');
    }

    // This would call platform-specific method to get device info
    // For now, return basic info from storage
    final deviceId = await _storage?.getDeviceId();
    return DeviceInfo(deviceId: deviceId, deviceType: Platform.operatingSystem);
  }

  /// Clear all stored data
  Future<void> clear() async {
    await _storage?.clear();
  }

  /// Check if plugin is initialized
  bool get isInitialized => _initialized;
}
