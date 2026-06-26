import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/device_models.dart';
import '../services/at_auth_service.dart';
import '../services/encryption_demo.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../services/telemetry_monitor.dart';
import 'device_telemetry_screen.dart';
import 'device_traceability_screen.dart';
import 'telemetry_widgets.dart';

const _starterPackUrl = 'https://my.atsign.com/starterpack_app';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.operatorAtSign});

  final String operatorAtSign;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _authService = AtAuthService();
  final List<ProtectedDevice> _devices = [];
  final List<SecurityAlert> _alerts = [
    SecurityAlert(
      id: 'alert-demo-001',
      deviceId: 'routing-firewall-001',
      severity: AlertSeverity.critical,
      title: 'Diameter/SS7 routing anomaly detected',
      assessment:
          'The signaling node is using an aging route profile with abnormal packet loss. This can indicate weak Diameter fallback, SS7 exposure, or route tamper.',
      recommendedFix:
          'Keep the node isolated, rotate credentials, verify routing policy, and schedule firmware inspection.',
      createdAt: DateTime.now().toUtc(),
    ),
  ];
  final _encryptionDemo = const EncryptionDemoService();
  final _monitor = TelemetryMonitor();
  EncryptionProof? _proof;
  List<String> _keychainAtSigns = const [];
  bool _imported = false;

  @override
  void initState() {
    super.initState();
    _refreshKeychain();
    _monitor.addListener(_onTelemetryUpdate);
  }

  @override
  void dispose() {
    _monitor.removeListener(_onTelemetryUpdate);
    _monitor.dispose();
    super.dispose();
  }

  void _onTelemetryUpdate() {
    if (!mounted) return;
    setState(_syncDevicesFromMonitor);
  }

  void _syncDevicesFromMonitor() {
    for (var i = 0; i < _devices.length; i += 1) {
      final latest = _monitor.latestFor(_devices[i].id);
      if (latest == null) continue;
      _devices[i] = _devices[i].copyWith(
        lastReading: latest,
        lastSeen: latest.recordedAt,
      );
    }
  }

  Future<void> _refreshKeychain() async {
    final atSigns = await _authService.getExistingAtSigns();
    if (!mounted) return;
    setState(() => _keychainAtSigns = atSigns);
  }

  Future<void> _runAuthAction(Future<void> Function() action) async {
    await action();
    if (!mounted) return;
    await _refreshKeychain();
  }

  Future<void> _exportCurrentKeys() async {
    final path = await _authService.saveAtKeysFile();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          path == null ? 'No active atSign keys to export.' : 'Saved $path',
        ),
      ),
    );
  }

  Future<void> _createNewAtSign() async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a new atSign'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Use the Atsign Starter Pack to create a new atSign, then return here and activate it with the CRAM key from Advanced Settings.',
            ),
            SizedBox(height: 12),
            SelectableText(_starterPackUrl),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(const ClipboardData(text: _starterPackUrl));
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Starter Pack URL copied.')),
              );
            },
            child: const Text('Copy URL'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _importDemoFleet() {
    setState(() {
      _imported = true;
      _devices
        ..clear()
        ..addAll(_demoDevices);
      _proof = _encryptionDemo.proveTelemetryEncryption(
        fromAtSign: '@lyra6dj04_sp',
        toAtSign: '@lyra6dj01_sp',
        deviceId: 'diameter-edge-001',
      );
      _monitor.start(_devices);
      _syncDevicesFromMonitor();
    });
  }

  void _openTelemetry(ProtectedDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceTelemetryScreen(
          device: device,
          monitor: _monitor,
          alerts: _alerts,
        ),
      ),
    );
  }

  void _openTraceability(ProtectedDevice device) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DeviceTraceabilityScreen(
          device: device,
          alerts: _alerts,
        ),
      ),
    );
  }

  void _toggle(ProtectedDevice device, bool enabled) {
    final state = enabled ? ProtectionState.enabled : ProtectionState.disabled;
    setState(() {
      for (var i = 0; i < _devices.length; i += 1) {
        if (_devices[i].id == device.id) {
          _devices[i] = _devices[i].copyWith(protectionState: state);
        }
      }
      if (_monitor.isRunning) {
        _monitor.syncDevices(_devices);
        _syncDevicesFromMonitor();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final activation = _ActivationPanel(
      keychainAtSigns: _keychainAtSigns,
      onRefresh: _refreshKeychain,
      onKeychain: () => _runAuthAction(
        () => _authService.loginWithKeychain(context),
      ),
      onCram: () => _runAuthAction(
        () => _authService.onboardWithManualCram(context),
      ),
      onApkam: () => _runAuthAction(
        () => _authService.loginWithApkam(context),
      ),
      onAtKeys: () => _runAuthAction(
        () => _authService.loginWithAtKeysFile(context),
      ),
      onCreate: _createNewAtSign,
      onExport: _exportCurrentKeys,
    );

    final import = _ImportPanel(
      imported: _imported,
      onImport: _importDemoFleet,
    );

    final summary = _SummaryRow(devices: _devices, alerts: _alerts);

    final proof = _proof == null
        ? null
        : _EncryptionProofCard(proof: _proof!);

    final assetsHeader = SectionHeader(
      title: 'Signaling assets',
      subtitle: _devices.isEmpty
          ? 'Import your fleet to assign atSigns and toggle protection.'
          : '${_devices.length} devices in registry',
    );

    final assetsBody = _devices.isEmpty
        ? const EmptyPanel(
            icon: Icons.upload_file_outlined,
            title: 'No devices yet',
            detail:
                'Import the demo fleet or add devices manually. Each asset receives its own atSign identity.',
          )
        : _DeviceGrid(
            devices: _devices,
            monitorRunning: _monitor.isRunning,
            onToggle: _toggle,
            onTrace: _openTraceability,
            onMonitor: _openTelemetry,
          );

    final alertsHeader = SectionHeader(
      title: 'Threat monitor',
      subtitle: '${_alerts.length} active assessment',
    );

    final alertsBody = _alerts.map(
      (alert) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _AlertCard(alert: alert),
      ),
    );

    return AppPage(
      title: 'Console',
      actions: [OperatorChip(atSign: widget.operatorAtSign)],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = AppLayout.isWide(constraints.maxWidth);

          final setup = <Widget>[
            const AppAccentRule(height: 2),
            const SizedBox(height: 28),
            activation,
            const SizedBox(height: 16),
            import,
            const SizedBox(height: 16),
            summary,
            if (proof != null) ...[
              const SizedBox(height: 16),
              proof,
            ],
          ];

          final fleet = <Widget>[
            if (wide) const SizedBox(height: 30),
            assetsHeader,
            assetsBody,
            const SizedBox(height: 32),
            alertsHeader,
            ...alertsBody,
          ];

          if (wide) {
            return SingleChildScrollView(
              child: ResponsiveColumns(
                breakpoint: 1100,
                gap: 32,
                flex: const [5, 7],
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: setup,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: fleet,
                  ),
                ],
              ),
            );
          }

          return ListView(
            children: [
              ...setup,
              const SizedBox(height: 32),
              ...fleet,
            ],
          );
        },
      ),
    );
  }
}

class _ActivationPanel extends StatelessWidget {
  const _ActivationPanel({
    required this.keychainAtSigns,
    required this.onRefresh,
    required this.onKeychain,
    required this.onCram,
    required this.onApkam,
    required this.onAtKeys,
    required this.onCreate,
    required this.onExport,
  });

  final List<String> keychainAtSigns;
  final VoidCallback onRefresh;
  final VoidCallback onKeychain;
  final VoidCallback onCram;
  final VoidCallback onApkam;
  final VoidCallback onAtKeys;
  final VoidCallback onCreate;
  final VoidCallback onExport;

  static const _targets = [
    _ActivationTarget('Company receiver', '@lyra6dj01_sp'),
    _ActivationTarget('Diameter edge router', '@lyra6dj04_sp'),
    _ActivationTarget('SS7 gateway', '@lyra6dj05_sp'),
    _ActivationTarget('HSS proxy', '@lyra6dj06_sp'),
    _ActivationTarget('Signaling firewall', '@lyra6dj07_sp'),
    _ActivationTarget('Interconnect probe', '@lyra6dj08_sp'),
  ];

  bool _activated(String atSign) {
    final n = atSign.toLowerCase();
    return keychainAtSigns.any((v) => v.toLowerCase() == n);
  }

  @override
  Widget build(BuildContext context) {
    final active = _targets.where((t) => _activated(t.atSign)).length;

    return AppPanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: Icons.vpn_key_outlined,
            title: 'Activate atSigns',
            subtitle:
                '$active of ${_targets.length} demo identities in keychain. Paste the CRAM key manually or import .atKeys.',
            trailing: IconButton(
              tooltip: 'Refresh keychain',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, size: 20),
              style: IconButton.styleFrom(
                foregroundColor: AppColors.gray700,
                side: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in _targets)
                _AtSignChip(
                  label: t.label,
                  atSign: t.atSign,
                  activated: _activated(t.atSign),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              FilledButton.icon(
                onPressed: onCram,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Activate with CRAM key'),
              ),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                label: const Text('Create new atSign'),
              ),
              OutlinedButton.icon(
                onPressed: onKeychain,
                icon: const Icon(Icons.key, size: 18),
                label: const Text('Use keychain'),
              ),
              OutlinedButton.icon(
                onPressed: onAtKeys,
                icon: const Icon(Icons.file_open_outlined, size: 18),
                label: const Text('Import .atKeys'),
              ),
              OutlinedButton.icon(
                onPressed: onApkam,
                icon: const Icon(Icons.phonelink_lock_outlined, size: 18),
                label: const Text('APKAM'),
              ),
              TextButton.icon(
                onPressed: onExport,
                icon: const Icon(Icons.save_alt, size: 18),
                label: const Text('Export keys'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivationTarget {
  const _ActivationTarget(this.label, this.atSign);
  final String label;
  final String atSign;
}

class _AtSignChip extends StatelessWidget {
  const _AtSignChip({
    required this.label,
    required this.atSign,
    required this.activated,
  });

  final String label;
  final String atSign;
  final bool activated;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: activated ? AppColors.gray200 : AppColors.gray100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: activated ? AppColors.gray800 : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            activated ? Icons.check : Icons.circle_outlined,
            size: 14,
            color: activated ? AppColors.gray900 : AppColors.gray500,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 6),
          Text(
            atSign,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ImportPanel extends StatelessWidget {
  const _ImportPanel({required this.imported, required this.onImport});

  final bool imported;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: imported
                ? Icons.check_circle_outline
                : Icons.inventory_2_outlined,
            title: imported ? 'Fleet imported' : 'Import devices',
            subtitle: imported
                ? 'Five Diameter and SS7 assets now have assigned atSign identities.'
                : 'Load signaling nodes, gateways, and proxies from a demo fleet or .txt file.',
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file, size: 18),
              label: Text(imported ? 'Re-import' : 'Import demo fleet'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.devices, required this.alerts});

  final List<ProtectedDevice> devices;
  final List<SecurityAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final protected = devices
        .where((d) => d.protectionState == ProtectionState.enabled)
        .length;
    final isolated = devices
        .where((d) => d.protectionState == ProtectionState.isolated)
        .length;

    final tiles = [
      MetricTile(label: 'Imported', value: devices.length.toString()),
      MetricTile(label: 'Protected', value: protected.toString()),
      MetricTile(label: 'Isolated', value: isolated.toString()),
      MetricTile(label: 'Alerts', value: alerts.length.toString()),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cols = AppLayout.gridColumns(c.maxWidth, maxColumns: 4);
        const gap = 10.0;
        if (cols >= 4) {
          return Row(
            children: [
              for (var i = 0; i < tiles.length; i += 1) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(child: tiles[i]),
              ],
            ],
          );
        }
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: tiles
              .map((t) => SizedBox(width: itemW, child: t))
              .toList(),
        );
      },
    );
  }
}

class _DeviceGrid extends StatelessWidget {
  const _DeviceGrid({
    required this.devices,
    required this.monitorRunning,
    required this.onToggle,
    required this.onTrace,
    required this.onMonitor,
  });

  final List<ProtectedDevice> devices;
  final bool monitorRunning;
  final void Function(ProtectedDevice device, bool enabled) onToggle;
  final void Function(ProtectedDevice device) onTrace;
  final void Function(ProtectedDevice device) onMonitor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final cols = AppLayout.gridColumns(c.maxWidth, maxColumns: 2);
        if (cols == 1) {
          return Column(
            children: [
              for (final device in devices)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DeviceCard(
                    device: device,
                    live: monitorRunning &&
                        device.protectionState != ProtectionState.disabled,
                    onToggle: onToggle,
                    onTrace: () => onTrace(device),
                    onMonitor: () => onMonitor(device),
                  ),
                ),
            ],
          );
        }

        const gap = 12.0;
        final itemW = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final device in devices)
              SizedBox(
                width: itemW,
                child: _DeviceCard(
                  device: device,
                  live: monitorRunning &&
                      device.protectionState != ProtectionState.disabled,
                  onToggle: onToggle,
                  onTrace: () => onTrace(device),
                  onMonitor: () => onMonitor(device),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EncryptionProofCard extends StatelessWidget {
  const _EncryptionProofCard({required this.proof});

  final EncryptionProof proof;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon:
                proof.verified ? Icons.lock_outline : Icons.lock_open_outlined,
            title: 'Encryption proof',
            subtitle:
                'Synthetic telemetry route ${proof.fromAtSign} → ${proof.toAtSign}',
          ),
          MonoBlock(label: 'Plain telemetry', value: proof.plaintext),
          MonoBlock(label: 'Encrypted payload', value: proof.ciphertext),
          MonoBlock(label: 'HMAC digest', value: proof.digest),
          MonoBlock(label: 'Decrypted by service', value: proof.decrypted),
          const SizedBox(height: 14),
          StatusPill(
            label: proof.verified
                ? 'Verified — route key matches'
                : 'Verification failed',
            tone: proof.verified ? AppStatusTone.active : AppStatusTone.warning,
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({
    required this.device,
    required this.live,
    required this.onToggle,
    required this.onTrace,
    required this.onMonitor,
  });

  final ProtectedDevice device;
  final bool live;
  final void Function(ProtectedDevice device, bool enabled) onToggle;
  final VoidCallback onTrace;
  final VoidCallback onMonitor;

  @override
  Widget build(BuildContext context) {
    final isolated = device.protectionState == ProtectionState.isolated;
    final enabled = device.protectionState == ProtectionState.enabled;
    final reading = device.lastReading;

    return AppPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(device.label,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 6),
                    Text(
                      device.id,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: protectionLabel(device.protectionState),
                tone: protectionTone(device.protectionState),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TelemetryMiniStrip(
            reading: reading,
            live: live,
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Protection',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const Spacer(),
              Switch(
                value: enabled,
                onChanged: isolated ? null : (v) => onToggle(device, v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: onMonitor,
                icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                label: const Text('Live monitor'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColors.gray900,
                ),
              ),
              const SizedBox(width: 16),
              TextButton.icon(
                onPressed: onTrace,
                icon: const Icon(Icons.timeline, size: 18),
                label: const Text('Traceability'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: AppColors.gray800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 3,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(12),
                ),
                gradient: AppColors.accentGradient,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(alert.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 8),
                    Text(alert.assessment,
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 10),
                    Text(
                      'Recommended: ${alert.recommendedFix}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

List<ProtectedDevice> get _demoDevices => [
      ProtectedDevice(
        id: 'diameter-edge-001',
        label: 'Diameter Edge Router - Core Site A',
        deviceAtSign: '@lyra6dj04_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:diameter-node',
        firmwareVersion: '2.4.1',
        protocol: 'diameter',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'diameter-edge-001',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -58,
          temperatureC: 41,
          packetLossPercent: 3,
          status: 'normal',
        ),
      ),
      ProtectedDevice(
        id: 'ss7-gateway-002',
        label: 'SS7 Gateway - Core Interconnect 002',
        deviceAtSign: '@lyra6dj05_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:ss7-gateway',
        firmwareVersion: '2.2.0',
        protocol: 'ss7-mtp3',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'ss7-gateway-002',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -64,
          temperatureC: 47,
          packetLossPercent: 7,
          status: 'normal',
        ),
      ),
      const ProtectedDevice(
        id: 'hss-proxy-001',
        label: 'HSS Proxy - Core Control 001',
        deviceAtSign: '@lyra6dj06_sp',
        protectionState: ProtectionState.disabled,
        source: 'demo-import:hss-proxy',
        firmwareVersion: '1.9.8',
        protocol: 'diameter',
      ),
      const ProtectedDevice(
        id: 'routing-firewall-001',
        label: 'Signaling Firewall - Interconnect 001',
        deviceAtSign: '@lyra6dj07_sp',
        protectionState: ProtectionState.isolated,
        source: 'demo-import:signaling-firewall',
        firmwareVersion: '3.1.0',
        protocol: 'ss7-firewall',
      ),
      ProtectedDevice(
        id: 'interconnect-probe-001',
        label: 'Interconnect Probe - Core Site 001',
        deviceAtSign: '@lyra6dj08_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:interconnect-probe',
        firmwareVersion: '4.0.3',
        protocol: 'ss7-monitor',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'interconnect-probe-001',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -71,
          temperatureC: 34,
          packetLossPercent: 2,
          status: 'normal',
        ),
      ),
    ];
