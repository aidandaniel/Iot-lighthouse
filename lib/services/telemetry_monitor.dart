import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../models/device_models.dart';

/// Synthetic live telemetry for demo devices — random-walk readings per asset.
class TelemetryMonitor extends ChangeNotifier {
  TelemetryMonitor({this.tickInterval = const Duration(seconds: 3)});

  final Duration tickInterval;
  final _history = <String, List<TelemetryReading>>{};
  final _rng = math.Random();
  Timer? _timer;
  List<ProtectedDevice> _devices = const [];
  final _underAttack = <String>{};

  static const historyLimit = 48;

  bool isUnderAttack(String deviceId) => _underAttack.contains(deviceId);

  List<TelemetryReading> historyFor(String deviceId) =>
      List.unmodifiable(_history[deviceId] ?? const []);

  TelemetryReading? latestFor(String deviceId) {
    final h = _history[deviceId];
    if (h == null || h.isEmpty) return null;
    return h.last;
  }

  bool get isRunning => _timer != null;

  void start(List<ProtectedDevice> devices) {
    _devices = devices;
    for (final device in devices) {
      _seed(device);
    }
    _timer?.cancel();
    _timer = Timer.periodic(tickInterval, (_) => _tick());
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    notifyListeners();
  }

  void syncDevices(List<ProtectedDevice> devices) {
    _devices = devices;
    for (final device in devices) {
      if (!_history.containsKey(device.id)) {
        _seed(device);
      }
    }
  }

  /// Demo: spike telemetry to mimic an AI-driven signaling attack.
  void simulateAttack(String deviceId) {
    _underAttack.add(deviceId);
    final now = DateTime.now().toUtc();
    final spikes = <TelemetryReading>[
      TelemetryReading(
        deviceId: deviceId,
        recordedAt: now.subtract(const Duration(seconds: 6)),
        signalStrength: -74,
        temperatureC: 49,
        packetLossPercent: 18,
        status: 'elevated',
      ),
      TelemetryReading(
        deviceId: deviceId,
        recordedAt: now.subtract(const Duration(seconds: 3)),
        signalStrength: -82,
        temperatureC: 54,
        packetLossPercent: 28,
        status: 'degraded',
      ),
      TelemetryReading(
        deviceId: deviceId,
        recordedAt: now,
        signalStrength: -91,
        temperatureC: 61,
        packetLossPercent: 41,
        status: 'under_attack',
      ),
    ];

    final list = List<TelemetryReading>.from(_history[deviceId] ?? [])
      ..addAll(spikes);
    if (list.length > historyLimit) {
      list.removeRange(0, list.length - historyLimit);
    }
    _history[deviceId] = list;
    notifyListeners();
  }

  void stopAttack(String deviceId) {
    if (_underAttack.remove(deviceId)) {
      notifyListeners();
    }
  }

  void _seed(ProtectedDevice device) {
    final profile = _profileFor(device);
    final now = DateTime.now().toUtc();
    final points = <TelemetryReading>[];
    var signal = profile.signalBase;
    var temp = profile.tempBase;
    var loss = profile.lossBase;

    for (var i = historyLimit - 1; i >= 0; i -= 1) {
      signal = _jitter(signal, profile.signalSwing, -95, -45);
      temp = _jitter(temp, 1.2, 28, 62);
      loss = _jitter(loss, 1.5, 0, 22).clamp(0, 100).toDouble();
      points.add(
        TelemetryReading(
          deviceId: device.id,
          recordedAt: now.subtract(Duration(seconds: i * 3)),
          signalStrength: signal,
          temperatureC: temp,
          packetLossPercent: loss,
          status: _statusFor(device, loss, signal),
        ),
      );
    }
    _history[device.id] = points;
  }

  void _tick() {
    for (final device in _devices) {
      if (!_shouldStream(device)) continue;
      final profile = _profileFor(device);
      final prev = latestFor(device.id);
      final loss = _underAttack.contains(device.id)
          ? _jitter(
              prev?.packetLossPercent ?? 35,
              3,
              22,
              55,
            ).clamp(0, 100).toDouble()
          : _jitter(
              prev?.packetLossPercent ?? profile.lossBase,
              1.2,
              0,
              22,
            ).clamp(0, 100).toDouble();
      final signal = _underAttack.contains(device.id)
          ? _jitter(prev?.signalStrength ?? -88, 2, -95, -78)
          : _jitter(
              prev?.signalStrength ?? profile.signalBase,
              profile.signalSwing,
              -95,
              -45,
            );
      final temp = _underAttack.contains(device.id)
          ? _jitter(prev?.temperatureC ?? 58, 1.5, 48, 68)
          : _jitter(
              prev?.temperatureC ?? profile.tempBase,
              0.9,
              28,
              62,
            );

      final reading = TelemetryReading(
        deviceId: device.id,
        recordedAt: DateTime.now().toUtc(),
        signalStrength: signal,
        temperatureC: temp,
        packetLossPercent: loss,
        status: _statusFor(device, loss, signal),
      );

      final list = List<TelemetryReading>.from(_history[device.id] ?? [])
        ..add(reading);
      if (list.length > historyLimit) {
        list.removeRange(0, list.length - historyLimit);
      }
      _history[device.id] = list;
    }
    notifyListeners();
  }

  bool _shouldStream(ProtectedDevice device) {
    if (device.protectionState == ProtectionState.disabled) return false;
    return true;
  }

  String _statusFor(ProtectedDevice device, double loss, double signal) {
    if (_underAttack.contains(device.id)) return 'under_attack';
    if (device.protectionState == ProtectionState.isolated) return 'isolated';
    if (loss >= 15 || signal <= -78) return 'degraded';
    if (loss >= 8 || signal <= -70) return 'elevated';
    return 'normal';
  }

  double _jitter(double value, double swing, double min, double max) {
    final next = value + (_rng.nextDouble() * 2 - 1) * swing;
    return next.clamp(min, max);
  }

  _DeviceProfile _profileFor(ProtectedDevice device) {
    return _profiles[device.id] ??
        const _DeviceProfile(
          signalBase: -62,
          signalSwing: 2.5,
          tempBase: 42,
          lossBase: 5,
        );
  }

  static const _profiles = <String, _DeviceProfile>{
    'diameter-edge-001': _DeviceProfile(
      signalBase: -58,
      signalSwing: 2,
      tempBase: 41,
      lossBase: 3,
    ),
    'ss7-gateway-002': _DeviceProfile(
      signalBase: -64,
      signalSwing: 3,
      tempBase: 47,
      lossBase: 7,
    ),
    'hss-proxy-001': _DeviceProfile(
      signalBase: -66,
      signalSwing: 2.5,
      tempBase: 39,
      lossBase: 4,
    ),
    'routing-firewall-001': _DeviceProfile(
      signalBase: -72,
      signalSwing: 4,
      tempBase: 52,
      lossBase: 14,
    ),
    'interconnect-probe-001': _DeviceProfile(
      signalBase: -71,
      signalSwing: 2,
      tempBase: 34,
      lossBase: 2,
    ),
  };

  @override
  void dispose() {
    stop();
    super.dispose();
  }
}

class _DeviceProfile {
  const _DeviceProfile({
    required this.signalBase,
    required this.signalSwing,
    required this.tempBase,
    required this.lossBase,
  });

  final double signalBase;
  final double signalSwing;
  final double tempBase;
  final double lossBase;
}
