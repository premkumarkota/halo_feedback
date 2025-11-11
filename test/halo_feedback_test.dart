import 'package:flutter_test/flutter_test.dart';
import 'package:halo_feedback/halo_feedback.dart';
import 'package:halo_feedback/halo_feedback_platform_interface.dart';
import 'package:halo_feedback/halo_feedback_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHaloFeedbackPlatform
    with MockPlatformInterfaceMixin
    implements HaloFeedbackPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map<String, dynamic>> getAndroidData() async {
    return {'randomId': 'test-android-id', 'deviceType': 'Mobile'};
  }

  @override
  Future<void> sendKeyedAppStateFeedback(String key, String message) async {
    // Mock implementation
  }

  @override
  Future<Map<String, dynamic>> getMDMConfig() async {
    return {'CERT_ID': 'test-cert-id'};
  }

  @override
  Future<String?> getWindowsDeviceId() async {
    return 'test-windows-device-id';
  }
}

void main() {
  final HaloFeedbackPlatform initialPlatform = HaloFeedbackPlatform.instance;

  test('$MethodChannelHaloFeedback is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHaloFeedback>());
  });

  test('getPlatformVersion', () async {
    MockHaloFeedbackPlatform fakePlatform = MockHaloFeedbackPlatform();
    HaloFeedbackPlatform.instance = fakePlatform;

    final version = await HaloFeedbackPlatform.instance.getPlatformVersion();
    expect(version, '42');
  });

  test('HaloFeedback is a singleton', () {
    final instance1 = HaloFeedback.instance;
    final instance2 = HaloFeedback.instance;
    expect(instance1, same(instance2));
  });

  test('HaloFeedback isInitialized returns false initially', () {
    final plugin = HaloFeedback.instance;
    expect(plugin.isInitialized, false);
  });
}
