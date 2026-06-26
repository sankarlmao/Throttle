import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class F1StartLightsOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const F1StartLightsOverlay({Key? key, required this.onComplete}) : super(key: key);

  static void show(BuildContext context, VoidCallback onComplete) {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return F1StartLightsOverlay(onComplete: onComplete);
      },
    );
  }

  @override
  State<F1StartLightsOverlay> createState() => _F1StartLightsOverlayState();
}

class _F1StartLightsOverlayState extends State<F1StartLightsOverlay> with SingleTickerProviderStateMixin {
  int _activeLights = 0;
  bool _lightsOut = false;
  bool _awayWeGo = false;
  Timer? _sequenceTimer;
  late AnimationController _shakeController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _startSequence();
  }

  @override
  void dispose() {
    _sequenceTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startSequence() {
    // Sequentially light up red lights every 800ms
    _sequenceTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (_activeLights < 5) {
        setState(() {
          _activeLights++;
        });
        HapticFeedback.mediumImpact();
      } else {
        timer.cancel();
        // Random delay (1 to 2.5 seconds) before lights out (like real F1)
        final randomDelay = 1000 + _random.nextInt(1500);
        _sequenceTimer = Timer(Duration(milliseconds: randomDelay), () {
          _triggerLightsOut();
        });
      }
    });
  }

  void _triggerLightsOut() {
    setState(() {
      _activeLights = 0;
      _lightsOut = true;
      _awayWeGo = true;
    });
    
    // Roar engine / screen shake vibration
    HapticFeedback.lightImpact();
    _shakeController.forward(from: 0.0);
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
    Future.delayed(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());

    // Dismiss overlay and start ride after 1.8 seconds
    Timer(const Duration(milliseconds: 1800), () {
      Navigator.of(context).pop();
      widget.onComplete();
    });
  }

  Widget _buildLightUnit(bool isLit) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      width: 50,
      height: 90,
      decoration: BoxDecoration(
        color: const Color(0xFF151515),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 4,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(2, (index) {
          return Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isLit ? const Color(0xFFFF1E1E) : const Color(0xFF2E0808),
              border: Border.all(
                color: isLit ? const Color(0xFFFF8A8A) : Colors.black,
                width: isLit ? 1.5 : 1.0,
              ),
              boxShadow: isLit
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFF1E1E).withOpacity(0.8),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 4,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
          );
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Shake animation
    final double shakeOffset = 6.0;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _shakeController,
        builder: (context, child) {
          double offset = 0.0;
          if (_shakeController.isAnimating) {
            offset = sin(_shakeController.value * pi * 8) * shakeOffset * (1.0 - _shakeController.value);
          }
          return Transform.translate(
            offset: Offset(offset, offset),
            child: child,
          );
        },
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // F1 style light board
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white24, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gantry Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE10600), // F1 Red
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "START SEQUENCE",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ),
                    // Row of 5 lights
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return _buildLightUnit(index < _activeLights);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),
              // Telemetry Subtext
              AnimatedOpacity(
                opacity: _awayWeGo ? 1.0 : 0.4,
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _awayWeGo ? "GO GO GO!" : "HOLD POSITION",
                  style: TextStyle(
                    color: _awayWeGo ? const Color(0xFF00E676) : const Color(0xFFFFB300),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Big text overlay when lights go out
              AnimatedScale(
                scale: _awayWeGo ? 1.0 : 0.6,
                duration: const Duration(milliseconds: 300),
                curve: Curves.elasticOut,
                child: AnimatedOpacity(
                  opacity: _awayWeGo ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE10600), // F1 Red
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE10600).withOpacity(0.5),
                          blurRadius: 15,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Text(
                      "LIGHTS OUT & AWAY WE GO!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
