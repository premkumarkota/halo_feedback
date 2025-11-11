## 0.0.4

* **Enhanced Logging System**: Added comprehensive logging with both `developer.log` and `print` statements for better visibility in console output
* **Re-initialization Support**: Plugin now allows re-initialization to update callbacks, enabling flexible callback configuration in different app screens
* **Improved Error Handling**: Added detailed stack trace logging in exception handlers for better debugging
* **Debug-Friendly Output**: All plugin operations now log to console with clear prefixes (`[HaloFeedback]`) for easy filtering
* **Native Implementation Updates**:
  * iOS: Added `getMDMConfig` method to plugin's native Swift implementation
  * Windows: Added `getWindowsDeviceId` method with registry reading from HKEY_USERS and HKEY_LOCAL_MACHINE
  * Android: Enhanced MainActivity to support both `my_native_plugin` and `halo_feedback` method channels
* **Better Integration**: Improved integration with existing apps by allowing callback updates without full re-initialization
* **Flow Type Logging**: Added detailed logging for different feedback flows (Mobile, TV/IFP, iOS, Windows)
* **Execution Tracking**: Added debug prints at key execution points to track plugin flow
* **Verbose Logging Control**: Added `verboseLogging` flag in `FeedbackLogger` for controlling log output
* **Platform Detection Logging**: Enhanced platform detection with visible console output
* **Success/Failure Visibility**: All success and failure results are now printed to console for immediate visibility

## 0.0.3

* **Production Integration**: Complete integration example with `halo-files` application
* **Boilerplate Removal**: Removed all feedback-related boilerplate code from end-user applications
* **Simplified API**: Single `executeFeedback()` call handles all platform-specific flows automatically
* **Callback-Based Navigation**: Full navigation control through `FeedbackCallbacks` for seamless UI integration
* **MainActivity Enhancement**: Added support for plugin's method channel alongside existing native channels
* **Android ID Logging**: Added Android ID to native data for comprehensive device information logging

## 0.0.2

* **Enhanced Android Support**: Added support for Android TV/IFP devices with Content Provider and Intent data handling
* **Improved iOS/macOS**: Enhanced MDM config retrieval with better retry logic and saved UDID support
* **Production-Ready**: Complete feedback flow implementation for all platforms (Android Mobile/TV/IFP, iOS/macOS, Windows)
* **Native Data Support**: Added `nativeData` parameter to `executeFeedback()` for passing platform-specific data
* **TV/IFP Flow**: Automatic detection and handling of TV/IFP devices with pre-provided tokens (skips feedback API)
* **Better Error Handling**: Improved error messages and exception handling across all platforms
* **API Compatibility**: Fixed API response parsing to handle both 'config' and 'conifg' (typo) fields
* **DeviceConfig Enhancement**: Added `baseUrl` field to DeviceConfig for TV/IFP flow support
* **Code Quality**: Removed boilerplate code, unified all feedback flows through plugin

## 0.0.1

* Initial release of halo_feedback plugin
* Cross-platform MDM feedback mechanism for Flutter
* Support for Android, iOS, macOS, and Windows
* Unified API for device authentication
* Configurable base URLs and app identifiers with flavor support
* Built-in retry logic for network requests
* Comprehensive error handling with specific error types
* Storage abstraction with default implementation
* Android Enterprise KeyedAppState support
* iOS/macOS MDM profile integration
* Windows Registry device ID reading
* Callback-based navigation system
* Comprehensive logging for debugging
* Example app included
