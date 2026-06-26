import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:at_cli_commons/at_cli_commons.dart';
import 'package:at_client/at_client.dart';
import 'package:iot_protector/models/device_models.dart';
import 'package:iot_protector/services/at_keys.dart';

Future<void> main(List<String> args) async {
  final cli = await CLIBase.fromCommandLineArgs(args);
  final atClient = cli.atClient;
  final atSign = atClient.getCurrentAtSign()?.toAtsign().toString();
  final deviceId = args.isNotEmpty ? args.last : atSign ?? 'device';
  await DeviceSimulator(atClient, deviceId).start();
}

class DeviceSimulator {
  DeviceSimulator(this._atClient, this.deviceId);

  final AtClient _atClient;
  final String deviceId;
  final _random = Random();

  Future<void> start() async {
    Timer.periodic(const Duration(seconds: 10), (_) => _publishReading());
    _atClient.notificationService
        .subscribe(regex: 'command\\.$deviceId\\.protection\\.$appNamespace@.*')
        .listen((notification) {
      final command = notification.value;
      if (command != null) {
        // Real devices would flip local protection controls here.
      }
    });
    await Completer<void>().future;
  }

  Future<void> _publishReading() async {
    final reading = TelemetryReading(
      deviceId: deviceId,
      recordedAt: DateTime.now().toUtc(),
      signalStrength: -40 - _random.nextDouble() * 30,
      temperatureC: 25 + _random.nextDouble() * 70,
      packetLossPercent: _random.nextDouble() * 50,
      status: _random.nextInt(30) == 0 ? 'tampered' : 'normal',
    );
    await _atClient.notificationService.notify(
      NotificationParams.forUpdate(
        IotKeys.telemetry(
          deviceId,
          reading.recordedAt.millisecondsSinceEpoch.toString(),
          sharedWith: protectionServiceAtSign,
        ),
        value: jsonEncode(reading.toJson()),
      ),
    );
  }
}
