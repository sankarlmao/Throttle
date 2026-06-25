import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/ride_model.dart';
import '../providers/ride_provider.dart';
import '../widgets/calibration_dialog.dart';
import '../widgets/lean_angle_hemisphere.dart';
import '../widgets/ride_map.dart';
import '../widgets/stats_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<RideProvider>(
      builder: (context, provider, child) {
        // Show auto-stop dialog if triggered
        if (provider.showAutoStopWarning) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showAutoStopDialog(context, provider);
          });
        }

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Top Bar
                _buildTopBar(provider),

                // 2. Uncalibrated Banner (Cold launch)
                if (!provider.isCalibrated && !provider.isRiding)
                  _buildCalibrationBanner(context),

                // 3. Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          // Lean Angle Hemisphere
                          Center(
                            child: LeanAngleHemisphere(
                              currentLeanAngle: provider.currentLeanAngle,
                              maxLeanRight: provider.maxLeanRight,
                              maxLeanLeft: provider.maxLeanLeft,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Dynamic Content based on Ride State
                          if (!provider.isRiding)
                            _buildIdleState(context, provider)
                          else
                            _buildActiveState(context, provider),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Top Bar Layout
  Widget _buildTopBar(RideProvider provider) {
    final String formattedDate = DateFormat("EEE, dd MMM yyyy").format(provider.currentDateTime);
    final String formattedTime = DateFormat("hh:mm:ss a").format(provider.currentDateTime);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1D1A), Color(0xFF121412)],
        ),
        border: Border(
          bottom: BorderSide(color: Colors.white10, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(
                Icons.motorcycle,
                color: Color(0xFFC5B494), // Matte Sand
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                "Throttle",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10, width: 0.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Colors.white54,
                  size: 12,
                ),
                const SizedBox(width: 6),
                Text(
                  "$formattedDate  ·  $formattedTime",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Calibration Alert Banner
  Widget _buildCalibrationBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => showCalibrationDialog(context),
      child: Container(
        color: const Color(0xFFD97724).withOpacity(0.15), // Tactical Orange
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFD97724), size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                "Calibrate lean sensor before riding →",
                style: TextStyle(
                  color: Color(0xFFD97724),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Idle Layout (Not Riding)
  Widget _buildIdleState(BuildContext context, RideProvider provider) {
    return Column(
      children: [
        // Calibrate Button
        OutlinedButton.icon(
          onPressed: () => showCalibrationDialog(context),
          icon: const Icon(Icons.tune, size: 18),
          label: Text(provider.isCalibrated ? "RE-CALIBRATE" : "CALIBRATE"),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFD97724), // Tactical Orange
            side: const BorderSide(color: Color(0xFFD97724), width: 1.2),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Lifetime Distance Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E221E), Color(0xFF151815)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFC5B494).withOpacity(0.25), width: 0.8),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.stars,
                color: Color(0xFFC5B494), // Matte Sand
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "TOTAL RIDE DISTANCE",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${provider.lifetimeDistanceKm.toStringAsFixed(1)} km",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Start Location Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E221E), Color(0xFF151815)],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10, width: 0.5),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Color(0xFF4CAF50),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "START LOCATION",
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withOpacity(0.4),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      provider.startLocationName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => provider.startRide(), // Call start ride implicitly on refresh logic
                icon: const Icon(Icons.refresh, color: Colors.white38, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
                tooltip: "Refresh location",
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // START RIDE Button
        Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF627254), Color(0xFF4A5542)], // Matte Olive Gradient
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF627254).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: () async {
              try {
                await provider.startRide();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.toString()),
                    backgroundColor: const Color(0xFFB85C4C), // Matte Red
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              "START RIDE",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Active Layout (Riding)
  Widget _buildActiveState(BuildContext context, RideProvider provider) {
    // Format duration to HH:MM:SS
    String formatDuration(Duration d) {
      String twoDigits(int n) => n.toString().padLeft(2, "0");
      String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
      String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
      return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }

    return Column(
      children: [
        // 2x3 Grid of stats cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            StatsCard(
              label: "Current Speed",
              value: "${provider.currentSpeedKmh.toStringAsFixed(1)} km/h",
              icon: Icons.speed,
              iconColor: const Color(0xFFC5B494),
            ),
            StatsCard(
              label: "Average Speed",
              value: "${provider.avgSpeedKmh.toStringAsFixed(1)} km/h",
              icon: Icons.directions_run,
            ),
            StatsCard(
              label: "Distance",
              value: "${provider.totalDistanceKm.toStringAsFixed(1)} km",
              icon: Icons.navigation_outlined,
            ),
            StatsCard(
              label: "Ride Time",
              value: formatDuration(provider.rideDuration),
              icon: Icons.timer,
            ),
            StatsCard(
              label: "Stops",
              value: "${provider.stopCount}",
              icon: Icons.pause_circle_outline,
            ),
            StatsCard(
              label: "Pit Pauses",
              value: "${provider.pitPauseCount}",
              icon: Icons.local_cafe_outlined,
              iconColor: const Color(0xFFD97724),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live Map
        RideMap(
          routePoints: provider.routePoints,
          pitStops: provider.pitStops,
          currentPosition: provider.currentPosition != null
              ? LatLng(provider.currentPosition!.latitude, provider.currentPosition!.longitude)
              : null,
          isInteractive: true,
          height: 200,
        ),
        const SizedBox(height: 24),

        // Controls
        Row(
          children: [
            // PIT PAUSE / RESUME button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFD97724), Color(0xFFAD5E1C)], // Matte Tactical Orange Gradient
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    if (provider.isPaused) {
                      provider.resumeRide();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Ride Resumed ✓"),
                          backgroundColor: Color(0xFF627254),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    } else {
                      final msg = await provider.pauseRide();
                      final lastPit = provider.pitStops.last;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Pit stop recorded at ${lastPit.locationName}"),
                          backgroundColor: const Color(0xFFD97724),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    provider.isPaused ? Icons.play_arrow : Icons.local_cafe,
                    color: Colors.white,
                  ),
                  label: Text(
                    provider.isPaused ? "RESUME" : "PIT PAUSE",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // STOP RIDE button
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFB85C4C), Color(0xFF8E4337)], // Matte Red Gradient
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton.icon(
                  onPressed: () => _handleStopRide(context, provider),
                  icon: const Icon(Icons.stop, color: Colors.white),
                  label: const Text(
                    "STOP RIDE",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  // Handle Stop Ride & Save Flow
  Future<void> _handleStopRide(BuildContext context, RideProvider provider) async {
    final ride = await provider.stopRide();
    _showSaveRideDialog(context, provider, ride);
  }

  // Save Ride Summary Dialog
  void _showSaveRideDialog(
      BuildContext context, RideProvider provider, RideModel ride) {
    final nameController = TextEditingController(text: ride.name);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF1A1D1A),
          title: const Text(
            "Ride Summary",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Editable Name field
                const Text(
                  "RIDE NAME",
                  style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    fillColor: Colors.white.withOpacity(0.04),
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Colors.white12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: const BorderSide(color: Color(0xFFC5B494)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Ride Stats Preview
                _buildSummaryRow("Distance", "${ride.totalDistanceKm} km"),
                _buildSummaryRow("Duration", _formatDuration(ride.rideDuration)),
                _buildSummaryRow("Avg Speed", "${ride.avgSpeedKmh} km/h"),
                _buildSummaryRow("Max Speed", "${ride.maxSpeedKmh} km/h"),
                _buildSummaryRow("Max Lean L/R", "${ride.maxLeanLeft.round()}°L / ${ride.maxLeanRight.round()}°R"),
                _buildSummaryRow("Stops", "${ride.stopCount}"),
                _buildSummaryRow("Pit Stops", "${ride.pitPauseCount}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss summary dialog
                // No save is performed, effectively discarding
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ride Discarded"),
                    backgroundColor: Color(0xFFB85C4C),
                  ),
                );
              },
              child: const Text(
                "DISCARD",
                style: TextStyle(color: Color(0xFFB85C4C), fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final customName = nameController.text.trim();
                final finalizedRide = ride.copyWith(
                  name: customName.isNotEmpty ? customName : ride.name,
                );
                await provider.saveRide(finalizedRide);
                Navigator.of(context).pop(); // Dismiss summary dialog

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Ride Saved Successfully ✓"),
                    backgroundColor: Color(0xFF4CAF50),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
              ),
              child: const Text("SAVE RIDE"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  // Auto-stop confirmation dialog
  void _showAutoStopDialog(BuildContext context, RideProvider provider) {
    provider.dismissAutoStopWarning(); // dismiss flag immediately to prevent repeat triggers

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1D1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Still riding?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: const Text(
            "We noticed that you have been stationary for more than 3 minutes. Would you like to keep tracking or end this ride?",
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss auto-stop dialog
                provider.dismissAutoStopWarning(); // Reset timers
              },
              child: const Text("CONTINUE", style: TextStyle(color: Color(0xFFC5B494))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss auto-stop dialog
                final ride = await provider.stopRide();
                _showSaveRideDialog(context, provider, ride);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB85C4C)),
              child: const Text("STOP & SAVE", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}
