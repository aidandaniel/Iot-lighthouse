import 'dart:io';

import 'package:at_auth/at_auth.dart';

Future<void> main(List<String> args) async {
  final atSigns = _readAtSigns(args);
  final outputDir = _readArg(args, '--out') ?? 'local_keys';

  if (atSigns.isEmpty) {
    stderr.writeln('Missing --atsign, --atsigns, or ATSIGN.');
    exitCode = 64;
    return;
  }

  var failures = 0;
  for (final atSign in atSigns) {
    final normalizedAtSign =
        atSign.startsWith('@') ? atSign.trim() : '@${atSign.trim()}';
    final cram = _readCramFor(normalizedAtSign);
    if (cram == null || cram.trim().isEmpty) {
      stderr.writeln('Missing CRAM secret for $normalizedAtSign.');
      failures += 1;
      continue;
    }

    final safeName =
        normalizedAtSign.substring(1).replaceAll(RegExp(r'\W+'), '_');
    final outputPath = '$outputDir/$safeName.atKeys';

    try {
      final request = AtOnboardingRequest(
        normalizedAtSign,
        atKeysIo: FileAtKeysIo(filePath: (_) => outputPath),
      )
        ..appName = 'iotlighthouse'
        ..deviceName = 'operator-console';

      final response = await AtAuth.create().onboard(request, cram.trim());
      stdout.writeln('Activated ${response.atSign}');
      stdout.writeln('Keys written to $outputPath');
    } on Exception catch (error) {
      failures += 1;
      stderr.writeln('Failed to activate $normalizedAtSign: $error');
    }
  }

  if (failures > 0) exitCode = 1;
}

String? _readArg(List<String> args, String name) {
  for (var i = 0; i < args.length; i += 1) {
    final arg = args[i];
    if (arg == name && i + 1 < args.length) return args[i + 1];
    if (arg.startsWith('$name=')) return arg.substring(name.length + 1);
  }
  return null;
}

List<String> _readAtSigns(List<String> args) {
  final explicitList =
      _readArg(args, '--atsigns') ?? Platform.environment['ATSIGNS'];
  if (explicitList != null && explicitList.trim().isNotEmpty) {
    return explicitList
        .split(',')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toList();
  }
  final single = _readArg(args, '--atsign') ?? Platform.environment['ATSIGN'];
  if (single == null || single.trim().isEmpty) return const [];
  return [single.trim()];
}

String? _readCramFor(String atSign) {
  final key = atSign
      .replaceFirst('@', '')
      .toUpperCase()
      .replaceAll(RegExp(r'\W+'), '_');
  return Platform.environment['ATSIGN_CRAM_$key'] ??
      Platform.environment['ATSIGN_CRAM_SECRET'];
}
