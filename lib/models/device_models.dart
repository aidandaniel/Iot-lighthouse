import 'dart:convert';

enum ProtectionState { enabled, disabled, isolated }

enum AlertSeverity { info, warning, critical }

class ProtectedDevice {
  const ProtectedDevice({
    required this.id,
    required this.label,
    required this.deviceAtSign,
    required this.protectionState,
    required this.source,
    this.lastReading,
    this.lastSeen,
    this.firmwareVersion,
    this.protocol,
  });

  final String id;
  final String label;
  final String deviceAtSign;
  final ProtectionState protectionState;
  final String source;
  final TelemetryReading? lastReading;
  final DateTime? lastSeen;
  final String? firmwareVersion;
  final String? protocol;

  ProtectedDevice copyWith({
    String? id,
    String? label,
    String? deviceAtSign,
    ProtectionState? protectionState,
    String? source,
    TelemetryReading? lastReading,
    DateTime? lastSeen,
    String? firmwareVersion,
    String? protocol,
  }) {
    return ProtectedDevice(
      id: id ?? this.id,
      label: label ?? this.label,
      deviceAtSign: deviceAtSign ?? this.deviceAtSign,
      protectionState: protectionState ?? this.protectionState,
      source: source ?? this.source,
      lastReading: lastReading ?? this.lastReading,
      lastSeen: lastSeen ?? this.lastSeen,
      firmwareVersion: firmwareVersion ?? this.firmwareVersion,
      protocol: protocol ?? this.protocol,
    );
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'label': label,
        'deviceAtSign': deviceAtSign,
        'protectionState': protectionState.name,
        'source': source,
        'lastReading': lastReading?.toJson(),
        'lastSeen': lastSeen?.toIso8601String(),
        'firmwareVersion': firmwareVersion,
        'protocol': protocol,
      };

  factory ProtectedDevice.fromJson(Map<String, Object?> json) {
    return ProtectedDevice(
      id: json['id'] as String,
      label: json['label'] as String,
      deviceAtSign: json['deviceAtSign'] as String,
      protectionState: ProtectionState.values.byName(
        json['protectionState'] as String? ?? ProtectionState.disabled.name,
      ),
      source: json['source'] as String? ?? 'manual',
      lastReading: json['lastReading'] == null
          ? null
          : TelemetryReading.fromJson(
              Map<String, Object?>.from(json['lastReading'] as Map),
            ),
      lastSeen: json['lastSeen'] == null
          ? null
          : DateTime.parse(json['lastSeen'] as String),
      firmwareVersion: json['firmwareVersion'] as String?,
      protocol: json['protocol'] as String?,
    );
  }

  static List<ProtectedDevice> listFromJson(String value) {
    final decoded = jsonDecode(value) as List;
    return decoded
        .map((item) => ProtectedDevice.fromJson(Map<String, Object?>.from(item)))
        .toList();
  }

  static String listToJson(List<ProtectedDevice> devices) {
    return jsonEncode(devices.map((device) => device.toJson()).toList());
  }
}

class TelemetryReading {
  const TelemetryReading({
    required this.deviceId,
    required this.recordedAt,
    required this.signalStrength,
    required this.temperatureC,
    required this.packetLossPercent,
    required this.status,
  });

  final String deviceId;
  final DateTime recordedAt;
  final double signalStrength;
  final double temperatureC;
  final double packetLossPercent;
  final String status;

  Map<String, Object?> toJson() => {
        'deviceId': deviceId,
        'recordedAt': recordedAt.toIso8601String(),
        'signalStrength': signalStrength,
        'temperatureC': temperatureC,
        'packetLossPercent': packetLossPercent,
        'status': status,
      };

  factory TelemetryReading.fromJson(Map<String, Object?> json) {
    return TelemetryReading(
      deviceId: json['deviceId'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      signalStrength: (json['signalStrength'] as num).toDouble(),
      temperatureC: (json['temperatureC'] as num).toDouble(),
      packetLossPercent: (json['packetLossPercent'] as num).toDouble(),
      status: json['status'] as String,
    );
  }
}

class SecurityAlert {
  const SecurityAlert({
    required this.id,
    required this.deviceId,
    required this.severity,
    required this.title,
    required this.assessment,
    required this.recommendedFix,
    required this.createdAt,
  });

  final String id;
  final String deviceId;
  final AlertSeverity severity;
  final String title;
  final String assessment;
  final String recommendedFix;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
        'id': id,
        'deviceId': deviceId,
        'severity': severity.name,
        'title': title,
        'assessment': assessment,
        'recommendedFix': recommendedFix,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SecurityAlert.fromJson(Map<String, Object?> json) {
    return SecurityAlert(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      severity: AlertSeverity.values.byName(json['severity'] as String),
      title: json['title'] as String,
      assessment: json['assessment'] as String,
      recommendedFix: json['recommendedFix'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  static List<SecurityAlert> listFromJson(String value) {
    final decoded = jsonDecode(value) as List;
    return decoded
        .map((item) => SecurityAlert.fromJson(Map<String, Object?>.from(item)))
        .toList();
  }

  static String listToJson(List<SecurityAlert> alerts) {
    return jsonEncode(alerts.map((alert) => alert.toJson()).toList());
  }
}
