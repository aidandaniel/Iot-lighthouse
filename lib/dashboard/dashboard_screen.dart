import 'package:flutter/material.dart';

import '../models/device_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.operatorAtSign});

  final String operatorAtSign;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<ProtectedDevice> _devices = [];
  final List<SecurityAlert> _alerts = [
    SecurityAlert(
      id: 'alert-demo-001',
      deviceId: 'smart-meter-001',
      severity: AlertSeverity.critical,
      title: 'Smart meter firmware fallback detected',
      assessment:
          'The meter is using an aging NB-IoT profile with abnormal packet loss. This can indicate weak protocol fallback, SIM misuse, or field tamper.',
      recommendedFix:
          'Keep the meter isolated, rotate credentials, verify SIM status, and schedule firmware inspection.',
      createdAt: DateTime.now().toUtc(),
    ),
  ];
  bool _imported = false;

  void _importDemoFleet() {
    setState(() {
      _imported = true;
      _devices
        ..clear()
        ..addAll(_demoDevices);
    });
  }

  void _toggle(ProtectedDevice device, bool enabled) {
    final state = enabled ? ProtectionState.enabled : ProtectionState.disabled;
    setState(() {
      for (var i = 0; i < _devices.length; i += 1) {
        if (_devices[i].id == device.id) {
          _devices[i] = _devices[i].copyWith(protectionState: state);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('IoT Lighthouse Console'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: Text(widget.operatorAtSign)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          _ImportPanel(imported: _imported, onImport: _importDemoFleet),
          const SizedBox(height: 16),
          _Summary(devices: _devices, alerts: _alerts),
          const SizedBox(height: 20),
          Text('Protected Telecom Assets',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          if (_devices.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.upload_file),
                title: Text('Import the demo fleet to begin'),
                subtitle: Text(
                  'The import assigns one Atsign identity to each 4G/LTE connected device.',
                ),
              ),
            ),
          for (final device in _devices)
            _DeviceTile(device: device, onToggle: _toggle),
          const SizedBox(height: 20),
          Text('Threat Monitor Alerts',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final alert in _alerts) _AlertTile(alert: alert),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(imported ? Icons.check_circle : Icons.inventory_2_outlined),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    imported
                        ? 'Demo fleet imported'
                        : 'Import telecom IoT devices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    imported
                        ? 'Five LTE/4G connected assets now have assigned Atsign identities.'
                        : 'Load LTE gateways, POS terminals, smart meters, and sensors, then assign each device an Atsign identity.',
                  ),
                ],
              ),
            ),
            FilledButton.icon(
              onPressed: onImport,
              icon: const Icon(Icons.upload_file),
              label: Text(imported ? 'Re-import' : 'Import demo fleet'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.devices, required this.alerts});

  final List<ProtectedDevice> devices;
  final List<SecurityAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final protectedCount = devices
        .where((device) => device.protectionState == ProtectionState.enabled)
        .length;
    final isolatedCount = devices
        .where((device) => device.protectionState == ProtectionState.isolated)
        .length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Metric(label: 'Imported', value: devices.length.toString()),
        _Metric(label: 'Protected', value: protectedCount.toString()),
        _Metric(label: 'Isolated', value: isolatedCount.toString()),
        _Metric(label: 'Alerts', value: alerts.length.toString()),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label),
              const SizedBox(height: 8),
              Text(value, style: Theme.of(context).textTheme.headlineSmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onToggle});

  final ProtectedDevice device;
  final void Function(ProtectedDevice device, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final enabled = device.protectionState == ProtectionState.enabled;
    final isolated = device.protectionState == ProtectionState.isolated;
    return Card(
      child: SwitchListTile(
        value: enabled,
        onChanged: isolated ? null : (value) => onToggle(device, value),
        title: Text(device.label),
        subtitle: Text(
          '${device.id}  |  ${device.deviceAtSign}  |  ${device.protocol ?? 'lte'}  |  ${device.lastReading?.status ?? 'awaiting telemetry'}',
        ),
        secondary: Icon(
          isolated
              ? Icons.block
              : enabled
                  ? Icons.shield
                  : Icons.shield_outlined,
        ),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.warning_amber, color: Colors.red),
        title: Text(alert.title),
        subtitle: Text('${alert.assessment}\nFix: ${alert.recommendedFix}'),
        isThreeLine: true,
      ),
    );
  }
}

List<ProtectedDevice> get _demoDevices => [
      ProtectedDevice(
        id: 'lte-gateway-001',
        label: 'LTE Gateway - Tower Sector A',
        deviceAtSign: '@lyra6dj04_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:lte-gateway',
        firmwareVersion: '2.4.1',
        protocol: 'lte-mqtt',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'lte-gateway-001',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -58,
          temperatureC: 41,
          packetLossPercent: 3,
          status: 'normal',
        ),
      ),
      ProtectedDevice(
        id: 'lte-router-002',
        label: '4G Router - Rural Backhaul 002',
        deviceAtSign: '@lyra6dj05_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:4g-router',
        firmwareVersion: '2.2.0',
        protocol: 'lte-ipsec',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'lte-router-002',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -64,
          temperatureC: 47,
          packetLossPercent: 7,
          status: 'normal',
        ),
      ),
      const ProtectedDevice(
        id: 'pos-terminal-001',
        label: 'POS Terminal - Retail Partner 001',
        deviceAtSign: '@lyra6dj06_sp',
        protectionState: ProtectionState.disabled,
        source: 'demo-import:pos-terminal',
        firmwareVersion: '1.9.8',
        protocol: 'lte-pos',
      ),
      const ProtectedDevice(
        id: 'smart-meter-001',
        label: 'Smart Meter - District Node 001',
        deviceAtSign: '@lyra6dj07_sp',
        protectionState: ProtectionState.isolated,
        source: 'demo-import:smart-meter',
        firmwareVersion: '3.1.0',
        protocol: 'nb-iot',
      ),
      ProtectedDevice(
        id: 'field-sensor-001',
        label: 'Field Sensor - Cabinet 001',
        deviceAtSign: '@lyra6dj08_sp',
        protectionState: ProtectionState.enabled,
        source: 'demo-import:field-sensor',
        firmwareVersion: '4.0.3',
        protocol: 'lte-cat-m1',
        lastSeen: DateTime.now().toUtc(),
        lastReading: TelemetryReading(
          deviceId: 'field-sensor-001',
          recordedAt: DateTime.now().toUtc(),
          signalStrength: -71,
          temperatureC: 34,
          packetLossPercent: 2,
          status: 'normal',
        ),
      ),
    ];
