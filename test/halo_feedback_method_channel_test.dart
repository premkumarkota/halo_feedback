import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:halo_feedback/halo_feedback_method_channel.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  MethodChannelHaloFeedback platform = MethodChannelHaloFeedback();
  const MethodChannel channel = MethodChannel('halo_feedback');

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'getPlatformVersion':
              return '42';
            case 'getAndroidData':
              return {'randomId': 'test-id', 'deviceType': 'Mobile'};
            case 'getMDMConfig':
              return {'CERT_ID': 'test-cert-id'};
            case 'getWindowsDeviceId':
              return 'test-device-id';
            case 'sendKeyedAppStateFeedback':
              return null;
            default:
              return null;
          }
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('getPlatformVersion', () async {
    expect(await platform.getPlatformVersion(), '42');
  });

  test('getAndroidData', () async {
    final result = await platform.getAndroidData();
    expect(result['randomId'], 'test-id');
    expect(result['deviceType'], 'Mobile');
  });

  test('getMDMConfig', () async {
    final result = await platform.getMDMConfig();
    expect(result['CERT_ID'], 'test-cert-id');
  });

  test('getWindowsDeviceId', () async {
    final result = await platform.getWindowsDeviceId();
    expect(result, 'test-device-id');
  });

  test('sendKeyedAppStateFeedback', () async {
    await platform.sendKeyedAppStateFeedback('TTEMM_APP', 'test-message');
    // Should not throw
  });
}
