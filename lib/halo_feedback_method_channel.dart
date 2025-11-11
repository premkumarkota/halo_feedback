import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'halo_feedback_platform_interface.dart';

/// An implementation of [HaloFeedbackPlatform] that uses method channels.
class MethodChannelHaloFeedback extends HaloFeedbackPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('halo_feedback');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<Map<String, dynamic>> getAndroidData() async {
    final result = await methodChannel.invokeMethod<Map>('getAndroidData');
    return result?.cast<String, dynamic>() ?? {};
  }

  @override
  Future<void> sendKeyedAppStateFeedback(String key, String message) async {
    await methodChannel.invokeMethod('sendKeyedAppStateFeedback', {
      'key': key,
      'message': message,
    });
  }

  @override
  Future<Map<String, dynamic>> getMDMConfig() async {
    final result = await methodChannel.invokeMethod<Map>('getMDMConfig');
    return result?.cast<String, dynamic>() ?? {};
  }

  @override
  Future<String?> getWindowsDeviceId() async {
    final result = await methodChannel.invokeMethod<String>(
      'getWindowsDeviceId',
    );
    return result;
  }
}
