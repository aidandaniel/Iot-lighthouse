import 'package:at_client/at_client.dart';
import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../services/iot_protector_repository.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final IotProtectorRepository _repository;
  List<ProtectedDevice> _devices = [];
  List<SecurityAlert> _alerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _repository = IotProtectorRepository(AtClientManager.getInstance().atClient);
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final devices = await _repository.loadDevices();
    final alerts = await _repository.loadAlerts();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _alerts = alerts;
      _loading = false;
    });
  }

  Future<void> _addDevice() async {
    final device = await showDialog<ProtectedDevice>(
      context: context,
      builder: (_) => const _AddDeviceDialog(),
    );
    if (device == null) return;
    await _repository.importDevices([device]);
    await _refresh();
  }

  Future<void> _toggle(ProtectedDevice device, bool enabled) async {
    final state = enabled ? ProtectionState.enabled : ProtectionState.disabled;
    await _repository.toggleProtection(device, state);
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Management Console'),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDevice,
        icon: const Icon(Icons.add),
        label: const Text('Device'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Summary(devices: _devices, alerts: _alerts),
                const SizedBox(height: 16),
                Text('Devices', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final device in _devices)
                  _DeviceTile(device: device, onToggle: _toggle),
                if (_devices.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.sensors_off),
                    title: Text('No devices imported yet'),
                    subtitle: Text('Add LTE gateways, POS terminals, smart meters, or sensors.'),
                  ),
                const SizedBox(height: 24),
                Text('Security Alerts', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                for (final alert in _alerts) _AlertTile(alert: alert),
                if (_alerts.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('No active alerts'),
                    subtitle: Text('Threat Monitor alerts will appear here.'),
                  ),
              ],
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
    final criticalCount = alerts
        .where((alert) => alert.severity == AlertSeverity.critical)
        .length;
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _Metric(label: 'Devices', value: devices.length.toString()),
        _Metric(label: 'Protected', value: protectedCount.toString()),
        _Metric(label: 'Critical Alerts', value: criticalCount.toString()),
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
      width: 180,
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
  final Future<void> Function(ProtectedDevice device, bool enabled) onToggle;

  @override
  Widget build(BuildContext context) {
    final enabled = device.protectionState == ProtectionState.enabled;
    return Card(
      child: SwitchListTile(
        value: enabled,
        onChanged: (value) => onToggle(device, value),
        title: Text(device.label),
        subtitle: Text(
          '${device.deviceAtSign}  •  ${device.lastReading?.status ?? 'awaiting telemetry'}',
        ),
        secondary: Icon(enabled ? Icons.shield : Icons.shield_outlined),
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final SecurityAlert alert;

  @override
  Widget build(BuildContext context) {
    final color = switch (alert.severity) {
      AlertSeverity.critical => Colors.red,
      AlertSeverity.warning => Colors.orange,
      AlertSeverity.info => Colors.blue,
    };
    return Card(
      child: ListTile(
        leading: Icon(Icons.warning_amber, color: color),
        title: Text(alert.title),
        subtitle: Text('${alert.assessment}\nFix: ${alert.recommendedFix}'),
        isThreeLine: true,
      ),
    );
  }
}

class _AddDeviceDialog extends StatefulWidget {
  const _AddDeviceDialog();

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _id = TextEditingController();
  final _label = TextEditingController();
  final _atSign = TextEditingController();
  String _assetType = 'LTE Gateway';

  void _applyPreset(String type) {
    setState(() {
      _assetType = type;
      switch (type) {
        case 'POS Terminal':
          _id.text = 'pos-terminal-001';
          _label.text = 'POS Terminal - Retail Partner 001';
        case 'Smart Meter':
          _id.text = 'smart-meter-001';
          _label.text = 'Smart Meter - District Node 001';
        case 'Field Sensor':
          _id.text = 'field-sensor-001';
          _label.text = 'Field Sensor - Cabinet 001';
        default:
          _id.text = 'lte-gateway-001';
          _label.text = 'LTE Gateway - Tower Sector A';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Device'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _assetType,
              decoration: const InputDecoration(labelText: 'Asset type'),
              items: const [
                DropdownMenuItem(value: 'LTE Gateway', child: Text('LTE Gateway')),
                DropdownMenuItem(value: 'POS Terminal', child: Text('POS Terminal')),
                DropdownMenuItem(value: 'Smart Meter', child: Text('Smart Meter')),
                DropdownMenuItem(value: 'Field Sensor', child: Text('Field Sensor')),
              ],
              onChanged: (value) {
                if (value != null) _applyPreset(value);
              },
            ),
            TextField(controller: _id, decoration: const InputDecoration(labelText: 'Device ID')),
            TextField(controller: _label, decoration: const InputDecoration(labelText: 'Label')),
            TextField(controller: _atSign, decoration: const InputDecoration(labelText: 'Device Atsign')),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ProtectedDevice(
                id: _id.text.trim(),
                label: _label.text.trim(),
                deviceAtSign: _atSign.text.trim(),
                protectionState: ProtectionState.disabled,
                source: 'manual:${_assetType.toLowerCase().replaceAll(' ', '-')}',
              ),
            );
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
