import 'dart:math';
import 'package:flutter/material.dart';

class LeanAngleHemisphere extends StatelessWidget {
  final double currentLeanAngle;
  final double maxLeanRight;
  final double maxLeanLeft;

  const LeanAngleHemisphere({
    Key? key,
    required this.currentLeanAngle,
    required this.maxLeanRight,
    required this.maxLeanLeft,
  }) : super(key: key);

  @override
  Widget build(key) {
    // Select the side with the larger absolute maximum lean angle to display the max dot
    final double maxAngleValue;
    final bool isMaxRight;
    if (maxLeanRight >= maxLeanLeft) {
      maxAngleValue = maxLeanRight;
      isMaxRight = true;
    } else {
      maxAngleValue = maxLeanLeft;
      isMaxRight = false;
    }

    return Container(
      width: 260,
      height: 155,
      padding: const EdgeInsets.only(top: 10),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Smoothly animate the needle movement
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: currentLeanAngle),
            duration: const Duration(milliseconds: 100),
            builder: (context, animatedAngle, child) {
              return CustomPaint(
                size: const Size(240, 130),
                painter: _HemispherePainter(
                  leanAngle: animatedAngle,
                  maxLean: maxAngleValue,
                  isMaxRight: isMaxRight,
                  theme: Theme.of(context),
                ),
              );
            },
          ),
          // Lean Angle Text in the Center/Bottom area
          Positioned(
            bottom: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatLeanAngleText(currentLeanAngle),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "LEAN ANGLE",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.5),
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatLeanAngleText(double angle) {
    final int rounded = angle.round();
    if (rounded == 0) return "0°";
    if (rounded > 0) return "${rounded}° R";
    return "${rounded.abs()}° L";
  }
}

class _HemispherePainter extends CustomPainter {
  final double leanAngle; // in degrees, positive = right, negative = left
  final double maxLean;   // in degrees, absolute positive value of max reached
  final bool isMaxRight;  // true if max lean was to the right, false if left
  final ThemeData theme;

  _HemispherePainter({
    required this.leanAngle,
    required this.maxLean,
    required this.isMaxRight,
    required this.theme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height;
    final Offset center = Offset(centerX, centerY);
    final double radius = min(size.width / 2 - 12, size.height - 12);

    // Paints
    final Paint trackPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final Paint dangerPaint = Paint()
      ..color = const Color(0xFFD32F2F).withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    // Draw base semicircle (from pi to 2*pi, i.e., 180 degrees)
    // In Flutter: 0 is right, pi/2 is down, pi is left, 1.5*pi is up.
    // So to draw a flat-side-down semicircle facing up: start at pi (left) and sweep pi (clockwise to right).
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi,
      false,
      trackPaint,
    );

    // Draw danger zones: leftmost 30 degrees (from pi to pi + pi/6)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      pi,
      pi / 6,
      false,
      dangerPaint,
    );

    // Draw danger zones: rightmost 30 degrees (from 2*pi - pi/6 to 2*pi)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      2 * pi - pi / 6,
      pi / 6,
      false,
      dangerPaint,
    );

    // Draw Ticks and Labels (0, 45L, 45R, 90L, 90R)
    final List<double> tickAngles = [-90, -45, 0, 45, 90];
    final List<String> tickLabels = ["90°L", "45°L", "0°", "45°R", "90°R"];

    for (int i = 0; i < tickAngles.length; i++) {
      double angleDeg = tickAngles[i];
      // Angle in radians: 0 lean is 1.5*pi (straight up)
      double angleRad = (1.5 * pi) + (angleDeg * pi / 180.0);

      // Tick mark lines
      double innerRadius = radius - 8;
      double outerRadius = radius + 8;

      Offset startOffset = Offset(
        centerX + innerRadius * cos(angleRad),
        centerY + innerRadius * sin(angleRad),
      );
      Offset endOffset = Offset(
        centerX + outerRadius * cos(angleRad),
        centerY + outerRadius * sin(angleRad),
      );

      final Paint tickPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawLine(startOffset, endOffset, tickPaint);

      // Labels
      final TextSpan span = TextSpan(
        text: tickLabels[i],
        style: TextStyle(
          color: Colors.white.withOpacity(0.4),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      tp.layout();

      // Position labels slightly outside the ticks
      double labelRadius = radius + 20;
      double labelX = centerX + labelRadius * cos(angleRad) - tp.width / 2;
      double labelY = centerY + labelRadius * sin(angleRad) - tp.height / 2;

      // Adjust specifically for 90L and 90R to avoid clipping
      if (angleDeg == -90) labelX += 4;
      if (angleDeg == 90) labelX -= 4;

      tp.paint(canvas, Offset(labelX, labelY));
    }

    // Draw Max Lean Dot if > 0
    if (maxLean > 0) {
      double maxAngleDeg = isMaxRight ? maxLean : -maxLean;
      double maxAngleRad = (1.5 * pi) + (maxAngleDeg * pi / 180.0);

      Offset maxDotPos = Offset(
        centerX + radius * cos(maxAngleRad),
        centerY + radius * sin(maxAngleRad),
      );

      final Paint maxDotPaint = Paint()
        ..color = const Color(0xFFF44336) // Red
        ..style = PaintingStyle.fill;

      final Paint maxDotOuterPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Draw red dot on the arc
      canvas.drawCircle(maxDotPos, 6, maxDotPaint);
      canvas.drawCircle(maxDotPos, 6, maxDotOuterPaint);

      // Draw Max Label near the dot
      final TextSpan labelSpan = TextSpan(
        text: "MAX\n${maxLean.round()}°",
        style: const TextStyle(
          color: Color(0xFFF44336),
          fontSize: 9,
          fontWeight: FontWeight.bold,
          height: 1.1,
        ),
      );
      final TextPainter labelTp = TextPainter(
        text: labelSpan,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      labelTp.layout();

      // Position text outside the dot
      double textRadius = radius - 26; // place inside the arc to not overlap with ticks
      if (maxLean < 25) {
        textRadius = radius - 30; // push further inside near the top
      }
      double textX = centerX + textRadius * cos(maxAngleRad) - labelTp.width / 2;
      double textY = centerY + textRadius * sin(maxAngleRad) - labelTp.height / 2;

      labelTp.paint(canvas, Offset(textX, textY));
    }

    // Draw Needle (Roll angle)
    double needleRad = (1.5 * pi) + (leanAngle * pi / 180.0);
    double needleLength = radius - 5;

    Offset needleTip = Offset(
      centerX + needleLength * cos(needleRad),
      centerY + needleLength * sin(needleRad),
    );

    final Paint needlePaint = Paint()
      ..color = const Color(0xFF64B5F6) // Light blue primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Draw Needle Pivot Joint (Circle at the bottom-center)
    final Paint pivotPaint = Paint()
      ..color = const Color(0xFF64B5F6)
      ..style = PaintingStyle.fill;
    final Paint pivotRingPaint = Paint()
      ..color = const Color(0xFF111111)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawCircle(center, 8, pivotPaint);
    canvas.drawCircle(center, 8, pivotRingPaint);
  }

  @override
  bool shouldRepaint(covariant _HemispherePainter oldDelegate) {
    return oldDelegate.leanAngle != leanAngle ||
        oldDelegate.maxLean != maxLean ||
        oldDelegate.isMaxRight != isMaxRight;
  }
}
