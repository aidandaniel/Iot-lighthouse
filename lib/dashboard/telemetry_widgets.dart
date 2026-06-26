import 'package:flutter/material.dart';

import '../models/device_models.dart';
import '../theme/app_theme.dart';
import '../theme/app_widgets.dart';

class LivePulse extends StatefulWidget {
  const LivePulse({super.key, required this.active});

  final bool active;

  @override
  State<LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<LivePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.active) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(LivePulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.active) {
      _pulse.stop();
      _pulse.value = 1;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final opacity = !widget.active
        ? 0.35
        : reduceMotion
            ? 1.0
            : 0.45 + _pulse.value * 0.55;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.active ? AppColors.emerald : AppColors.gray400,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          widget.active ? 'LIVE' : 'PAUSED',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: widget.active ? AppColors.emerald : AppColors.gray400,
              ),
        ),
      ],
    );
  }
}

class Sparkline extends StatelessWidget {
  const Sparkline({
    super.key,
    required this.values,
    this.height = 44,
    this.strokeColor = AppColors.emerald,
    this.fillColor,
  });

  final List<double> values;
  final double height;
  final Color strokeColor;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) {
      return SizedBox(
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.gray100,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.border),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _SparklinePainter(
          values: values,
          strokeColor: strokeColor,
          fillColor: fillColor ?? strokeColor.withValues(alpha: 0.08),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.values,
    required this.strokeColor,
    required this.fillColor,
  });

  final List<double> values;
  final Color strokeColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < 0.001 ? 1.0 : max - min;

    final path = Path();
    final fill = Path();

    for (var i = 0; i < values.length; i += 1) {
      final x = i / (values.length - 1) * size.width;
      final y = size.height - ((values[i] - min) / range) * (size.height - 4) - 2;
      if (i == 0) {
        path.moveTo(x, y);
        fill.moveTo(x, size.height);
        fill.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fill.lineTo(x, y);
      }
    }
    fill.lineTo(size.width, size.height);
    fill.close();

    canvas.drawPath(fill, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.strokeColor != strokeColor;
}

class TelemetryMetricCard extends StatelessWidget {
  const TelemetryMetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.history,
    this.tone = AppStatusTone.active,
  });

  final String label;
  final String value;
  final String unit;
  final List<double> history;
  final AppStatusTone tone;

  Color get _accent {
    switch (tone) {
      case AppStatusTone.active:
        return AppColors.emerald;
      case AppStatusTone.idle:
        return AppColors.gray500;
      case AppStatusTone.warning:
        return AppColors.ruby;
      case AppStatusTone.muted:
        return AppColors.gray400;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: _accent,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
              const SizedBox(width: 4),
              Text(unit, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 14),
          Sparkline(values: history, strokeColor: _accent),
        ],
      ),
    );
  }
}

class TelemetryMiniStrip extends StatelessWidget {
  const TelemetryMiniStrip({super.key, required this.reading, required this.live});

  final TelemetryReading? reading;
  final bool live;

  @override
  Widget build(BuildContext context) {
    if (reading == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          'Telemetry paused — enable protection to stream readings.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          LivePulse(active: live),
          const SizedBox(width: 16),
          Expanded(
            child: Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _MiniStat(
                  label: 'Signal',
                  value: '${reading!.signalStrength.toStringAsFixed(0)} dBm',
                ),
                _MiniStat(
                  label: 'Temp',
                  value: '${reading!.temperatureC.toStringAsFixed(0)} °C',
                ),
                _MiniStat(
                  label: 'Loss',
                  value: '${reading!.packetLossPercent.toStringAsFixed(0)}%',
                ),
                _MiniStat(label: 'Status', value: reading!.status),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label ', style: Theme.of(context).textTheme.labelSmall),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.text,
                fontWeight: FontWeight.w600,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
        ),
      ],
    );
  }
}

AppStatusTone toneForReading(TelemetryReading reading) {
  if (reading.status == 'under_attack' ||
      reading.status == 'isolated' ||
      reading.status == 'degraded') {
    return AppStatusTone.warning;
  }
  if (reading.status == 'elevated') return AppStatusTone.idle;
  return AppStatusTone.active;
}

String formatTelemetryTime(DateTime time) {
  final utc = time.toUtc();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(utc.hour)}:${two(utc.minute)}:${two(utc.second)} UTC';
}
