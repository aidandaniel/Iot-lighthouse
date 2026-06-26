import 'dart:convert';
import 'dart:io';

import 'package:iot_protector/services/real_atsign_telemetry.dart';

Future<void> main(List<String> args) async {
  final deviceAtSign = _readArg(args, '--device') ?? '@lyra6dj04_sp';
  final companyAtSign = _readArg(args, '--company') ?? '@lyra6dj01_sp';
  final deviceId = _readArg(args, '--device-id') ?? 'diameter-edge-001';
  final keysDirectory = _readArg(args, '--keys-dir') ?? 'local_keys';

  final service = RealAtsignTelemetryService(keysDirectory: keysDirectory);
  final proof = await service.proveDeviceToCompanyEncryption(
    deviceAtSign: deviceAtSign,
    companyAtSign: companyAtSign,
    deviceId: deviceId,
  );

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(proof.toJson()));
  if (!proof.verified) {
    stderr.writeln(proof.error ?? 'Real Atsign telemetry proof failed.');
    exitCode = 1;
  }
}

String? _readArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}
