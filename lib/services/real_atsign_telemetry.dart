import 'dart:convert';
import 'dart:io';

import 'package:at_auth/at_auth.dart';
import 'package:at_client/at_client.dart';

import 'at_keys.dart';

class RealAtsignTelemetryProof {
  const RealAtsignTelemetryProof({
    required this.deviceAtSign,
    required this.companyAtSign,
    required this.deviceId,
    required this.atKeyName,
    required this.plaintext,
    required this.decrypted,
    required this.verified,
    required this.sentAt,
    this.error,
  });

  final String deviceAtSign;
  final String companyAtSign;
  final String deviceId;
  final String atKeyName;
  final String plaintext;
  final String decrypted;
  final bool verified;
  final DateTime sentAt;
  final String? error;

  Map<String, Object?> toJson() => {
        'deviceAtSign': deviceAtSign,
        'companyAtSign': companyAtSign,
        'deviceId': deviceId,
        'atKeyName': atKeyName,
        'plaintext': plaintext,
        'decrypted': decrypted,
        'verified': verified,
        'sentAt': sentAt.toIso8601String(),
        'error': error,
      };

  factory RealAtsignTelemetryProof.fromJson(Map<String, Object?> json) {
    return RealAtsignTelemetryProof(
      deviceAtSign: json['deviceAtSign'] as String,
      companyAtSign: json['companyAtSign'] as String,
      deviceId: json['deviceId'] as String,
      atKeyName: json['atKeyName'] as String,
      plaintext: json['plaintext'] as String? ?? '',
      decrypted: json['decrypted'] as String? ?? '',
      verified: json['verified'] as bool? ?? false,
      sentAt: DateTime.parse(json['sentAt'] as String),
      error: json['error'] as String?,
    );
  }
}

class RealAtsignTelemetryService {
  const RealAtsignTelemetryService({
    this.keysDirectory = 'local_keys',
    this.runtimeDirectory = '.runtime/atsign',
    this.proofPath = 'local_keys/real_atsign_telemetry_proof.json',
  });

  final String keysDirectory;
  final String runtimeDirectory;
  final String proofPath;

  Future<RealAtsignTelemetryProof?> loadLastProof() async {
    final file = File(proofPath);
    if (!file.existsSync()) return null;
    final decoded = jsonDecode(await file.readAsString());
    return RealAtsignTelemetryProof.fromJson(
      Map<String, Object?>.from(decoded as Map),
    );
  }

  Future<RealAtsignTelemetryProof> proveDeviceToCompanyEncryption({
    String deviceAtSign = '@lyra6dj04_sp',
    String companyAtSign = '@lyra6dj01_sp',
    String deviceId = 'diameter-edge-001',
  }) async {
    final sentAt = DateTime.now().toUtc();
    final runId = 'run-${sentAt.microsecondsSinceEpoch}-$pid';
    final readingId = 'real-${sentAt.microsecondsSinceEpoch}';
    final keyName = 'telemetry.$deviceId.$readingId';
    final payload = jsonEncode({
      'deviceId': deviceId,
      'source': 'real-atsign-atkey',
      'protocol': 'diameter',
      'packetLossPercent': 2.4,
      'signalStrength': -61,
      'status': 'normal',
      'recordedAt': sentAt.toIso8601String(),
      'from': deviceAtSign,
      'to': companyAtSign,
    });

    try {
      final deviceClient = await _clientFor(deviceAtSign, runId: runId);
      final writeKey = AtKey()
        ..key = keyName
        ..namespace = appNamespace
        ..sharedWith = companyAtSign;

      await deviceClient.put(
        writeKey,
        payload,
        putRequestOptions: PutRequestOptions()..useRemoteAtServer = true,
      );

      AtClientManager.getInstance().reset();

      final companyClient = await _clientFor(companyAtSign, runId: runId);
      final readKey = AtKey()
        ..key = keyName
        ..namespace = appNamespace
        ..sharedBy = deviceAtSign
        ..sharedWith = companyAtSign;

      final result = await companyClient.get(
        readKey,
        getRequestOptions: GetRequestOptions()
          ..bypassCache = true
          ..useRemoteAtServer = true,
      );
      final decrypted = result.value?.toString() ?? '';
      final proof = RealAtsignTelemetryProof(
        deviceAtSign: deviceAtSign,
        companyAtSign: companyAtSign,
        deviceId: deviceId,
        atKeyName: '$keyName.$appNamespace',
        plaintext: payload,
        decrypted: decrypted,
        verified: decrypted == payload,
        sentAt: sentAt,
      );
      await _saveProof(proof);
      return proof;
    } on Exception catch (error) {
      final proof = RealAtsignTelemetryProof(
        deviceAtSign: deviceAtSign,
        companyAtSign: companyAtSign,
        deviceId: deviceId,
        atKeyName: '$keyName.$appNamespace',
        plaintext: payload,
        decrypted: '',
        verified: false,
        sentAt: sentAt,
        error: error.toString(),
      );
      await _saveProof(proof);
      return proof;
    } finally {
      AtClientManager.getInstance().reset();
    }
  }

  Future<AtClient> _clientFor(String atSign, {required String runId}) async {
    final keyPath = _keyPathFor(atSign);
    if (!File(keyPath).existsSync()) {
      throw StateError('Missing .atKeys file for $atSign at $keyPath');
    }

    final safeAtSign = atSign.substring(1).replaceAll(RegExp(r'\W+'), '_');
    final storagePath = '$runtimeDirectory/$runId/$safeAtSign';
    await Directory(storagePath).create(recursive: true);

    final prefs = AtClientPreference()
      ..rootDomain = AtRootDomain.atsignDomain.rootDomain
      ..rootPort = AtRootDomain.atsignDomain.rootPort
      ..namespace = appNamespace
      ..hiveStoragePath = storagePath
      ..commitLogPath = storagePath;

    final authRequest = AtAuthRequest(
      atSign,
      atKeysIo: FileAtKeysIo(filePath: (_) => keyPath),
      rootDomain: AtRootDomain.atsignDomain,
    );
    final response = await AtAuth.create().authenticate(authRequest);
    if (!response.isSuccessful) {
      throw StateError('Authentication failed for $atSign');
    }

    await AtClientManager.getInstance().setCurrentAtSign(
      response.atSign,
      appNamespace,
      prefs,
      enrollmentId: response.enrollmentId,
      atChops: response.atChops,
      atLookUp: response.atLookUp,
    );
    return AtClientManager.getInstance().atClient;
  }

  String _keyPathFor(String atSign) {
    final safeAtSign = atSign.substring(1).replaceAll(RegExp(r'\W+'), '_');
    return '$keysDirectory/$safeAtSign.atKeys';
  }

  Future<void> _saveProof(RealAtsignTelemetryProof proof) async {
    final file = File(proofPath);
    await file.parent.create(recursive: true);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(proof.toJson()),
    );
  }
}
