import Flutter
import UIKit

public class HaloFeedbackPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "halo_feedback", binaryMessenger: registrar.messenger())
    let instance = HaloFeedbackPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "getMDMConfig":
      // Get MDM configuration from UserDefaults
      if let config = UserDefaults.standard.dictionary(forKey: "com.apple.configuration.managed") {
        result(config)
      } else {
        result([String: Any]())
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
