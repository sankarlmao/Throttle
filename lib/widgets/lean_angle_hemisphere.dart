import 'dart:math';
import 'package:flutter/material.dart';

class LeanAngleHemisphere extends StatelessWidget {
  final double currentLeanAngle;
  final double maxLeanRight;
  final double maxLeanLeft;
  final double currentSpeedKmh;
  final Color helmetColor;

  const LeanAngleHemisphere({
    Key? key,
    required this.currentLeanAngle,
    required this.maxLeanRight,
    required this.maxLeanLeft,
    required this.currentSpeedKmh,
    this.helmetColor = const Color(0xFFFF5722), // Default Racing Orange
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      width: double.infinity,
      height: 240,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF161916),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // 1. Shift Lights (F1/MotoGP Style Rev bar)
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: _buildShiftLightsBar(currentSpeedKmh),
          ),

          // 2. Custom Painter for Dial, Arcs, and Rotating Bike
          Positioned(
            top: 45,
            bottom: 10,
            left: 20,
            right: 20,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: currentLeanAngle),
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOutCubic,
              builder: (context, animatedAngle, child) {
                return CustomPaint(
                  painter: _MotoGPTelemetryPainter(
                    leanAngle: animatedAngle,
                    maxLeanLeft: maxLeanLeft,
                    maxLeanRight: maxLeanRight,
                    helmetColor: helmetColor,
                    speedKmh: currentSpeedKmh,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Build the horizontal LED rev bar at the top
  Widget _buildShiftLightsBar(double speed) {
    // Gear and RPM simulation
    int gear = 1;
    double rpm = 1500;
    double maxRpm = 14000;
    
    if (speed == 0) {
      gear = 1;
      rpm = 1500;
    } else if (speed < 35) {
      gear = 1;
      rpm = 1500 + (speed / 35) * (11500 - 1500);
    } else if (speed < 65) {
      gear = 2;
      rpm = 4000 + ((speed - 35) / (65 - 35)) * (12000 - 4000);
    } else if (speed < 95) {
      gear = 3;
      rpm = 5000 + ((speed - 65) / (95 - 65)) * (12500 - 5000);
    } else if (speed < 125) {
      gear = 4;
      rpm = 6000 + ((speed - 95) / (125 - 95)) * (12800 - 6000);
    } else if (speed < 155) {
      gear = 5;
      rpm = 7000 + ((speed - 125) / (155 - 125)) * (13200 - 7000);
    } else {
      gear = 6;
      rpm = 8000 + ((speed - 155) / 100) * (13500 - 8000);
      if (rpm > maxRpm) rpm = maxRpm;
    }

    final double rpmPercent = (rpm / maxRpm).clamp(0.0, 1.0);
    final int totalLeds = 12;
    final int litLeds = (rpmPercent * totalLeds).round();
    final bool isFlashing = rpmPercent > 0.88; // Redline flash

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "RPM  ${rpm.round()}",
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: isFlashing ? const Color(0xFFFF1744) : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                "GEAR $gear",
                style: TextStyle(
                  color: isFlashing ? Colors.white : const Color(0xFFFFE082),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // LED Bar
        _LedIndicatorBar(
          litCount: litLeds,
          totalCount: totalLeds,
          flashing: isFlashing,
        ),
      ],
    );
  }
}

class _LedIndicatorBar extends StatefulWidget {
  final int litCount;
  final int totalCount;
  final bool flashing;

  const _LedIndicatorBar({
    Key? key,
    required this.litCount,
    required this.totalCount,
    required this.flashing,
  }) : super(key: key);

  @override
  State<_LedIndicatorBar> createState() => _LedIndicatorBarState();
}

class _LedIndicatorBarState extends State<_LedIndicatorBar> with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Color _getLedColor(int index, int total) {
    if (index < total * 0.4) {
      return const Color(0xFF00E676); // Green LEDs (0-40%)
    } else if (index < total * 0.75) {
      return const Color(0xFFFFD700); // Yellow/Orange LEDs (40-75%)
    } else if (index < total * 0.9) {
      return const Color(0xFFFF3D00); // Red LEDs (75-90%)
    } else {
      return const Color(0xFF2979FF); // Blue Shift LEDs (90%+)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, child) {
        final bool showFlashingLeds = !widget.flashing || (_blinkController.value > 0.5);
        return Row(
          children: List.generate(widget.totalCount, (index) {
            final bool isLit = index < widget.litCount;
            final Color baseColor = _getLedColor(index, widget.totalCount);
            final Color ledColor = (isLit && showFlashingLeds) ? baseColor : const Color(0xFF222522);
            
            return Expanded(
              child: Container(
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: ledColor,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: (isLit && showFlashingLeds)
                      ? [
                          BoxShadow(
                            color: baseColor.withOpacity(0.6),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _MotoGPTelemetryPainter extends CustomPainter {
  final double leanAngle;
  final double maxLeanLeft;
  final double maxLeanRight;
  final Color helmetColor;
  final double speedKmh;

  _MotoGPTelemetryPainter({
    required this.leanAngle,
    required this.maxLeanLeft,
    required this.maxLeanRight,
    required this.helmetColor,
    required this.speedKmh,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height - 35; // Position contacting tire
    final Offset center = Offset(centerX, centerY);
    final double dialRadius = min(size.width / 2.3, size.height - 50);

    // 1. Draw Dial Track (Background gauge ring)
    final Paint trackPaint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    
    // Sweeps from 210 degrees to 330 degrees (i.e. -60 to +60 degrees from vertical vertical)
    // 0 is right, pi/2 is down, pi is left, 1.5*pi (270deg) is vertical-up.
    // Start angle: 1.5*pi - 60*pi/180 = 270 - 60 = 210 deg
    // Sweep angle: 120 deg
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: dialRadius),
      (1.5 * pi) - (60.0 * pi / 180.0),
      120.0 * pi / 180.0,
      false,
      trackPaint,
    );

    // 2. Draw Lean Arcs (Visualizing active lean angle)
    if (leanAngle.abs() > 0.5) {
      final Paint arcPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round;

      final double angleRad = (leanAngle * pi / 180.0);
      final double startAngleRad = 1.5 * pi; // straight up

      // Set gradient based on lean severity
      final Color arcColor = leanAngle.abs() > 45
          ? const Color(0xFFFF1744) // Danger Red
          : leanAngle.abs() > 30
              ? const Color(0xFFFF9100) // Warning Orange
              : const Color(0xFF00E676); // Safe Green

      arcPaint.color = arcColor;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: dialRadius),
        startAngleRad,
        angleRad,
        false,
        arcPaint,
      );

      // Neon Arc glow effect
      final Paint glowPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = arcColor.withOpacity(0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: dialRadius),
        startAngleRad,
        angleRad,
        false,
        glowPaint,
      );
    }

    // 3. Draw Ticks & Labels (-60, -45, -30, 0, 30, 45, 60)
    final List<double> ticks = [-60, -45, -30, 0, 30, 45, 60];
    final Paint tickPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var deg in ticks) {
      double angleRad = (1.5 * pi) + (deg * pi / 180.0);
      Offset inner = Offset(
        centerX + (dialRadius - 6) * cos(angleRad),
        centerY + (dialRadius - 6) * sin(angleRad),
      );
      Offset outer = Offset(
        centerX + (dialRadius + 6) * cos(angleRad),
        centerY + (dialRadius + 6) * sin(angleRad),
      );

      tickPaint.color = deg == 0 
          ? Colors.white.withOpacity(0.6) 
          : Colors.white.withOpacity(0.2);
      
      canvas.drawLine(inner, outer, tickPaint);

      // Text Labels
      final String labelText = "${deg.abs().round()}°";
      final TextSpan span = TextSpan(
        text: labelText,
        style: TextStyle(
          color: deg == 0 
              ? Colors.white.withOpacity(0.8) 
              : Colors.white.withOpacity(0.3),
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      double labelRadius = dialRadius + 18;
      double labelX = centerX + labelRadius * cos(angleRad) - tp.width / 2;
      double labelY = centerY + labelRadius * sin(angleRad) - tp.height / 2;

      tp.paint(canvas, Offset(labelX, labelY));
    }

    // 4. Draw Max Lean Markers (Lines + text)
    if (maxLeanLeft > 1.0) {
      double angleRad = (1.5 * pi) - (maxLeanLeft * pi / 180.0);
      final Paint maxPaint = Paint()
        ..color = const Color(0xFFFF1744).withOpacity(0.8)
        ..strokeWidth = 2.5;

      Offset inner = Offset(centerX + (dialRadius - 10) * cos(angleRad), centerY + (dialRadius - 10) * sin(angleRad));
      Offset outer = Offset(centerX + (dialRadius + 10) * cos(angleRad), centerY + (dialRadius + 10) * sin(angleRad));
      canvas.drawLine(inner, outer, maxPaint);

      // Print MAX text near bottom left
      final TextSpan span = TextSpan(
        text: "MAX L\n${maxLeanLeft.round()}°",
        style: const TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      );
      final TextPainter tp = TextPainter(text: span, textDirection: TextDirection.ltr)..layout();
      tp.paint(canvas, Offset(20, size.height - 40));
    }

    if (maxLeanRight > 1.0) {
      double angleRad = (1.5 * pi) + (maxLeanRight * pi / 180.0);
      final Paint maxPaint = Paint()
        ..color = const Color(0xFFFF1744).withOpacity(0.8)
        ..strokeWidth = 2.5;

      Offset inner = Offset(centerX + (dialRadius - 10) * cos(angleRad), centerY + (dialRadius - 10) * sin(angleRad));
      Offset outer = Offset(centerX + (dialRadius + 10) * cos(angleRad), centerY + (dialRadius + 10) * sin(angleRad));
      canvas.drawLine(inner, outer, maxPaint);

      // Print MAX text near bottom right
      final TextSpan span = TextSpan(
        text: "MAX R\n${maxLeanRight.round()}°",
        style: const TextStyle(
          color: Color(0xFFFF1744),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          height: 1.1,
        ),
      );
      final TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.end,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width - 20, size.height - 40));
    }

    // 5. Draw Digital Lean Angle Display (Center bottom)
    final String mainLeanText = "${leanAngle.abs().round()}°";
    final String leanDirText = leanAngle.round() == 0 
        ? "UPRIGHT" 
        : leanAngle > 0 
            ? "LEAN RIGHT" 
            : "LEAN LEFT";
    
    final TextSpan leanAngleSpan = TextSpan(
      text: mainLeanText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.w900,
        letterSpacing: -1.0,
      ),
    );
    final TextPainter leanAngleTp = TextPainter(
      text: leanAngleSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    leanAngleTp.paint(canvas, Offset(centerX - leanAngleTp.width / 2, centerY - 145));

    final TextSpan leanDirSpan = TextSpan(
      text: leanDirText,
      style: TextStyle(
        color: leanAngle.abs() > 45 
            ? const Color(0xFFFF1744) 
            : leanAngle.abs() > 30 
                ? const Color(0xFFFF9100) 
                : Colors.white54,
        fontSize: 10,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.5,
      ),
    );
    final TextPainter leanDirTp = TextPainter(
      text: leanDirSpan,
      textDirection: TextDirection.ltr,
    )..layout();
    leanDirTp.paint(canvas, Offset(centerX - leanDirTp.width / 2, centerY - 105));

    // 6. Draw Rotating Motorcycle Silhouette (In center of rotation)
    canvas.save();
    canvas.translate(centerX, centerY - 15);
    canvas.rotate(leanAngle * pi / 180.0);
    
    // Draw bike body relative to (0, 0)
    // 0, 0 is the contact patch of the tire.
    // So tire is from y = 0 to y = -35.
    // Body is from y = -35 to y = -95.
    
    // 1. Draw Tire (black/dark grey pill)
    final Paint tirePaint = Paint()
      ..color = const Color(0xFF242724)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(-9, -35, 9, 0),
        const Radius.circular(8),
      ),
      tirePaint,
    );
    
    final Paint rimPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(const Offset(0, -18), 7, rimPaint);

    // 2. Draw swingarm & exhaust pipes
    final Paint metalPaint = Paint()
      ..color = const Color(0xFF4A4E4A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawLine(const Offset(-5, -18), const Offset(-13, -40), metalPaint); // Swingarm
    canvas.drawLine(const Offset(6, -18), const Offset(13, -38), metalPaint); // Exhaust pipe

    // 3. Fairing body (using team helmetColor!)
    final Paint bodyPaint = Paint()
      ..color = helmetColor
      ..style = PaintingStyle.fill;
    
    final Path tailPath = Path()
      ..moveTo(-15, -35)
      ..lineTo(15, -35)
      ..lineTo(11, -65)
      ..lineTo(0, -74)
      ..lineTo(-11, -65)
      ..close();
    canvas.drawPath(tailPath, bodyPaint);

    // 4. Glowing Red Tail Light
    final Paint tailLightPaint = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;
    final Path lightPath = Path()
      ..moveTo(-5, -60)
      ..lineTo(5, -60)
      ..lineTo(0, -66)
      ..close();
    canvas.drawPath(lightPath, tailLightPaint);
    
    final Paint lightGlow = Paint()
      ..color = const Color(0xFFFF1744).withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawCircle(const Offset(0, -62), 4, lightGlow);

    // 5. Rider black racing suit shoulders
    final Paint suitPaint = Paint()
      ..color = const Color(0xFF1E211E)
      ..style = PaintingStyle.fill;
    final Path riderPath = Path()
      ..moveTo(-24, -65)
      ..lineTo(24, -65)
      ..lineTo(16, -88)
      ..lineTo(-16, -88)
      ..close();
    canvas.drawPath(riderPath, suitPaint);

    // 6. Handlebars
    final Paint barPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawLine(const Offset(-26, -68), const Offset(26, -68), barPaint);
    
    // 7. Rider Helmet
    final Paint helmetPaint = Paint()
      ..color = helmetColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(0, -92), 9, helmetPaint);
    
    // Helmet Visor
    final Paint visorPaint = Paint()
      ..color = const Color(0xFF282828)
      ..style = PaintingStyle.fill;
    final Path visorPath = Path()
      ..moveTo(-6, -94)
      ..lineTo(6, -94)
      ..lineTo(4, -89)
      ..lineTo(-4, -89)
      ..close();
    canvas.drawPath(visorPath, visorPaint);
    
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MotoGPTelemetryPainter oldDelegate) {
    return oldDelegate.leanAngle != leanAngle ||
        oldDelegate.maxLeanLeft != maxLeanLeft ||
        oldDelegate.maxLeanRight != maxLeanRight ||
        oldDelegate.helmetColor != helmetColor ||
        oldDelegate.speedKmh != speedKmh;
  }
}
