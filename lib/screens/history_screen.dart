import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/ride_model.dart';
import '../providers/ride_provider.dart';
import '../services/database_service.dart';
import 'ride_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<RideModel>> _ridesFuture;

  @override
  void initState() {
    super.initState();
    _refreshRides();
  }

  void _refreshRides() {
    setState(() {
      _ridesFuture = DatabaseService.instance.getAllRides();
    });
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Color _getLeanBadgeColor(double maxLeanLeft, double maxLeanRight) {
    final double maxLean = maxLeanLeft > maxLeanRight ? maxLeanLeft : maxLeanRight;
    if (maxLean < 35.0) {
      return const Color(0xFF4CAF50); // Green
    } else if (maxLean <= 45.0) {
      return const Color(0xFFFF9800); // Amber
    } else {
      return const Color(0xFFF44336); // Red
    }
  }

  Future<void> _deleteRide(int rideId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Ride", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("Are you sure you want to delete this ride from your history?", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF44336)),
            child: const Text("DELETE", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseService.instance.deleteRide(rideId);
      _refreshRides();
      if (mounted) {
        // Update the provider's lifetime stats so the home screen reflects the deletion
        Provider.of<RideProvider>(context, listen: false).loadLifetimeStats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ride deleted"),
            backgroundColor: Color(0xFFF44336),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111111),
      appBar: AppBar(
        title: const Text("Ride History"),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: _refreshRides,
          )
        ],
      ),
      body: FutureBuilder<List<RideModel>>(
        future: _ridesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF64B5F6)),
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Error loading rides: ${snapshot.error}",
                style: const TextStyle(color: Colors.white70),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.motorcycle_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "No rides recorded yet",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white30,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Go track your first ride!",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            );
          }

          final rides = snapshot.data!;
          return ListView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: rides.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildHistorySummaryBanner(rides);
              }
              final ride = rides[index - 1];
              final maxLeanAngle = ride.maxLeanLeft > ride.maxLeanRight
                  ? ride.maxLeanLeft
                  : ride.maxLeanRight;
              final Color badgeColor = _getLeanBadgeColor(ride.maxLeanLeft, ride.maxLeanRight);

              return GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RideDetailScreen(ride: ride),
                    ),
                  );
                  _refreshRides(); // Refresh in case the ride name was edited
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.06),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row (Name + Lean Badge)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              ride.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: badgeColor.withOpacity(0.4), width: 1),
                            ),
                            child: Text(
                              "Lean: ${maxLeanAngle.round()}°",
                              style: TextStyle(
                                color: badgeColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Time Subtitle
                      Text(
                        DateFormat("EEEE, d MMMM yyyy · h:mm a").format(ride.startTime),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Quick Stats Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMiniStat(Icons.navigation_outlined, "${ride.totalDistanceKm} km"),
                          _buildMiniStat(Icons.timer, _formatDuration(ride.rideDuration)),
                          _buildMiniStat(Icons.speed, "${ride.avgSpeedKmh} km/h"),
                          _buildMiniStat(Icons.local_cafe_outlined, "${ride.pitPauseCount} pits"),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.white30, size: 18),
                            onPressed: () => _deleteRide(ride.id!),
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            splashRadius: 20,
                            tooltip: "Delete Ride",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHistorySummaryBanner(List<RideModel> rides) {
    double totalDist = 0.0;
    Duration totalDuration = Duration.zero;
    for (var r in rides) {
      totalDist += r.totalDistanceKm;
      totalDuration += r.rideDuration;
    }

    String formatHours(Duration d) {
      final hours = d.inHours;
      final minutes = d.inMinutes.remainder(60);
      if (hours > 0) {
        return "${hours}h ${minutes}m";
      } else {
        return "${minutes}m";
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF64B5F6).withOpacity(0.15), width: 0.8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryMetric("TOTAL DISTANCE", "${totalDist.toStringAsFixed(1)} km"),
          Container(width: 0.5, height: 30, color: Colors.white12),
          _buildSummaryMetric("TOTAL RIDES", "${rides.length}"),
          Container(width: 0.5, height: 30, color: Colors.white12),
          _buildSummaryMetric("TOTAL TIME", formatHours(totalDuration)),
        ],
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
