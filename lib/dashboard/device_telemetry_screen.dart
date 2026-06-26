import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../services/telemetry_monitor.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'device_traceability_screen.dart';
import 'telemetry_widgets.dart';

class DeviceTelemetryScreen extends StatefulWidget {
  const DeviceTelemetryScreen({
    super.key,
    required this.device,
    required this.monitor,
    required this.alerts,
  });

  final ProtectedDevice device;
  final TelemetryMonitor monitor;
  final List<SecurityAlert> alerts;

  @override
  State<DeviceTelemetryScreen> createState() => _DeviceTelemetryScreenState();
}

class _DeviceTelemetryScreenState extends State<DeviceTelemetryScreen> {
  @override
  void initState() {
    super.initState();
    widget.monitor.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.monitor.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  bool get _streaming =>
      widget.device.protectionState != ProtectionState.disabled;

  List<TelemetryReading> get _history =>
      widget.monitor.historyFor(widget.device.id);

  TelemetryReading? get _latest =>
      widget.monitor.latestFor(widget.device.id) ?? widget.device.lastReading;

  @override
  Widget build(BuildContext context) {
    final device = widget.device;
    final latest = _latest;
    final history = _history;
    final signals = history.map((r) => r.signalStrength).toList();
    final temps = history.map((r) => r.temperatureC).toList();
    final losses = history.map((r) => r.packetLossPercent).toList();

    return AppPage(
      title: 'Live telemetry',
      leading: const BackButton(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final cols = AppLayout.gridColumns(constraints.maxWidth, maxColumns: 4);

          return ListView(
            children: [
              const AppAccentRule(height: 2),
              const SizedBox(height: 24),
              AppPanel(
                accent: true,
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
                              Text(
                                device.label,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontSize: 22),
                              ),
                              const SizedBox(height: 8),
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
                        LivePulse(active: _streaming && widget.monitor.isRunning),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 20,
                      runSpacing: 8,
                      children: [
                        _HeaderField(label: 'atSign', value: device.deviceAtSign),
                        _HeaderField(
                          label: 'Protocol',
                          value: device.protocol ?? 'diameter',
                        ),
                        _HeaderField(
                          label: 'Route',
                          value: '${device.deviceAtSign} → @lyra6dj02_sp',
                        ),
                        if (latest != null)
                          _HeaderField(
                            label: 'Last reading',
                            value: formatTelemetryTime(latest.recordedAt),
                          ),
                      ],
                    ),
                    if (latest != null) ...[
                      const SizedBox(height: 16),
                      StatusPill(
                        label: latest.status.toUpperCase(),
                        tone: toneForReading(latest),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (latest == null)
                const EmptyPanel(
                  icon: Icons.sensors_off_outlined,
                  title: 'No telemetry yet',
                  detail:
                      'Enable protection on this device to start the encrypted telemetry stream.',
                )
              else ...[
                _MetricGrid(
                  maxWidth: constraints.maxWidth,
                  cols: cols,
                  latest: latest,
                  signals: signals,
                  temps: temps,
                  losses: losses,
                ),
                const SizedBox(height: 28),
                SectionHeader(
                  title: 'Reading log',
                  subtitle: 'Last ${history.length} encrypted samples',
                ),
                AppPanel(
                  padding: const EdgeInsets.all(0),
                  child: _ReadingLog(readings: history.reversed.take(12).toList()),
                ),
              ],
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DeviceTraceabilityScreen(
                            device: device,
                            alerts: widget.alerts,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.timeline, size: 18),
                    label: const Text('Traceability map'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HeaderField extends StatelessWidget {
  const _HeaderField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.maxWidth,
    required this.cols,
    required this.latest,
    required this.signals,
    required this.temps,
    required this.losses,
  });

  final double maxWidth;
  final int cols;
  final TelemetryReading latest;
  final List<double> signals;
  final List<double> temps;
  final List<double> losses;

  @override
  Widget build(BuildContext context) {
    final cards = [
      TelemetryMetricCard(
        label: 'Signal strength',
        value: latest.signalStrength.toStringAsFixed(0),
        unit: 'dBm',
        history: signals,
        tone: latest.signalStrength <= -75
            ? AppStatusTone.warning
            : AppStatusTone.active,
      ),
      TelemetryMetricCard(
        label: 'Temperature',
        value: latest.temperatureC.toStringAsFixed(0),
        unit: '°C',
        history: temps,
        tone: latest.temperatureC >= 55
            ? AppStatusTone.warning
            : AppStatusTone.active,
      ),
      TelemetryMetricCard(
        label: 'Packet loss',
        value: latest.packetLossPercent.toStringAsFixed(1),
        unit: '%',
        history: losses,
        tone: latest.packetLossPercent >= 10
            ? AppStatusTone.warning
            : AppStatusTone.active,
      ),
      TelemetryMetricCard(
        label: 'Link status',
        value: latest.status,
        unit: '',
        history: losses,
        tone: toneForReading(latest),
      ),
    ];

    if (cols >= 4) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i += 1) ...[
            if (i > 0) const SizedBox(width: 12),
            Expanded(child: cards[i]),
          ],
        ],
      );
    }

    const gap = 12.0;
    final itemW = (maxWidth - gap * (cols - 1)) / cols;
    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: cards.map((card) => SizedBox(width: itemW, child: card)).toList(),
    );
  }
}

class _ReadingLog extends StatelessWidget {
  const _ReadingLog({required this.readings});

  final List<TelemetryReading> readings;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Text('No samples recorded.', style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text('TIME', style: Theme.of(context).textTheme.labelSmall)),
              Expanded(child: Text('SIGNAL', style: Theme.of(context).textTheme.labelSmall)),
              Expanded(child: Text('TEMP', style: Theme.of(context).textTheme.labelSmall)),
              Expanded(child: Text('LOSS', style: Theme.of(context).textTheme.labelSmall)),
              Expanded(child: Text('STATUS', style: Theme.of(context).textTheme.labelSmall)),
            ],
          ),
        ),
        const Divider(height: 1),
        for (var i = 0; i < readings.length; i += 1) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    formatTelemetryTime(readings[i].recordedAt),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.gray700,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    readings[i].signalStrength.toStringAsFixed(0),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${readings[i].temperatureC.toStringAsFixed(0)}°',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    '${readings[i].packetLossPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: AppColors.text,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    readings[i].status,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.text,
                        ),
                  ),
                ),
              ],
            ),
          ),
          if (i < readings.length - 1) const Divider(height: 1, indent: 20, endIndent: 20),
        ],
        const SizedBox(height: 8),
      ],
    );
  }
}
