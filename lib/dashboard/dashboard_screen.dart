import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/device_models.dart';
import '../services/at_auth_service.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import '../services/telemetry_monitor.dart';
import 'device_telemetry_screen.dart';
import 'device_traceability_screen.dart';
import 'telemetry_widgets.dart';

const _starterPackUrl = 'https://my.atsign.com/starterpack_app';

const _attackDemoDeviceId = 'diameter-edge-001';

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
  final _monitor = TelemetryMonitor();
  List<String> _keychainAtSigns = const [];
  bool _imported = false;
  int _selectedTabIndex = 0;

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

  void _simulateAttack(ProtectedDevice device) {
    setState(() {
      _monitor.simulateAttack(device.id);
      for (var i = 0; i < _devices.length; i += 1) {
        if (_devices[i].id == device.id) {
          _devices[i] = _devices[i].copyWith(
            protectionState: ProtectionState.isolated,
          );
        }
      }
      _monitor.syncDevices(_devices);
      _syncDevicesFromMonitor();

      final alreadyAlerted = _alerts.any((a) => a.deviceId == device.id);
      if (!alreadyAlerted) {
        _alerts.insert(
          0,
          SecurityAlert(
            id: 'alert-attack-${device.id}',
            deviceId: device.id,
            severity: AlertSeverity.critical,
            title: 'Simulated attack on ${device.id}',
            assessment:
                'Telemetry spiked: packet loss exceeded 40%, signal collapsed, '
                'and routing anomalies match AI-assisted SS7/Diameter probing.',
            recommendedFix:
                'Device auto-isolated. Rotate credentials, inspect firmware, '
                'and verify atSign protection keys.',
            createdAt: DateTime.now().toUtc(),
          ),
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${device.label} isolated — attack telemetry streaming.',
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
      if (enabled) {
        _monitor.stopAttack(device.id);
      }
      if (_monitor.isRunning) {
        _monitor.syncDevices(_devices);
        _syncDevicesFromMonitor();
      }
    });
  }

  void _showAddDeviceDialog(
      BuildContext context, Widget activation, Widget import) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Add Device',
                        style: Theme.of(context).textTheme.headlineMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                activation,
                const SizedBox(height: 16),
                import,
              ],
            ),
          ),
        ),
      ),
    );
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

    // summary is now rendered directly in the column

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
            onSimulateAttack: _simulateAttack,
            attackDemoDeviceId: _attackDemoDeviceId,
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

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            decoration: const BoxDecoration(
              color: AppColors.gray100,
              border: Border(right: BorderSide(color: AppColors.border)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: OperatorChip(atSign: widget.operatorAtSign),
                ),
                const SizedBox(height: 16),
                _SidebarItem(
                  icon: Icons.devices_outlined,
                  label: 'Devices',
                  selected: _selectedTabIndex == 0,
                  onTap: () => setState(() => _selectedTabIndex = 0),
                ),
                _SidebarItem(
                  icon: Icons.list_alt_outlined,
                  label: 'Logging',
                  selected: _selectedTabIndex == 1,
                  onTap: () => setState(() => _selectedTabIndex = 1),
                ),
              ],
            ),
          ),
          // Main content
          if (_selectedTabIndex == 0)
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Devices Pane
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SummaryBar(devices: _devices, alerts: _alerts),
                        Expanded(
                          child: ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              assetsHeader,
                              assetsBody,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right Pane
                  Container(
                    width: 360,
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.border)),
                    ),
                    child: ListView(
                      padding: const EdgeInsets.all(32),
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              _showAddDeviceDialog(context, activation, import),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Device'),
                        ),
                        if (_devices.isNotEmpty) ...[
                          const SizedBox(height: 32),
                          alertsHeader,
                          ...alertsBody,
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            Expanded(
              child: _LoggingPane(devices: _devices),
            ),
        ],
      ),
    );
  }
}

class _LoggingPane extends StatefulWidget {
  const _LoggingPane({required this.devices});

  final List<ProtectedDevice> devices;

  @override
  State<_LoggingPane> createState() => _LoggingPaneState();
}

class _LoggingPaneState extends State<_LoggingPane> {
  String? _selectedDeviceId;

  @override
  Widget build(BuildContext context) {
    if (widget.devices.isEmpty) {
      return const Center(
        child: EmptyPanel(
          icon: Icons.folder_open,
          title: 'No logs available',
          detail: 'Import devices to view their logs.',
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Folders list
        Container(
          width: 300,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: AppColors.border)),
          ),
          child: ListView.builder(
            itemCount: widget.devices.length,
            itemBuilder: (context, index) {
              final device = widget.devices[index];
              final isSelected = device.id == _selectedDeviceId;
              return ListTile(
                leading: Icon(
                  isSelected ? Icons.folder_open : Icons.folder,
                  color: isSelected ? AppColors.black : AppColors.gray500,
                ),
                title: Text(
                  device.id,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    color: isSelected ? AppColors.black : AppColors.gray800,
                  ),
                ),
                selected: isSelected,
                selectedTileColor: AppColors.gray100,
                onTap: () => setState(() => _selectedDeviceId = device.id),
              );
            },
          ),
        ),
        // Files list
        Expanded(
          child: _selectedDeviceId == null
              ? const Center(
                  child: Text(
                    'Select a device folder to view logs',
                    style: TextStyle(color: AppColors.gray500),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Text(
                      'Logs for $_selectedDeviceId',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 24),
                    _LogFileRow(
                        filename: '${_selectedDeviceId}_syslog_2026-06-26.log',
                        size: '2.4 MB',
                        date: 'Today, 10:42 AM'),
                    _LogFileRow(
                        filename: '${_selectedDeviceId}_auth_2026-06-26.log',
                        size: '1.1 MB',
                        date: 'Today, 08:15 AM'),
                    _LogFileRow(
                        filename: '${_selectedDeviceId}_telemetry_2026-06-25.log',
                        size: '8.7 MB',
                        date: 'Yesterday, 11:59 PM'),
                    _LogFileRow(
                        filename: '${_selectedDeviceId}_syslog_2026-06-25.log',
                        size: '4.2 MB',
                        date: 'Yesterday, 11:59 PM'),
                  ],
                ),
        ),
      ],
    );
  }
}

class _LogFileRow extends StatelessWidget {
  const _LogFileRow({
    required this.filename,
    required this.size,
    required this.date,
  });

  final String filename;
  final String size;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.insert_drive_file_outlined, color: AppColors.gray600),
        title: Text(filename, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
        subtitle: Text(date),
        trailing: Text(size, style: const TextStyle(color: AppColors.gray500)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Downloading $filename...')),
          );
        },
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: selected ? AppColors.gray200 : Colors.transparent,
      child: ListTile(
        leading:
            Icon(icon, color: selected ? AppColors.black : AppColors.gray600),
        title: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.black : AppColors.gray600,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        onTap: onTap,
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

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({required this.devices, required this.alerts});

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _MiniMetric(label: 'Imported', value: devices.length.toString()),
          _MiniMetric(label: 'Protected', value: protected.toString()),
          _MiniMetric(label: 'Isolated', value: isolated.toString()),
          _MiniMetric(label: 'Alerts', value: alerts.length.toString()),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.emerald,
              ),
        ),
      ],
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
    required this.onSimulateAttack,
    required this.attackDemoDeviceId,
  });

  final List<ProtectedDevice> devices;
  final bool monitorRunning;
  final void Function(ProtectedDevice device, bool enabled) onToggle;
  final void Function(ProtectedDevice device) onTrace;
  final void Function(ProtectedDevice device) onMonitor;
  final void Function(ProtectedDevice device) onSimulateAttack;
  final String attackDemoDeviceId;

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
                    onSimulateAttack: device.id == attackDemoDeviceId &&
                            device.protectionState != ProtectionState.isolated
                        ? () => onSimulateAttack(device)
                        : null,
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
                  onSimulateAttack: device.id == attackDemoDeviceId
                      ? () => onSimulateAttack(device)
                      : null,
                ),
              ),
          ],
        );
      },
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
    this.onSimulateAttack,
  });

  final ProtectedDevice device;
  final bool live;
  final void Function(ProtectedDevice device, bool enabled) onToggle;
  final VoidCallback onTrace;
  final VoidCallback onMonitor;
  final VoidCallback? onSimulateAttack;

  @override
  Widget build(BuildContext context) {
    final enabled = device.protectionState == ProtectionState.enabled;
    final reading = device.lastReading;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AppPanel(
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
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: TelemetryMiniStrip(
                key: ValueKey('${reading?.status}_$live'),
                reading: reading,
                live: live,
              ),
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
                  onChanged: (v) => onToggle(device, v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (onSimulateAttack != null)
                  TextButton.icon(
                    onPressed: device.protectionState == ProtectionState.isolated ? null : onSimulateAttack,
                    icon: const Icon(Icons.bolt_outlined, size: 18),
                    label: Text(device.protectionState == ProtectionState.isolated ? 'Attack' : 'Simulate'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      foregroundColor: AppColors.emerald,
                      disabledForegroundColor: AppColors.ruby,
                    ),
                  ),
                TextButton.icon(
                  onPressed: onMonitor,
                  icon: const Icon(Icons.monitor_heart_outlined, size: 18),
                  label: const Text('Live monitor'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.emerald,
                  ),
                ),
                TextButton.icon(
                  onPressed: onTrace,
                  icon: const Icon(Icons.timeline, size: 18),
                  label: const Text('Traceability'),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
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
        protectionState: ProtectionState.disabled,
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
        protectionState: ProtectionState.enabled,
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
