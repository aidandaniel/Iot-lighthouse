import 'dart:async';
import 'dart:convert';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:iot_protector/models/device_models.dart';
import 'package:iot_protector/services/at_keys.dart';
import 'package:uuid/uuid.dart';

Future<void> main(List<String> args) async {
  final atClient = (await CLIBase.fromCommandLineArgs(args)).atClient;
  atClient.getCurrentAtSign()?.toAtsign();

  final service = DeviceProtectionService(atClient);
  await service.start();
}

class DeviceProtectionService {
  DeviceProtectionService(this._atClient);

  final AtClient _atClient;
  final _uuid = const Uuid();

  Future<void> start() async {
    _atClient.notificationService
        .subscribe(regex: '.*\\.$appNamespace@.*', shouldDecrypt: true)
        .listen(_handleNotification, onError: (Object error) {
      // Keep the process alive; the SDK monitor reconnects subscriptions.
    });
    await Completer<void>().future;
  }

  Future<void> _handleNotification(AtNotification notification) async {
    try {
      final requestId = notification.id.isEmpty ? _uuid.v4() : notification.id;
      final wonMutex = await _atClient.put(
        IotKeys.mutex(requestId),
        DateTime.now().toUtc().toIso8601String(),
        putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
      );
      if (!wonMutex) return;

      final value = notification.value;
      if (value == null || value.isEmpty) return;
      final payload = jsonDecode(value) as Map<String, Object?>;
      final action = payload['action'] as String?;
      final body = Map<String, Object?>.from(payload['body'] as Map? ?? {});

      switch (action) {
        case 'import':
          await _appendTrace('fleet', 'Imported ${body['count']} devices');
        case 'vulnerability_report':
          await _appendTrace(
            body['deviceId']?.toString() ?? 'unknown',
            'Vulnerability report requested',
          );
        default:
          await _handleProtectionCommand(notification);
      }
    } on AtClientException catch (error) {
      await _appendTrace('service', 'AtClient error: $error');
    } on FormatException {
      await _handleProtectionCommand(notification);
    }
  }

  Future<void> _handleProtectionCommand(AtNotification notification) async {
    final value = notification.value;
    if (value == null || value.isEmpty) return;
    final payload = jsonDecode(value) as Map<String, Object?>;
    final deviceId = payload['deviceId']?.toString();
    final stateName = payload['state']?.toString();
    if (deviceId == null || stateName == null) return;

    final devices = await _loadDevices();
    final state = ProtectionState.values.byName(stateName);
    final updated = [
      for (final device in devices)
        if (device.id == deviceId) device.copyWith(protectionState: state) else device,
    ];
    await _saveDevices(updated);
    await _appendTrace(deviceId, 'Protection changed to ${state.name}');
    await _sendDeviceCommand(deviceId, state);
  }

  Future<List<ProtectedDevice>> _loadDevices() async {
    try {
      final result = await _atClient.get(
        IotKeys.deviceRegistry(),
        getRequestOptions: GetRequestOptions()..bypassCache = true,
      );
      if (result.value == null || result.value.toString().isEmpty) return [];
      return ProtectedDevice.listFromJson(result.value.toString());
    } on Exception {
      return [];
    }
  }

  Future<void> _saveDevices(List<ProtectedDevice> devices) async {
    await _atClient.put(
      IotKeys.deviceRegistry(),
      ProtectedDevice.listToJson(devices),
      putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
    );
  }

  Future<void> _appendTrace(String deviceId, String event) async {
    final key = IotKeys.traceLog(deviceId);
    final current = await _readJsonList(key);
    current.add({
      'event': event,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
    await _atClient.put(
      key,
      jsonEncode(current),
      putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
    );
  }

  Future<List<Map<String, Object?>>> _readJsonList(AtKey key) async {
    try {
      final value = await _atClient.get(
        key,
        getRequestOptions: GetRequestOptions()..bypassCache = true,
      );
      if (value.value == null || value.value.toString().isEmpty) return [];
      return (jsonDecode(value.value.toString()) as List)
          .map((item) => Map<String, Object?>.from(item as Map))
          .toList();
    } on Exception {
      return [];
    }
  }

  Future<void> _sendDeviceCommand(String deviceId, ProtectionState state) async {
    final devices = await _loadDevices();
    final match = devices.where((device) => device.id == deviceId).firstOrNull;
    if (match == null) return;
    match.deviceAtSign.toAtsign();
    await _atClient.notificationService.notify(
      NotificationParams.forUpdate(
        IotKeys.protectionCommand(deviceId, sharedWith: match.deviceAtSign),
        value: jsonEncode({
          'deviceId': deviceId,
          'state': state.name,
          'sentAt': DateTime.now().toUtc().toIso8601String(),
        }),
      ),
    );
  }
}
