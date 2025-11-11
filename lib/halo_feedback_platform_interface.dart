import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'halo_feedback_method_channel.dart';

abstract class HaloFeedbackPlatform extends PlatformInterface {
  /// Constructs a HaloFeedbackPlatform.
  HaloFeedbackPlatform() : super(token: _token);

  static final Object _token = Object();

  static HaloFeedbackPlatform _instance = MethodChannelHaloFeedback();

  /// The default instance of [HaloFeedbackPlatform] to use.
  ///
  /// Defaults to [MethodChannelHaloFeedback].
  static HaloFeedbackPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HaloFeedbackPlatform] when
  /// they register themselves.
  static set instance(HaloFeedbackPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Get Android device data (randomId, deviceType, etc.)
  Future<Map<String, dynamic>> getAndroidData() {
    throw UnimplementedError('getAndroidData() has not been implemented.');
  }

  /// Send KeyedAppState feedback for Android Enterprise
  Future<void> sendKeyedAppStateFeedback(String key, String message) {
    throw UnimplementedError(
      'sendKeyedAppStateFeedback() has not been implemented.',
    );
  }

  /// Get MDM config for iOS/macOS
  Future<Map<String, dynamic>> getMDMConfig() {
    throw UnimplementedError('getMDMConfig() has not been implemented.');
  }

  /// Get Windows device ID from registry
  Future<String?> getWindowsDeviceId() {
    throw UnimplementedError('getWindowsDeviceId() has not been implemented.');
  }
}
