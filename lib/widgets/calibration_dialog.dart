import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/ride_provider.dart';

class CalibrationDialog extends StatefulWidget {
  const CalibrationDialog({Key? key}) : super(key: key);

  @override
  State<CalibrationDialog> createState() => _CalibrationDialogState();
}

class _CalibrationDialogState extends State<CalibrationDialog> {
  int _secondsRemaining = 5;

  @override
  void initState() {
    super.initState();
    // Run calibration after build completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RideProvider>(context, listen: false);
      provider.startCalibration(
        (countdown) {
          if (mounted) {
            setState(() {
              _secondsRemaining = countdown;
            });
          }
        },
        () {
          if (mounted) {
            Navigator.of(context).pop(true); // Return true when done
          }
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      backgroundColor: const Color(0xFF1A1D1A),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.screen_rotation,
              color: Color(0xFFD97724), // Tactical Orange
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              "Sensor Calibration",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: _secondsRemaining / 5.0,
                    strokeWidth: 6,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97724)),
                    backgroundColor: Colors.white12,
                  ),
                ),
                Text(
                  "$_secondsRemaining",
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              "Keep phone in your pocket in its normal riding position. Do not move.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.white70,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Calibrating...",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showCalibrationDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return const CalibrationDialog();
    },
  ).then((success) {
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Color(0xFF627254)), // Tactical Green
              SizedBox(width: 12),
              Text(
                "Calibrated ✓ — 0° set.",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1A1D1A),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  });
}
