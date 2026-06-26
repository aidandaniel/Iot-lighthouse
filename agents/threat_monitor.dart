import 'dart:async';
import 'dart:convert';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:iot_protector/models/device_models.dart';
import 'package:iot_protector/services/at_keys.dart';
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final atClient = (await CLIBase.fromCommandLineArgs(args)).atClient;
  final monitor = ThreatMonitor(atClient);
  await monitor.start();
}

class ThreatMonitor {
  ThreatMonitor(this._atClient);

  final AtClient _atClient;
  final _uuid = const Uuid();

  Future<void> start() async {
    _atClient.notificationService
        .subscribe(regex: 'telemetry\\..*\\.$appNamespace@.*', shouldDecrypt: true)
        .listen(_handleTelemetry);
    await Completer<void>().future;
  }

  Future<void> _handleTelemetry(AtNotification notification) async {
    final raw = notification.value;
    if (raw == null || raw.isEmpty) return;

    final reading = TelemetryReading.fromJson(
      Map<String, Object?>.from(jsonDecode(raw) as Map),
    );
    final alert = _assess(reading);
    if (alert == null) return;

    final alertKey = IotKeys.alert(alert.id);
    await _atClient.put(
      alertKey,
      jsonEncode(alert.toJson()),
      putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
    );
    await _appendAlert(alert);
    if (alert.severity == AlertSeverity.critical) {
      await _requestIsolation(alert.deviceId);
    }
  }

  SecurityAlert? _assess(TelemetryReading reading) {
    if (reading.packetLossPercent >= 45 || reading.status == 'tampered') {
      return SecurityAlert(
        id: _uuid.v4(),
        deviceId: reading.deviceId,
        severity: AlertSeverity.critical,
        title: 'Possible compromise on ${reading.deviceId}',
        assessment:
            'The device is reporting severe packet loss or tamper status, which can indicate interception, firmware abuse, or physical access.',
        recommendedFix:
            'Isolate the device, rotate credentials, inspect firmware, and verify the communications module.',
        createdAt: DateTime.now().toUtc(),
      );
    }
    if (reading.temperatureC > 85 || reading.packetLossPercent >= 20) {
      return SecurityAlert(
        id: _uuid.v4(),
        deviceId: reading.deviceId,
        severity: AlertSeverity.warning,
        title: 'Anomalous telemetry from ${reading.deviceId}',
        assessment:
            'The telemetry pattern is outside normal operating thresholds and may point to degraded hardware or an aging network method.',
        recommendedFix:
            'Schedule maintenance, check signal quality, and update device software if available.',
        createdAt: DateTime.now().toUtc(),
      );
    }
    return null;
  }

  Future<void> _appendAlert(SecurityAlert alert) async {
    final key = IotKeys.alertFeed();
    final alerts = <SecurityAlert>[];
    try {
      final current = await _atClient.get(
        key,
        getRequestOptions: GetRequestOptions()..bypassCache = true,
      );
      if (current.value != null && current.value.toString().isNotEmpty) {
        alerts.addAll(SecurityAlert.listFromJson(current.value.toString()));
      }
    } on Exception {
      // Start a new feed if the shared feed has not been created yet.
    }
    alerts.insert(0, alert);
    await _atClient.put(
      key,
      SecurityAlert.listToJson(alerts.take(100).toList()),
      putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
    );
  }

  Future<void> _requestIsolation(String deviceId) async {
    await _atClient.notificationService.notify(
      NotificationParams.forUpdate(
        IotKeys.protectionCommand(deviceId, sharedWith: protectionServiceAtSign),
        value: jsonEncode({
          'deviceId': deviceId,
          'state': ProtectionState.isolated.name,
          'reason': 'critical-threat-monitor-alert',
          'sentAt': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
  }
}
