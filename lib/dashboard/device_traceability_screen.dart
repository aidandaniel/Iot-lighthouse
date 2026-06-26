import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

enum _StageStatus { done, current, pending }

class _TraceStage {
  const _TraceStage({
    required this.title,
    required this.detail,
    required this.status,
    this.timestamp,
  });

  final String title;
  final String detail;
  final _StageStatus status;
  final DateTime? timestamp;
}

class DeviceTraceabilityScreen extends StatelessWidget {
  const DeviceTraceabilityScreen({
    super.key,
    required this.device,
    required this.alerts,
  });

  final ProtectedDevice device;
  final List<SecurityAlert> alerts;

  List<_TraceStage> _buildStages() {
    final deviceAlerts = alerts
        .where((a) => a.deviceId == device.id)
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final isolated = device.protectionState == ProtectionState.isolated;
    final protectionOn =
        device.protectionState == ProtectionState.enabled || isolated;
    final reading = device.lastReading;

    return [
      _TraceStage(
        title: 'Imported',
        detail: 'Onboarded via ${device.source}.',
        status: _StageStatus.done,
        timestamp: device.lastSeen,
      ),
      _TraceStage(
        title: 'atSign assigned',
        detail: device.deviceAtSign.isEmpty
            ? 'No identity bound yet.'
            : '${device.deviceAtSign} bound to this device.',
        status: device.deviceAtSign.isEmpty
            ? _StageStatus.pending
            : _StageStatus.done,
      ),
      _TraceStage(
        title: 'Protection',
        detail: isolated
            ? 'Device isolated by the protection service.'
            : protectionOn
                ? 'Protection service is active.'
                : 'Protection is off.',
        status: protectionOn ? _StageStatus.done : _StageStatus.pending,
      ),
      _TraceStage(
        title: 'Telemetry',
        detail: reading == null
            ? 'Awaiting first reading.'
            : '${reading.status} · ${reading.signalStrength.toStringAsFixed(0)} dBm · '
                '${reading.packetLossPercent.toStringAsFixed(0)}% loss',
        status: reading == null ? _StageStatus.pending : _StageStatus.done,
        timestamp: reading?.recordedAt,
      ),
      _TraceStage(
        title: 'Threat assessment',
        detail: deviceAlerts.isEmpty
            ? 'No threats flagged. Monitoring continues.'
            : deviceAlerts.last.title,
        status:
            deviceAlerts.isEmpty ? _StageStatus.current : _StageStatus.done,
        timestamp: deviceAlerts.isEmpty ? null : deviceAlerts.last.createdAt,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();

    return AppPage(
      title: 'Traceability',
      leading: const BackButton(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = AppLayout.isWide(constraints.maxWidth);
          return AppWindow(
            child: ListView(
              children: [
                const AppAccentRule(height: 2),
                const SizedBox(height: 24),
                _DeviceSummary(device: device),
                const SizedBox(height: 32),
                const SectionHeader(
                  title: 'Signal trace',
                  subtitle: 'Lifecycle from import to threat assessment.',
                ),
                if (wide)
                  ResponsiveColumns(
                    breakpoint: 1100,
                    gap: 32,
                    flex: const [1, 2],
                    children: [
                      AppPanel(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Device context',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Each stage records a verifiable hop in the '
                              'protection and telemetry chain for this asset.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      AppPanel(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                        child: Column(
                          children: [
                            for (var i = 0; i < stages.length; i += 1)
                              _TraceRow(
                                stage: stages[i],
                                isLast: i == stages.length - 1,
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                else
                  AppPanel(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                    child: Column(
                      children: [
                        for (var i = 0; i < stages.length; i += 1)
                          _TraceRow(
                            stage: stages[i],
                            isLast: i == stages.length - 1,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DeviceSummary extends StatelessWidget {
  const _DeviceSummary({required this.device});

  final ProtectedDevice device;

  @override
  Widget build(BuildContext context) {
    return AppPanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  device.label,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 22,
                      ),
                ),
              ),
              StatusPill(
                label: protectionLabel(device.protectionState),
                tone: protectionTone(device.protectionState),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            device.id,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              color: AppColors.gray600,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _Field(label: 'atSign', value: device.deviceAtSign),
              _Field(label: 'Protocol', value: device.protocol ?? 'diameter'),
              _Field(
                label: 'Firmware',
                value: device.firmwareVersion ?? 'unknown',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value});

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

class _TraceRow extends StatelessWidget {
  const _TraceRow({required this.stage, required this.isLast});

  final _TraceStage stage;
  final bool isLast;

  Color _nodeColor() {
    switch (stage.status) {
      case _StageStatus.done:
        return AppColors.gray900;
      case _StageStatus.current:
        return AppColors.gray700;
      case _StageStatus.pending:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    final node = _nodeColor();
    final pending = stage.status == _StageStatus.pending;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: pending ? Colors.transparent : node,
                    border: Border.all(color: node, width: pending ? 2 : 0),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            node,
                            pending ? AppColors.gray300 : AppColors.gray500,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: pending ? AppColors.gray500 : AppColors.text,
                          fontSize: 16,
                        ),
                  ),
                  if (stage.timestamp != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _formatTimestamp(stage.timestamp!),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    stage.detail,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: pending ? AppColors.gray500 : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatTimestamp(DateTime time) {
  final utc = time.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${utc.year}-${two(utc.month)}-${two(utc.day)} '
      '${two(utc.hour)}:${two(utc.minute)} UTC';
}
