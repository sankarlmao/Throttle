import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/ride_model.dart';
import '../services/database_service.dart';
import '../widgets/lean_angle_hemisphere.dart';
import '../widgets/ride_map.dart';
import '../widgets/stats_card.dart';

class RideDetailScreen extends StatefulWidget {
  final RideModel ride;

  const RideDetailScreen({
    Key? key,
    required this.ride,
  }) : super(key: key);

  @override
  State<RideDetailScreen> createState() => _RideDetailScreenState();
}

class _RideDetailScreenState extends State<RideDetailScreen> {
  late RideModel _ride;

  @override
  void initState() {
    super.initState();
    _ride = widget.ride;
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Future<void> _renameRide() async {
    final nameController = TextEditingController(text: _ride.name);

    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Rename Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            isDense: true,
            hintText: "Enter ride name",
            hintStyle: const TextStyle(color: Colors.white30),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF64B5F6))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(nameController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF64B5F6)),
            child: const Text("SAVE", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty && newName != _ride.name) {
      await DatabaseService.instance.updateRideName(_ride.id!, newName);
      setState(() {
        _ride = _ride.copyWith(name: newName);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ride renamed successfully"),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final String dateStr = DateFormat("EEE, dd MMM yyyy").format(_ride.startTime);
    final String timeStr = "${DateFormat("hh:mm a").format(_ride.startTime)} - ${DateFormat("hh:mm a").format(_ride.endTime)}";

    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text("Ride Details"),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            tooltip: "Rename Ride",
            onPressed: _renameRide,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Name, Date & Time Range)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _ride.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "$dateStr  ·  $timeStr",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Static Route Map
              const Text(
                "ROUTE MAP",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_ride.routePoints.isNotEmpty)
                RideMap(
                  routePoints: _ride.routePoints,
                  pitStops: _ride.pitStops,
                  isInteractive: false,
                  height: 220,
                )
              else
                Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10, width: 0.5),
                  ),
                  child: const Center(
                    child: Text(
                      "No map route data",
                      style: TextStyle(color: Colors.white30),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              // 3. Stats Grid
              const Text(
                "RIDE STATISTICS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: [
                  StatsCard(
                    label: "Distance",
                    value: "${_ride.totalDistanceKm} km",
                    icon: Icons.navigation_outlined,
                  ),
                  StatsCard(
                    label: "Moving Time",
                    value: _formatDuration(_ride.rideDuration),
                    icon: Icons.timer,
                  ),
                  StatsCard(
                    label: "Avg Speed",
                    value: "${_ride.avgSpeedKmh} km/h",
                    icon: Icons.speed,
                  ),
                  StatsCard(
                    label: "Max Speed",
                    value: "${_ride.maxSpeedKmh} km/h",
                    icon: Icons.bolt,
                  ),
                  StatsCard(
                    label: "Stops",
                    value: "${_ride.stopCount}",
                    icon: Icons.pause_circle_outline,
                  ),
                  StatsCard(
                    label: "Pit Pauses",
                    value: "${_ride.pitPauseCount}",
                    icon: Icons.local_cafe_outlined,
                    iconColor: const Color(0xFFFF9800),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 4. Lean Angle Section (Static Hemisphere with max dots)
              const Text(
                "MAX LEAN ANGLES",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10, width: 0.5),
                ),
                child: Column(
                  children: [
                    LeanAngleHemisphere(
                      currentLeanAngle: 0.0, // center needle for static view
                      maxLeanRight: _ride.maxLeanRight,
                      maxLeanLeft: _ride.maxLeanLeft,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text("MAX LEFT LEAN", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${_ride.maxLeanLeft.round()}° L", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        Column(
                          children: [
                            const Text("MAX RIGHT LEAN", style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text("${_ride.maxLeanRight.round()}° R", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 5. Start / End Location Addresses
              const Text(
                "LOCATIONS",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              _buildLocationDetails(
                title: "START LOCATION",
                address: _ride.startLocationName,
                coords: "${_ride.startLat.toStringAsFixed(6)}, ${_ride.startLng.toStringAsFixed(6)}",
                iconColor: const Color(0xFF4CAF50),
              ),
              const SizedBox(height: 12),
              _buildLocationDetails(
                title: "END LOCATION",
                address: _ride.endLocationName,
                coords: "${_ride.endLat.toStringAsFixed(6)}, ${_ride.endLng.toStringAsFixed(6)}",
                iconColor: const Color(0xFFF44336),
              ),
              const SizedBox(height: 24),

              // 6. Pit Stop Log
              const Text(
                "PIT STOP LOG",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 8),
              if (_ride.pitStops.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white10, width: 0.5),
                  ),
                  child: const Center(
                    child: Text(
                      "No pit pauses during this ride",
                      style: TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _ride.pitStops.length,
                  itemBuilder: (context, index) {
                    final pit = _ride.pitStops[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10, width: 0.5),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.local_cafe,
                              color: Color(0xFFFF9800),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Pit Stop ${pit.pitNumber}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    Text(
                                      DateFormat("hh:mm a").format(pit.timestamp),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  pit.locationName,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.7),
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Duration: ${_formatDuration(pit.duration)}",
                                  style: const TextStyle(
                                    color: Color(0xFFFF9800),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDetails({
    required String title,
    required String address,
    required String coords,
    required Color iconColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.location_on, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  coords,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
