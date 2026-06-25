class PitStopModel {
  final int? id;
  final int? rideId;
  final int pitNumber;
  final DateTime timestamp;
  final double lat;
  final double lng;
  final String locationName;
  final Duration duration;

  PitStopModel({
    this.id,
    this.rideId,
    required this.pitNumber,
    required this.timestamp,
    required this.lat,
    required this.lng,
    required this.locationName,
    required this.duration,
  });

  Map<String, dynamic> toMap(int associatedRideId) {
    return {
      'id': id,
      'ride_id': associatedRideId,
      'pit_number': pitNumber,
      'timestamp': timestamp.toIso8601String(),
      'lat': lat,
      'lng': lng,
      'location_name': locationName,
      'duration_seconds': duration.inSeconds,
    };
  }

  factory PitStopModel.fromMap(Map<String, dynamic> map) {
    return PitStopModel(
      id: map['id'] as int?,
      rideId: map['ride_id'] as int?,
      pitNumber: map['pit_number'] as int,
      timestamp: DateTime.parse(map['timestamp'] as String),
      lat: map['lat'] as double,
      lng: map['lng'] as double,
      locationName: map['location_name'] as String,
      duration: Duration(seconds: map['duration_seconds'] as int),
    );
  }
}
