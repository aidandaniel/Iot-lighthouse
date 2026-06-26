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

  Future<void> onboardWithManualCram(BuildContext context) async {
    await _safe(context, () async {
      final request = await AtSignSelectionDialog.show(context);
      if (request == null || !context.mounted) return;

      request.atSign.toAtsign();
      final cramKey = await _ManualCramDialog.show(context, request.atSign);
      if (cramKey == null || cramKey.trim().isEmpty || !context.mounted) {
        return;
      }

      final response = await CramDialog.show(
        context,
        request: request as AtOnboardingRequest,
        cramKey: cramKey.trim(),
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
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ManualCramDialog extends StatefulWidget {
  const _ManualCramDialog({required this.atSign});

  final String atSign;

  static Future<String?> show(BuildContext context, String atSign) {
    return showDialog<String>(
      context: context,
      builder: (_) => _ManualCramDialog(atSign: atSign),
    );
  }

  @override
  State<_ManualCramDialog> createState() => _ManualCramDialogState();
}

class _ManualCramDialogState extends State<_ManualCramDialog> {
  final _controller = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Activate ${widget.atSign}'),
      content: TextField(
        controller: _controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          labelText: 'CRAM key',
          helperText: 'Paste the key from Advanced Settings.',
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show key' : 'Hide key',
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
          ),
        ),
        onSubmitted: (_) => Navigator.of(context).pop(_controller.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Activate'),
        ),
      ],
    );
  }
}
