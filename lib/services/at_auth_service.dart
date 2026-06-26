import 'package:at_auth/at_auth.dart';
import 'package:at_client_flutter/at_client_flutter.dart';
import 'package:at_client_flutter/extensions.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'at_keys.dart';

final KeychainStorage keychainStorage = KeychainStorage();

const _registrarApiKey = String.fromEnvironment('ATSIGN_REGISTRAR_API_KEY');

final RegistrarService registrar = RegistrarService(
  registrarUrl: 'my.atsign.com',
  apiKey: _registrarApiKey,
);

class AtAuthService {
  Future<List<String>> getExistingAtSigns() => keychainStorage.getAllAtsigns();

  Future<void> loginWithKeychain(BuildContext context) async {
    await _safe(context, () async {
      final atSigns = await keychainStorage.getAllAtsigns();
      if (!context.mounted) return;
      if (atSigns.isEmpty) {
        _showMessage(context, 'No Atsigns are available in the keychain.');
        return;
      }
      final request = await AtSignSelectionDialog.show(
        context,
        existingAtSigns: atSigns,
      );
      if (request == null || !context.mounted) return;

      request.atSign.toAtsign();
      final authRequest = AtAuthRequest(
        request.atSign,
        atKeysIo: KeychainAtKeysIo(),
        rootDomain: request.rootDomain,
      );
      final response = await PkamDialog.show(
        context,
        request: authRequest,
        backupKeys: [KeychainAtKeysIo()],
      );
      if (response != null && response.isSuccessful && context.mounted) {
        await setupAtClient(context, authRequest, response);
      }
    });
  }

  Future<void> onboard(BuildContext context) async {
    await _safe(context, () async {
      final request = await AtSignSelectionDialog.show(context);
      if (request == null || !context.mounted) return;

      request.atSign.toAtsign();
      final cramKey = await RegistrarCramDialog.show(
        context,
        request as AtOnboardingRequest,
        registrar: registrar,
      );
      if (cramKey == null || !context.mounted) return;

      final response = await CramDialog.show(
        context,
        request: request,
        cramKey: cramKey,
      );
      if (response != null && response.isSuccessful && context.mounted) {
        await setupAtClient(context, request, response);
      }
    });
  }

  Future<void> loginWithApkam(BuildContext context) async {
    await _safe(context, () async {
      final request = await AtSignSelectionDialog.show(context);
      if (request == null || !context.mounted) return;

      request.atSign.toAtsign();
      final enrollmentResponse = await ApkamActivationDialog.show(
        context,
        atSign: request.atSign,
        rootDomain: request.rootDomain,
        appName: appNamespace,
        deviceName: 'operator-console',
        namespaces: {appNamespace: 'rw'},
      );
      if (!context.mounted) return;
      if (enrollmentResponse?.atAuthKeys == null) {
        _showMessage(context, 'APKAM enrollment was not completed.');
        return;
      }

      final authRequest = AtAuthRequest(
        request.atSign,
        atAuthKeys: enrollmentResponse!.atAuthKeys!,
        rootDomain: request.rootDomain,
      );
      final response = await PkamDialog.show(
        context,
        request: authRequest,
        backupKeys: [KeychainAtKeysIo()],
      );
      if (response != null && response.isSuccessful && context.mounted) {
        await setupAtClient(context, authRequest, response);
      }
    });
  }

  Future<void> loginWithAtKeysFile(BuildContext context) async {
    await _safe(context, () async {
      final atKeysIo = await AtKeysFileDialog.show(context);
      if (atKeysIo == null || !context.mounted) return;

      final atSign = atKeysIo.getAtsign();
      atSign.toAtsign();
      final authRequest = AtAuthRequest(
        atSign,
        atKeysIo: atKeysIo,
        rootDomain: AtRootDomain.atsignDomain,
      );
      final response = await PkamDialog.show(
        context,
        request: authRequest,
        backupKeys: [KeychainAtKeysIo()],
      );
      if (response != null && response.isSuccessful && context.mounted) {
        await setupAtClient(context, authRequest, response);
      }
    });
  }

  Future<void> setupAtClient(
    BuildContext context,
    AuthRequest authRequest,
    AuthResponse response,
  ) async {
    response.atSign.toAtsign();
    final dir = await getApplicationSupportDirectory();
    final prefs = AtClientPreference()
      ..rootDomain = authRequest.rootDomain.rootDomain
      ..rootPort = authRequest.rootDomain.rootPort
      ..namespace = appNamespace
      ..hiveStoragePath = dir.path
      ..commitLogPath = dir.path;

    await AtClientManager.getInstance().setCurrentAtSign(
      response.atSign,
      appNamespace,
      prefs,
      enrollmentId: response.enrollmentId,
      atChops: response.atChops,
      atLookUp: response.atLookUp,
    );
  }

  Future<String?> saveAtKeysFile() async {
    final atSign = AtClientManager.getInstance()
        .atClient
        .getCurrentAtSign()
        ?.toAtsign()
        .toString();
    if (atSign == null) return null;

    String? outputPath = await FilePicker.saveFile(
      dialogTitle: 'Export Atsign keys',
      fileName: '${atSign}_key.atKeys',
      type: FileType.custom,
      allowedExtensions: ['atKeys'],
    );
    if (outputPath == null) return null;
    if (!outputPath.endsWith('.atKeys')) outputPath = '$outputPath.atKeys';

    final atKeys = await keychainStorage.getAtsign(atSign);
    if (atKeys == null) return null;
    FileAtKeysIo(filePath: (_) => outputPath!).write(atSign, atKeys);
    return outputPath;
  }

  Future<void> _safe(
    BuildContext context,
    Future<void> Function() operation,
  ) async {
    try {
      await operation();
    } on Exception catch (error) {
      if (context.mounted) {
        _showMessage(context, error.toString());
      }
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
