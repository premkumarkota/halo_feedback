import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:halo_feedback/halo_feedback.dart';
import 'package:halo_feedback/halo_feedback_platform_interface.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await HaloFeedbackPlatform.instance.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Halo Feedback Plugin Example')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Running on: $_platformVersion'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Example: Initialize and execute feedback
                  _executeFeedback();
                },
                child: const Text('Execute Feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _executeFeedback() async {
    if (!mounted) return;

    try {
      // Initialize plugin
      await HaloFeedback.instance.initialize(
        config: FeedbackConfig(
          baseUrl: 'https://portal.qa.halofort.com',
          appIdentifier: 'files',
        ),
      );

      // Execute feedback
      final result = await HaloFeedback.instance.executeFeedback();

      if (!mounted) return;

      result.when(
        success: (data) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Success! Device ID: ${data.config.deviceId ?? "N/A"}',
              ),
            ),
          );
        },
        failure: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${error.error}'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exception: $e'), backgroundColor: Colors.red),
      );
    }
  }
}
