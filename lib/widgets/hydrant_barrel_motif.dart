import 'package:flutter/material.dart';
import 'package:drafting_the_hydrant_valve/enum/hydrant_enums.dart';
import 'package:drafting_the_hydrant_valve/utils/const.dart';

/// Minimal Board of Works hydrant barrel cross-section motif.
class HydrantBarrelPainter extends CustomPainter {
  final FootValveGateStyle valveStyle;
  final Color color;
  final double boreRatio;

  HydrantBarrelPainter({
    required this.valveStyle,
    required this.color,
    double? boreRatio,
  }) : boreRatio = boreRatio ?? valveStyle.motifBoreRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fill = Paint()
      ..color = color.withAlpha(22)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final top = size.height * 0.08;
    final bottom = size.height * 0.92;
    final outerW = size.width * 0.42;
    final frostW = size.width * 0.56;
    final boreW = outerW * boreRatio.clamp(0.3, 0.85);

    // Frost case sleeve — outer concentric rectangle
    final frostRect = Rect.fromCenter(
      center: Offset(cx, (top + bottom) / 2),
      width: frostW,
      height: bottom - top,
    );
    canvas.drawRect(frostRect, paint..strokeWidth = 1.0);
    canvas.drawRect(frostRect.deflate(2), fill);

    // Barrel outer wall
    final barrelLeft = cx - outerW / 2;
    final barrelRight = cx + outerW / 2;
    canvas.drawRect(
      Rect.fromLTRB(barrelLeft, top + size.height * 0.12, barrelRight, bottom),
      paint..strokeWidth = 1.4,
    );

    // Bore — parallel inner lines
    final boreLeft = cx - boreW / 2;
    final boreRight = cx + boreW / 2;
    final borePaint = Paint()
      ..color = color.withAlpha(160)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;
    canvas.drawLine(
      Offset(boreLeft, top + size.height * 0.18),
      Offset(boreLeft, bottom - size.height * 0.12),
      borePaint,
    );
    canvas.drawLine(
      Offset(boreRight, top + size.height * 0.18),
      Offset(boreRight, bottom - size.height * 0.12),
      borePaint,
    );

    // Operating nut — square section at top
    final nutSize = size.width * 0.22;
    final nutRect = Rect.fromCenter(
      center: Offset(cx, top + size.height * 0.06),
      width: nutSize,
      height: nutSize * 0.7,
    );
    canvas.drawRect(nutRect, paint..strokeWidth = 1.3);
    // Drive ratio gear tick marks
    for (int i = 0; i < 4; i++) {
      final x = cx + (i.isEven ? -nutSize * 0.15 : nutSize * 0.15);
      canvas.drawLine(
        Offset(x, nutRect.top),
        Offset(x, nutRect.top - 3),
        paint..strokeWidth = 0.8,
      );
    }

    // Foot valve flap at base with leather seal indication
    final flapY = bottom - size.height * 0.06;
    final flapPaint = Paint()
      ..color = valveStyle.usesLeather ? kLeather : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(barrelLeft + 2, flapY),
      Offset(barrelRight - 2, flapY),
      flapPaint,
    );
    // Hinge arc suggesting flap gate
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(barrelLeft + 4, flapY),
        width: 10,
        height: 10,
      ),
      -0.4,
      1.2,
      false,
      flapPaint..strokeWidth = 1.0,
    );
  }

  @override
  bool shouldRepaint(covariant HydrantBarrelPainter old) =>
      old.valveStyle != valveStyle ||
      old.color != color ||
      old.boreRatio != boreRatio;
}

Widget hydrantBarrelIcon({
  required FootValveGateStyle valveStyle,
  required HeadSimulationStatus status,
  double size = 36,
}) {
  final color = isHydraulicallyIntact(status)
      ? kAccent
      : (valveStyle.usesLeather ? kLeather : kSecondaryText);
  return SizedBox(
    width: size,
    height: size,
    child: CustomPaint(
      painter: HydrantBarrelPainter(
        valveStyle: valveStyle,
        color: color,
      ),
    ),
  );
}
