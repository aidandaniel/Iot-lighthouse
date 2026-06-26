import 'dart:convert';

import 'package:at_client/at_client.dart';

import '../models/device_models.dart';
import 'at_keys.dart';

class IotProtectorRepository {
  IotProtectorRepository(this._atClient);

  final AtClient _atClient;

  Future<List<ProtectedDevice>> loadDevices() async {
    try {
      final value = await _atClient.get(
        IotKeys.deviceRegistry(sharedWith: protectionServiceAtSign),
        getRequestOptions: GetRequestOptions()..bypassCache = true,
      );
      if (value.value == null || value.value.toString().isEmpty) return [];
      return ProtectedDevice.listFromJson(value.value.toString());
    } on Exception {
      return [];
    }
  }

  Future<void> saveDevices(List<ProtectedDevice> devices) async {
    final payload = ProtectedDevice.listToJson(devices);
    await _atClient.put(
      IotKeys.deviceRegistry(sharedWith: protectionServiceAtSign),
      payload,
      putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
    );
  }

  Future<void> importDevices(List<ProtectedDevice> devices) async {
    final current = await loadDevices();
    final byId = {for (final device in current) device.id: device};
    for (final device in devices) {
      device.deviceAtSign.toAtsign();
      byId[device.id] = device;
    }
    await saveDevices(byId.values.toList());
    await notifyService('import', {'count': devices.length});
  }

  Future<void> toggleProtection(
    ProtectedDevice device,
    ProtectionState state,
  ) async {
    final payload = jsonEncode({
      'deviceId': device.id,
      'state': state.name,
      'requestedAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _atClient.notificationService.notify(
      NotificationParams.forUpdate(
        IotKeys.protectionCommand(
          device.id,
          sharedWith: protectionServiceAtSign,
        ),
        value: payload,
      ),
    );
  }

  Future<List<SecurityAlert>> loadAlerts() async {
    try {
      final value = await _atClient.get(
        IotKeys.alertFeed(sharedWith: threatMonitorAtSign),
        getRequestOptions: GetRequestOptions()..bypassCache = true,
      );
      if (value.value == null || value.value.toString().isEmpty) return [];
      return SecurityAlert.listFromJson(value.value.toString());
    } on Exception {
      return [];
    }
  }

  Future<void> requestVulnerabilityReport(String deviceId) {
    return notifyService('vulnerability_report', {'deviceId': deviceId});
  }

  Future<void> notifyService(String action, Map<String, Object?> body) async {
    final payload = jsonEncode({
      'action': action,
      'body': body,
      'sentAt': DateTime.now().toUtc().toIso8601String(),
    });
    await _atClient.notificationService.notify(
      NotificationParams.forUpdate(
        IotKeys.companyProfile(sharedWith: protectionServiceAtSign),
        value: payload,
      ),
    );
  }
}
