/// Authentication data from feedback login
class FeedbackAuthData {
  final String accessToken;
  final String? refreshToken;
  final String? reportingToken;

  const FeedbackAuthData({
    required this.accessToken,
    this.refreshToken,
    this.reportingToken,
  });

  factory FeedbackAuthData.fromJson(Map<String, dynamic> json) {
    return FeedbackAuthData(
      accessToken: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      reportingToken: json['reportingToken'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': accessToken,
      if (refreshToken != null) 'refreshToken': refreshToken,
      if (reportingToken != null) 'reportingToken': reportingToken,
    };
  }
}

/// Device configuration from feedback response
class DeviceConfig {
  final String? deviceId;
  final String? tenantId;
  final String? enterpriseId;
  final String? userId;
  final String? baseUrl; // For TV/IFP flow
  final Map<String, dynamic>? policy;
  final List<Ref>? refs;

  const DeviceConfig({
    this.deviceId,
    this.tenantId,
    this.enterpriseId,
    this.userId,
    this.baseUrl,
    this.policy,
    this.refs,
  });

  factory DeviceConfig.fromJson(Map<String, dynamic> json) {
    return DeviceConfig(
      deviceId: json['device'] as String?,
      tenantId: json['tenant'] as String?,
      enterpriseId: json['enterprise'] as String?,
      userId: json['user'] as String?,
      baseUrl: json['baseUrl'] as String?,
      policy: json['policy'] as Map<String, dynamic>?,
      refs:
          json['refs'] != null
              ? (json['refs'] as List)
                  .map((e) => Ref.fromJson(e as Map<String, dynamic>))
                  .toList()
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'device': deviceId,
      if (tenantId != null) 'tenant': tenantId,
      if (enterpriseId != null) 'enterprise': enterpriseId,
      if (userId != null) 'user': userId,
      if (baseUrl != null) 'baseUrl': baseUrl,
      if (policy != null) 'policy': policy,
      if (refs != null) 'refs': refs!.map((e) => e.toJson()).toList(),
    };
  }
}

/// Reference data from config
class Ref {
  final String? type;
  final String? value;

  const Ref({this.type, this.value});

  factory Ref.fromJson(Map<String, dynamic> json) {
    return Ref(type: json['type'] as String?, value: json['value'] as String?);
  }

  Map<String, dynamic> toJson() {
    return {if (type != null) 'type': type, if (value != null) 'value': value};
  }
}

/// Device information
class DeviceInfo {
  final String? deviceId;
  final String? deviceType;
  final Map<String, dynamic>? additionalData;

  const DeviceInfo({this.deviceId, this.deviceType, this.additionalData});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) {
    return DeviceInfo(
      deviceId: json['deviceId'] as String?,
      deviceType: json['deviceType'] as String?,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceType != null) 'deviceType': deviceType,
      if (additionalData != null) 'additionalData': additionalData,
    };
  }
}
