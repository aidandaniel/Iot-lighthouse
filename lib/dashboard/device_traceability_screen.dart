import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../services/real_atsign_telemetry.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';
import 'world_map_route.dart';

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

class _DeviceContext {
  const _DeviceContext({
    required this.title,
    required this.summary,
    required this.environment,
    required this.outboundData,
    required this.riskFocus,
    required this.protectionValue,
  });

  final String title;
  final String summary;
  final String environment;
  final String outboundData;
  final String riskFocus;
  final String protectionValue;
}

class DeviceTraceabilityScreen extends StatefulWidget {
  const DeviceTraceabilityScreen({
    super.key,
    required this.device,
    required this.alerts,
  });

  final ProtectedDevice device;
  final List<SecurityAlert> alerts;

  @override
  State<DeviceTraceabilityScreen> createState() =>
      _DeviceTraceabilityScreenState();
}

class _DeviceTraceabilityScreenState extends State<DeviceTraceabilityScreen> {
  final _realTelemetry = const RealAtsignTelemetryService();
  RealAtsignTelemetryProof? _realProof;
  bool _realProofRunning = false;

  ProtectedDevice get device => widget.device;
  List<SecurityAlert> get alerts => widget.alerts;

  bool get _isOutboundProofDevice =>
      device.id == 'diameter-edge-001' &&
      device.deviceAtSign.toLowerCase() == '@lyra6dj04_sp';

  _DeviceContext get _context => _contextFor(device);

  @override
  void initState() {
    super.initState();
    _loadRealProof();
  }

  Future<void> _loadRealProof() async {
    final proof = await _realTelemetry.loadLastProof();
    if (!mounted) return;
    setState(() {
      _realProof = proof?.deviceId == device.id ? proof : null;
    });
  }

  Future<void> _runRealTelemetryProof() async {
    setState(() => _realProofRunning = true);
    final proof = await _realTelemetry.proveDeviceToCompanyEncryption(
      deviceAtSign: device.deviceAtSign,
      deviceId: device.id,
    );
    if (!mounted) return;
    setState(() {
      _realProof = proof;
      _realProofRunning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          proof.verified
              ? 'Outbound encrypted telemetry verified.'
              : 'Encrypted telemetry proof failed. Check the proof panel.',
        ),
      ),
    );
  }

  List<_TraceStage> _buildStages() {
    final deviceAlerts = alerts.where((a) => a.deviceId == device.id).toList()
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
        status: deviceAlerts.isEmpty ? _StageStatus.current : _StageStatus.done,
        timestamp: deviceAlerts.isEmpty ? null : deviceAlerts.last.createdAt,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final stages = _buildStages();
    final deviceContext = _context;

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
                if (_isOutboundProofDevice) ...[
                  const SizedBox(height: 16),
                  _OutboundEncryptionProofPanel(
                    proof: _realProof,
                    running: _realProofRunning,
                    onRun: _runRealTelemetryProof,
                  ),
                  const SizedBox(height: 32),
                ],
                if (wide)
                  ResponsiveColumns(
                    breakpoint: 1100,
                    gap: 32,
                    flex: const [1, 2],
                    children: [
                      AppPanel(
                        padding: const EdgeInsets.all(24),
                        child: _DeviceContextPanel(contextInfo: deviceContext),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppPanel(
                        padding: const EdgeInsets.all(24),
                        child: _DeviceContextPanel(contextInfo: deviceContext),
                      ),
                      const SizedBox(height: 16),
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

class _DeviceContextPanel extends StatelessWidget {
  const _DeviceContextPanel({required this.contextInfo});

  final _DeviceContext contextInfo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          contextInfo.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Text(
          contextInfo.summary,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        _ContextLine(label: 'Environment', value: contextInfo.environment),
        _ContextLine(label: 'Outbound data', value: contextInfo.outboundData),
        _ContextLine(label: 'Risk focus', value: contextInfo.riskFocus),
        _ContextLine(
          label: 'Protection value',
          value: contextInfo.protectionValue,
        ),
      ],
    );
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}

class _OutboundEncryptionProofPanel extends StatelessWidget {
  const _OutboundEncryptionProofPanel({
    required this.proof,
    required this.running,
    required this.onRun,
  });

  final RealAtsignTelemetryProof? proof;
  final bool running;
  final VoidCallback onRun;

  @override
  Widget build(BuildContext context) {
    final verified = proof?.verified == true;
    return AppPanel(
      accent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PanelHeader(
            icon: verified ? Icons.enhanced_encryption : Icons.lock_outline,
            title: 'Outbound encryption proof',
            subtitle:
                'Device telemetry leaves this node as an encrypted Atsign shared AtKey.',
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: running ? null : onRun,
            icon: running
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_outlined, size: 18),
            label: Text(
              running
                  ? 'Sending encrypted telemetry...'
                  : 'Send outbound encrypted telemetry',
            ),
          ),
          if (proof == null) ...[
            const SizedBox(height: 14),
            Text(
              'Runs the real proof for this outbound device: authenticate device .atKeys, write shared telemetry, authenticate company .atKeys, read and decrypt.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ] else ...[
            const SizedBox(height: 16),
            StatusPill(
              label: verified
                  ? 'Verified - company decrypted shared AtKey'
                  : 'Not verified',
              tone: verified ? AppStatusTone.active : AppStatusTone.warning,
            ),
            const SizedBox(height: 12),
            WorldMapRoute(
              fromAtSign: proof!.deviceAtSign,
              toAtSign: proof!.companyAtSign,
            ),
            const SizedBox(height: 16),
            MonoBlock(
              label: 'Route',
              value: '${proof!.deviceAtSign} -> ${proof!.companyAtSign}',
            ),
            MonoBlock(label: 'AtKey', value: proof!.atKeyName),
            MonoBlock(label: 'Device plaintext', value: proof!.plaintext),
            MonoBlock(
                label: 'Company decrypted value', value: proof!.decrypted),
            if (proof!.error != null)
              MonoBlock(label: 'Error', value: proof!.error!),
          ],
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
        Text(label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall),
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
                          color: pending
                              ? AppColors.gray500
                              : AppColors.textSecondary,
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

_DeviceContext _contextFor(ProtectedDevice device) {
  switch (device.id) {
    case 'diameter-edge-001':
      return const _DeviceContext(
        title: 'Diameter edge router context',
        summary:
            'Core signaling edge node handling Diameter traffic between access systems and the operator control plane.',
        environment:
            '4G/LTE packet core edge, near MME/PCRF/HSS integrations and roaming/interconnect routes.',
        outboundData:
            'Route health, peer status, packet-loss telemetry, and anomaly signals sent back to the company atSign.',
        riskFocus:
            'Diameter route tamper, peer spoofing, downgrade pressure, and abnormal fallback into legacy signaling paths.',
        protectionValue:
            'The device atSign encrypts outbound telemetry directly for the company atSign, proving telemetry can leave the node without a central plaintext collector.',
      );
    case 'ss7-gateway-002':
      return const _DeviceContext(
        title: 'SS7 gateway context',
        summary:
            'Interconnect gateway bridging legacy SS7 signaling into the operator monitoring and protection workflow.',
        environment:
            'Core interconnect boundary where MAP/CAP-style signaling and roaming traffic require tight traceability.',
        outboundData:
            'Linkset health, MTP3 status, suspicious routing patterns, and gateway availability readings.',
        riskFocus:
            'Location tracking abuse, message interception, spoofed signaling origin, and weak trust between roaming partners.',
        protectionValue:
            'AtSign identity gives the gateway a device-bound sender identity so telemetry provenance is visible before operators trust the reading.',
      );
    case 'hss-proxy-001':
      return const _DeviceContext(
        title: 'HSS proxy context',
        summary:
            'Diameter-facing subscriber control proxy representing a sensitive identity and authentication choke point.',
        environment:
            'Core control plane path near HSS/HLR systems, subscription lookups, and authentication workflows.',
        outboundData:
            'Proxy health, request pressure, failed authentication rates, and route-status telemetry.',
        riskFocus:
            'Credential abuse, subscriber-data exposure, unauthorized lookup patterns, and saturation against identity services.',
        protectionValue:
            'AtSign encryption lets the proxy report control-plane health to the company while keeping subscriber-adjacent telemetry scoped to the owner.',
      );
    case 'routing-firewall-001':
      return const _DeviceContext(
        title: 'Signaling firewall context',
        summary:
            'Policy enforcement appliance watching Diameter and SS7 traffic at a high-risk interconnect boundary.',
        environment:
            'Interconnect edge between operator core services, roaming partners, and legacy signaling networks.',
        outboundData:
            'Blocked routes, rule hits, isolation state, route-risk scores, and protection-action telemetry.',
        riskFocus:
            'Malicious route attempts, unexpected partner traffic, policy bypass, and command-and-control style probing.',
        protectionValue:
            'AtSign protection makes firewall events attributable to the appliance identity and allows isolation evidence to be encrypted back to the company.',
      );
    case 'interconnect-probe-001':
      return const _DeviceContext(
        title: 'Interconnect probe context',
        summary:
            'Passive monitoring probe that observes signaling behavior and feeds operational evidence into IoT Lighthouse.',
        environment:
            'Core-site monitoring tap for roaming, SS7, and Diameter interconnect paths.',
        outboundData:
            'Observed latency, packet loss, route anomalies, suspicious peer behavior, and live monitoring samples.',
        riskFocus:
            'Blind spots in partner links, slow-burn reconnaissance, abnormal signaling bursts, and telemetry integrity gaps.',
        protectionValue:
            'The probe atSign signs the telemetry source path and encrypts observations so monitoring data is protected before storage or review.',
      );
    default:
      return _DeviceContext(
        title: '${device.label} context',
        summary:
            'Telecom signaling asset managed by IoT Lighthouse with a dedicated atSign identity.',
        environment:
            'Operator signaling environment using ${device.protocol ?? 'Diameter/SS7'} telemetry.',
        outboundData:
            'Status, signal, packet-loss, and protection-state readings sent to the company atSign.',
        riskFocus:
            'Credential misuse, route tamper, stale firmware, and untrusted telemetry provenance.',
        protectionValue:
            'AtSign encryption binds outbound device telemetry to an identity and keeps readings encrypted for the company.',
      );
  }
}
