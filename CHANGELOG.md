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
