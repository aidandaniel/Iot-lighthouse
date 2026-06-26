import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WorldMapRoute extends StatefulWidget {
  const WorldMapRoute({
    super.key,
    required this.fromAtSign,
    required this.toAtSign,
  });

  final String fromAtSign;
  final String toAtSign;

  @override
  State<WorldMapRoute> createState() => _WorldMapRouteState();
}

class _WorldMapRouteState extends State<WorldMapRoute>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.gray100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return CustomPaint(
              painter: _WorldMapPainter(
                progress: _ctrl.value,
                fromAtSign: widget.fromAtSign,
                toAtSign: widget.toAtSign,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WorldMapPainter extends CustomPainter {
  _WorldMapPainter({
    required this.progress,
    required this.fromAtSign,
    required this.toAtSign,
  });

  final double progress;
  final String fromAtSign;
  final String toAtSign;

  @override
  void paint(Canvas canvas, Size size) {
    _drawMap(canvas, size);
    _drawRoute(canvas, size);
  }

  void _drawMap(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray300
      ..style = PaintingStyle.fill;

    const spacing = 6.0;
    const dotRadius = 1.5;

    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final nx = x / size.width;
        final ny = y / size.height;

        if (_isLand(nx, ny)) {
          canvas.drawCircle(Offset(x, y), dotRadius, paint);
        }
      }
    }
  }

  bool _isLand(double nx, double ny) {
    bool inEllipse(double cx, double cy, double rx, double ry) {
      final dx = (nx - cx) / rx;
      final dy = (ny - cy) / ry;
      return (dx * dx + dy * dy) <= 1.0;
    }

    // Abstract continent shapes
    if (inEllipse(0.2, 0.3, 0.12, 0.18)) return true; // NA
    if (inEllipse(0.15, 0.15, 0.1, 0.1)) return true; // NA Top
    if (inEllipse(0.3, 0.65, 0.08, 0.18)) return true; // SA
    if (inEllipse(0.5, 0.25, 0.08, 0.1)) return true; // EU
    if (inEllipse(0.53, 0.5, 0.1, 0.18)) return true; // AF
    if (inEllipse(0.75, 0.28, 0.18, 0.15)) return true; // AS
    if (inEllipse(0.7, 0.45, 0.08, 0.1)) return true; // SE AS
    if (inEllipse(0.85, 0.75, 0.06, 0.08)) return true; // AU
    if (inEllipse(0.35, 0.1, 0.05, 0.05)) return true; // GL

    return false;
  }

  void _drawRoute(Canvas canvas, Size size) {
    // Define start (NA) and end (EU)
    final start = Offset(size.width * 0.25, size.height * 0.35);
    final end = Offset(size.width * 0.5, size.height * 0.25);

    // Draw connection line
    final path = Path();
    path.moveTo(start.dx, start.dy);
    
    // Control point for curve
    final cp = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - 40,
    );
    
    path.quadraticBezierTo(cp.dx, cp.dy, end.dx, end.dy);

    // Draw dashed/faded line
    final linePaint = Paint()
      ..color = AppColors.emerald.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(path, linePaint);

    // Calculate current particle position
    final t = progress;
    final px = _quadBezier(start.dx, cp.dx, end.dx, t);
    final py = _quadBezier(start.dy, cp.dy, end.dy, t);
    final particle = Offset(px, py);

    // Draw particle
    final particlePaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    canvas.drawCircle(particle, 4.0, particlePaint);
    
    final corePaint = Paint()
      ..color = AppColors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(particle, 2.0, corePaint);

    // Draw endpoints
    _drawNode(canvas, start, fromAtSign);
    _drawNode(canvas, end, toAtSign);
  }

  double _quadBezier(double p0, double p1, double p2, double t) {
    final mt = 1.0 - t;
    return mt * mt * p0 + 2.0 * mt * t * p1 + t * t * p2;
  }

  void _drawNode(Canvas canvas, Offset pos, String label) {
    final nodePaint = Paint()
      ..color = AppColors.black
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = AppColors.emerald
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(pos, 6.0, nodePaint);
    canvas.drawCircle(pos, 6.0, borderPaint);

    // Draw label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: AppColors.black,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    
    // Background for text
    final bgRect = Rect.fromCenter(
      center: Offset(pos.dx, pos.dy + 16),
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    final bgPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(2)),
      bgPaint,
    );
    
    textPainter.paint(
      canvas,
      Offset(pos.dx - textPainter.width / 2, pos.dy + 16 - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _WorldMapPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.fromAtSign != fromAtSign ||
           oldDelegate.toAtSign != toAtSign;
  }
}
