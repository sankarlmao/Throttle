import 'dart:math' as math;
import 'package:flutter/material.dart';

class SpeedGraph extends StatelessWidget {
  final List<double> speeds;
  final Color lineColor;
  final double height;

  const SpeedGraph({
    Key? key,
    required this.speeds,
    required this.lineColor,
    this.height = 150.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (speeds.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFF161916),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: const Center(
          child: Text(
            "Telemetry Speed Data Offline",
            style: TextStyle(color: Colors.white30, fontSize: 12, letterSpacing: 0.5),
          ),
        ),
      );
    }

    // Downsample speeds if there are too many points to prevent performance degradation
    List<double> renderedSpeeds = speeds;
    if (speeds.length > 300) {
      final double step = speeds.length / 300;
      renderedSpeeds = List.generate(300, (index) {
        return speeds[(index * step).floor().clamp(0, speeds.length - 1)];
      });
    }

    final double maxSpeed = speeds.reduce(math.max);
    final double maxVal = math.max(60.0, ((maxSpeed + 20) / 20).ceil() * 20.0);

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF161916),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.04)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 12,
                    margin: const EdgeInsets.only(right: 6),
                    color: lineColor,
                  ),
                  const Text(
                    "SPEED TELEMETRY (km/h vs time)",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
              Text(
                "MAX: ${maxSpeed.toStringAsFixed(1)} KM/H",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: lineColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: CustomPaint(
              painter: _SpeedGraphPainter(
                speeds: renderedSpeeds,
                lineColor: lineColor,
                maxVal: maxVal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpeedGraphPainter extends CustomPainter {
  final List<double> speeds;
  final Color lineColor;
  final double maxVal;

  _SpeedGraphPainter({
    required this.speeds,
    required this.lineColor,
    required this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (speeds.isEmpty) return;

    final double width = size.width;
    final double height = size.height;

    // 1. Draw Grid Lines
    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1.0;

    // Draw horizontal grid lines (every 20 units up to maxVal)
    final int gridLinesCount = 3;
    for (int i = 1; i <= gridLinesCount; i++) {
      final double y = height - (i * (height / (gridLinesCount + 1)));
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);

      // Label
      final double valueLabel = (maxVal / (gridLinesCount + 1)) * i;
      final TextPainter labelPainter = TextPainter(
        text: TextSpan(
          text: "${valueLabel.toStringAsFixed(0)}",
          style: TextStyle(
            color: Colors.white.withOpacity(0.2),
            fontSize: 8,
            fontFamily: 'monospace',
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(2, y - 10));
    }

    // 2. Map coordinates
    final double stepX = width / math.max(1, speeds.length - 1);
    final Path path = Path();
    final Path areaPath = Path();

    // Start coordinates
    final double startY = height - (speeds[0] / maxVal) * height;
    path.moveTo(0, startY);
    areaPath.moveTo(0, height);
    areaPath.lineTo(0, startY);

    for (int i = 1; i < speeds.length; i++) {
      final double x = i * stepX;
      final double y = height - (speeds[i] / maxVal) * height;

      // Draw smooth curve using quadratic Bezier
      final double prevX = (i - 1) * stepX;
      final double prevY = height - (speeds[i - 1] / maxVal) * height;
      final double midX = (prevX + x) / 2;
      final double midY = (prevY + y) / 2;

      path.quadraticBezierTo(prevX, prevY, midX, midY);
      areaPath.quadraticBezierTo(prevX, prevY, midX, midY);

      if (i == speeds.length - 1) {
        path.lineTo(x, y);
        areaPath.lineTo(x, y);
      }
    }

    areaPath.lineTo(width, height);
    areaPath.close();

    // 3. Draw area gradient under the line
    final Paint areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          lineColor.withOpacity(0.18),
          lineColor.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTRB(0, 0, width, height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // 4. Draw Glow Shadow under the neon path
    final Paint glowPaint = Paint()
      ..color = lineColor.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(path, glowPaint);

    // 5. Draw the foreground Neon Path Line
    final Paint linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, linePaint);

    // 6. Draw speed labels at start and end
    final double finalX = width;
    final double finalY = height - (speeds.last / maxVal) * height;

    // Pulse dot at the current/final speed point
    final Paint dotPaintOuter = Paint()
      ..color = lineColor.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    final Paint dotPaintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(finalX, finalY), 6.0, dotPaintOuter);
    canvas.drawCircle(Offset(finalX, finalY), 2.5, dotPaintInner);
  }

  @override
  bool shouldRepaint(covariant _SpeedGraphPainter oldDelegate) {
    return oldDelegate.speeds != speeds || oldDelegate.lineColor != lineColor;
  }
}
