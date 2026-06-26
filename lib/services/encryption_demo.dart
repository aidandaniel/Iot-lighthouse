import 'dart:convert';

import 'package:crypto/crypto.dart';

class EncryptionProof {
  const EncryptionProof({
    required this.fromAtSign,
    required this.toAtSign,
    required this.plaintext,
    required this.ciphertext,
    required this.digest,
    required this.decrypted,
    required this.verified,
  });

  final String fromAtSign;
  final String toAtSign;
  final String plaintext;
  final String ciphertext;
  final String digest;
  final String decrypted;
  final bool verified;
}

class EncryptionDemoService {
  const EncryptionDemoService();

  EncryptionProof proveTelemetryEncryption({
    required String fromAtSign,
    required String toAtSign,
    required String deviceId,
  }) {
    final plaintext = jsonEncode({
      'deviceId': deviceId,
      'packetLossPercent': 2.8,
      'signalStrength': -62,
      'status': 'normal',
      'recordedAt': DateTime.now().toUtc().toIso8601String(),
    });
    final key = _deriveDemoKey(fromAtSign, toAtSign);
    final encryptedBytes = _xor(utf8.encode(plaintext), key);
    final ciphertext = base64UrlEncode(encryptedBytes);
    final digest = hmacSha256(key, ciphertext);
    final decrypted = utf8.decode(_xor(base64Url.decode(ciphertext), key));
    final verified = digest == hmacSha256(key, ciphertext);

    return EncryptionProof(
      fromAtSign: fromAtSign,
      toAtSign: toAtSign,
      plaintext: plaintext,
      ciphertext: ciphertext,
      digest: digest,
      decrypted: decrypted,
      verified: verified && decrypted == plaintext,
    );
  }

  List<int> _deriveDemoKey(String fromAtSign, String toAtSign) {
    final seed = 'iot-lighthouse|$fromAtSign|$toAtSign';
    return sha256.convert(utf8.encode(seed)).bytes;
  }

  List<int> _xor(List<int> input, List<int> key) {
    return [
      for (var i = 0; i < input.length; i += 1) input[i] ^ key[i % key.length],
    ];
  }
}

String hmacSha256(List<int> key, String value) {
  final hmac = Hmac(sha256, key);
  return hmac.convert(utf8.encode(value)).toString();
}
