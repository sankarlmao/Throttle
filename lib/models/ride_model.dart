import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'pit_stop_model.dart';

class RideModel {
  final int? id;
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final double totalDistanceKm;
  final double avgSpeedKmh;
  final double maxSpeedKmh;
  final double maxLeanRight;
  final double maxLeanLeft;
  final int stopCount;
  final int pitPauseCount;
  final Duration rideDuration;
  final String startLocationName;
  final String endLocationName;
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final List<LatLng> routePoints;
  final List<double> routeSpeeds;
  final List<PitStopModel> pitStops;

  RideModel({
    this.id,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.totalDistanceKm,
    required this.avgSpeedKmh,
    required this.maxSpeedKmh,
    required this.maxLeanRight,
    required this.maxLeanLeft,
    required this.stopCount,
    required this.pitPauseCount,
    required this.rideDuration,
    required this.startLocationName,
    required this.endLocationName,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.routePoints,
    required this.routeSpeeds,
    required this.pitStops,
  });

  Map<String, dynamic> toMap() {
    final routeJson = jsonEncode(
      List.generate(routePoints.length, (i) {
        final p = routePoints[i];
        final speed = i < routeSpeeds.length ? routeSpeeds[i] : 0.0;
        return {'lat': p.latitude, 'lng': p.longitude, 'speed': speed};
      }),
    );
    return {
      'id': id,
      'name': name,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'total_distance_km': totalDistanceKm,
      'avg_speed_kmh': avgSpeedKmh,
      'max_speed_kmh': maxSpeedKmh,
      'max_lean_right': maxLeanRight,
      'max_lean_left': maxLeanLeft,
      'stop_count': stopCount,
      'pit_pause_count': pitPauseCount,
      'ride_duration_seconds': rideDuration.inSeconds,
      'start_location_name': startLocationName,
      'end_location_name': endLocationName,
      'start_lat': startLat,
      'start_lng': startLng,
      'end_lat': endLat,
      'end_lng': endLng,
      'route_points_json': routeJson,
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map, List<PitStopModel> stops) {
    final routePointsList = <LatLng>[];
    final routeSpeedsList = <double>[];
    if (map['route_points_json'] != null) {
      final decoded = jsonDecode(map['route_points_json'] as String) as List;
      for (var item in decoded) {
        final m = item as Map<String, dynamic>;
        routePointsList.add(LatLng(m['lat'] as double, m['lng'] as double));
        routeSpeedsList.add(((m['speed'] ?? 0.0) as num).toDouble());
      }
    }

    return RideModel(
      id: map['id'] as int?,
      name: map['name'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      totalDistanceKm: map['total_distance_km'] as double,
      avgSpeedKmh: map['avg_speed_kmh'] as double,
      maxSpeedKmh: map['max_speed_kmh'] as double,
      maxLeanRight: map['max_lean_right'] as double,
      maxLeanLeft: map['max_lean_left'] as double,
      stopCount: map['stop_count'] as int,
      pitPauseCount: map['pit_pause_count'] as int,
      rideDuration: Duration(seconds: map['ride_duration_seconds'] as int),
      startLocationName: map['start_location_name'] as String,
      endLocationName: map['end_location_name'] as String,
      startLat: map['start_lat'] as double,
      startLng: map['start_lng'] as double,
      endLat: map['end_lat'] as double,
      endLng: map['end_lng'] as double,
      routePoints: routePointsList,
      routeSpeeds: routeSpeedsList,
      pitStops: stops,
    );
  }

  RideModel copyWith({
    int? id,
    String? name,
    DateTime? startTime,
    DateTime? endTime,
    double? totalDistanceKm,
    double? avgSpeedKmh,
    double? maxSpeedKmh,
    double? maxLeanRight,
    double? maxLeanLeft,
    int? stopCount,
    int? pitPauseCount,
    Duration? rideDuration,
    String? startLocationName,
    String? endLocationName,
    double? startLat,
    double? startLng,
    double? endLat,
    double? endLng,
    List<LatLng>? routePoints,
    List<double>? routeSpeeds,
    List<PitStopModel>? pitStops,
  }) {
    return RideModel(
      id: id ?? this.id,
      name: name ?? this.name,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDistanceKm: totalDistanceKm ?? this.totalDistanceKm,
      avgSpeedKmh: avgSpeedKmh ?? this.avgSpeedKmh,
      maxSpeedKmh: maxSpeedKmh ?? this.maxSpeedKmh,
      maxLeanRight: maxLeanRight ?? this.maxLeanRight,
      maxLeanLeft: maxLeanLeft ?? this.maxLeanLeft,
      stopCount: stopCount ?? this.stopCount,
      pitPauseCount: pitPauseCount ?? this.pitPauseCount,
      rideDuration: rideDuration ?? this.rideDuration,
      startLocationName: startLocationName ?? this.startLocationName,
      endLocationName: endLocationName ?? this.endLocationName,
      startLat: startLat ?? this.startLat,
      startLng: startLng ?? this.startLng,
      endLat: endLat ?? this.endLat,
      endLng: endLng ?? this.endLng,
      routePoints: routePoints ?? this.routePoints,
      routeSpeeds: routeSpeeds ?? this.routeSpeeds,
      pitStops: pitStops ?? this.pitStops,
    );
  }
}
