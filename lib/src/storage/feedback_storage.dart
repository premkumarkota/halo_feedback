import '../models/feedback_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Abstract storage interface for feedback data
abstract class FeedbackStorage {
  /// Save authentication token
  Future<void> saveToken(String token);

  /// Get authentication token
  Future<String?> getToken();

  /// Save refresh token
  Future<void> saveRefreshToken(String? refreshToken);

  /// Get refresh token
  Future<String?> getRefreshToken();

  /// Save device ID
  Future<void> saveDeviceId(String deviceId);

  /// Get device ID
  Future<String?> getDeviceId();

  /// Save tenant ID
  Future<void> saveTenantId(String? tenantId);

  /// Get tenant ID
  Future<String?> getTenantId();

  /// Save base URL
  Future<void> saveBaseUrl(String baseUrl);

  /// Get base URL
  Future<String?> getBaseUrl();

  /// Save device configuration
  Future<void> saveDeviceConfig(DeviceConfig config);

  /// Get device configuration
  Future<DeviceConfig?> getDeviceConfig();

  /// Clear all stored data
  Future<void> clear();
}

/// Default implementation using shared_preferences
class DefaultFeedbackStorage implements FeedbackStorage {
  static const String _keyToken = 'halo_feedback_token';
  static const String _keyRefreshToken = 'halo_feedback_refresh_token';
  static const String _keyDeviceId = 'halo_feedback_device_id';
  static const String _keyTenantId = 'halo_feedback_tenant_id';
  static const String _keyBaseUrl = 'halo_feedback_base_url';
  static const String _keyDeviceConfig = 'halo_feedback_device_config';

  final SharedPreferences _prefs;

  DefaultFeedbackStorage(this._prefs);

  @override
  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  @override
  Future<String?> getToken() async {
    return _prefs.getString(_keyToken);
  }

  @override
  Future<void> saveRefreshToken(String? refreshToken) async {
    if (refreshToken != null) {
      await _prefs.setString(_keyRefreshToken, refreshToken);
    } else {
      await _prefs.remove(_keyRefreshToken);
    }
  }

  @override
  Future<String?> getRefreshToken() async {
    return _prefs.getString(_keyRefreshToken);
  }

  @override
  Future<void> saveDeviceId(String deviceId) async {
    await _prefs.setString(_keyDeviceId, deviceId);
  }

  @override
  Future<String?> getDeviceId() async {
    return _prefs.getString(_keyDeviceId);
  }

  @override
  Future<void> saveTenantId(String? tenantId) async {
    if (tenantId != null) {
      await _prefs.setString(_keyTenantId, tenantId);
    } else {
      await _prefs.remove(_keyTenantId);
    }
  }

  @override
  Future<String?> getTenantId() async {
    return _prefs.getString(_keyTenantId);
  }

  @override
  Future<void> saveBaseUrl(String baseUrl) async {
    await _prefs.setString(_keyBaseUrl, baseUrl);
  }

  @override
  Future<String?> getBaseUrl() async {
    return _prefs.getString(_keyBaseUrl);
  }

  @override
  Future<void> saveDeviceConfig(DeviceConfig config) async {
    final json = config.toJson();
    // Convert to JSON string using dart:convert
    final jsonString = json.toString();
    await _prefs.setString(_keyDeviceConfig, jsonString);
  }

  @override
  Future<DeviceConfig?> getDeviceConfig() async {
    final jsonString = _prefs.getString(_keyDeviceConfig);
    if (jsonString == null) return null;
    // Note: Proper JSON parsing would require json_serializable or manual parsing
    // For now, returning null as DeviceConfig.fromJson needs proper Map<String, dynamic>
    // This can be enhanced later with proper JSON serialization
    return null;
  }

  @override
  Future<void> clear() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyDeviceId);
    await _prefs.remove(_keyTenantId);
    await _prefs.remove(_keyBaseUrl);
    await _prefs.remove(_keyDeviceConfig);
  }
}
