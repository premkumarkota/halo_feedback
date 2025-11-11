// This is a basic Flutter integration test.
//
// Since integration tests run in a full Flutter application, they can interact
// with the host side of a plugin implementation, unlike Dart unit tests.
//
// For more information about Flutter integration tests, please see
// https://flutter.dev/to/integration-testing

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:halo_feedback/halo_feedback.dart';
import 'package:halo_feedback/halo_feedback_platform_interface.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getPlatformVersion test', (WidgetTester tester) async {
    final String? version = await HaloFeedbackPlatform.instance.getPlatformVersion();
    // The version string depends on the host platform running the test, so
    // just assert that some non-empty string is returned.
    expect(version?.isNotEmpty, true);
  });

  testWidgets('HaloFeedback singleton test', (WidgetTester tester) async {
    final instance1 = HaloFeedback.instance;
    final instance2 = HaloFeedback.instance;
    expect(instance1, same(instance2));
    expect(instance1.isInitialized, false);
  });
}
