import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/pit_stop_model.dart';
import '../models/ride_model.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../services/sensor_service.dart';

class Vector3 {
  final double x;
  final double y;
  final double z;
  Vector3(this.x, this.y, this.z);
  static Vector3 zero() => Vector3(0.0, 0.0, 0.0);
}

class RideProvider extends ChangeNotifier {
  final SensorService _sensorService = SensorService();
  final LocationService _locationService = LocationService();
  final DatabaseService _dbService = DatabaseService.instance;

  // Core State
  bool isRiding = false;
  bool isPaused = false;
  bool isCalibrated = false;
  Vector3 calibrationOffset = Vector3.zero();

  // Lean Angle
  double currentLeanAngle = 0.0;
  double maxLeanRight = 0.0;
  double maxLeanLeft = 0.0;

  // Ride Metrics
  double currentSpeedKmh = 0.0;
  double avgSpeedKmh = 0.0;
  double maxSpeedKmh = 0.0;
  double totalDistanceKm = 0.0;
  int stopCount = 0;
  int pitPauseCount = 0;
  Duration rideDuration = Duration.zero;
  double lifetimeDistanceKm = 0.0;

  DateTime? rideStartTime;
  DateTime? currentPitStartTime;
  List<LatLng> routePoints = [];
  List<PitStopModel> pitStops = [];
  Position? lastPosition;
  final Stopwatch rideStopwatch = Stopwatch();

  // Calibration helper
  int calibrationCountdown = 5;
  bool isCalibrating = false;

  // Start/End location strings
  String startLocationName = "Resolving location...";
  String endLocationName = "Resolving location...";
  Position? currentPosition;

  // Stream Subscriptions & Timers
  StreamSubscription<AccelerometerEvent>? _sensorSubscription;
  StreamSubscription<Position>? _locationSubscription;
  Timer? _uiTimer;
  Timer? _dateTimer;

  // Current Date & Time for Home Top Bar
  DateTime currentDateTime = DateTime.now();

  // Stop detection and Auto-stop variables
  int _secondsBelowTwoKmh = 0;
  bool _isStoppedDetected = false;
  int _secondsAtZeroSpeed = 0;
  bool showAutoStopWarning = false;

  // Sensor reading tracking for calibration
  AccelerometerEvent? _latestRawEvent;

  RideProvider() {
    _startDateTimer();
    _startListeningSensorsAlways();
    _fetchInitialLocation();
    loadLifetimeStats();
  }

  void _startDateTimer() {
    _dateTimer?.cancel();
    _dateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      currentDateTime = DateTime.now();
      notifyListeners();
    });
  }

  void _startListeningSensorsAlways() {
    _sensorSubscription?.cancel();
    _sensorSubscription = _sensorService.accelerometerEventsStream.listen(
      _onAccelerometerEvent,
      onError: (error) {
        debugPrint("Accelerometer stream error: $error");
      },
    );
  }

  Future<void> _fetchInitialLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      if (pos != null) {
        currentPosition = pos;
        startLocationName = await _locationService.getPlaceName(pos.latitude, pos.longitude);
      } else {
        startLocationName = "Permission required / GPS disabled";
      }
    } catch (_) {
      startLocationName = "Location unavailable";
    }
    notifyListeners();
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    _latestRawEvent = event;

    // Apply offset
    double calibratedX = event.x - calibrationOffset.x;
    double calibratedY = event.y - calibrationOffset.y;
    double calibratedZ = event.z - calibrationOffset.z;

    // leanAngle in degrees: roll = atan2(calibratedX, calibratedZ) * (180 / pi)
    // Positive = right, negative = left
    double leanAngle = atan2(calibratedX, calibratedZ) * (180.0 / pi);

    // Keep it in range [-90, 90]
    if (leanAngle > 90.0) leanAngle = 90.0;
    if (leanAngle < -90.0) leanAngle = -90.0;

    currentLeanAngle = leanAngle;

    // Track max lean angles during active and unpaused ride
    if (isRiding && !isPaused) {
      if (leanAngle > 0.0) {
        if (leanAngle > maxLeanRight) {
          maxLeanRight = leanAngle;
        }
      } else {
        double leftAbs = leanAngle.abs();
        if (leftAbs > maxLeanLeft) {
          maxLeanLeft = leftAbs;
        }
      }
    }
    notifyListeners();
  }

  // Calibration Flow
  Future<void> startCalibration(
      Function(int) onTick, VoidCallback onComplete) async {
    isCalibrating = true;
    calibrationCountdown = 5;
    notifyListeners();

    Timer.periodic(const Duration(seconds: 1), (timer) {
      calibrationCountdown--;
      onTick(calibrationCountdown);
      notifyListeners();

      if (calibrationCountdown <= 0) {
        timer.cancel();
        isCalibrating = false;

        if (_latestRawEvent != null) {
          calibrationOffset = Vector3(
            _latestRawEvent!.x,
            _latestRawEvent!.y,
            _latestRawEvent!.z,
          );
          isCalibrated = true;
        } else {
          calibrationOffset = Vector3.zero();
          isCalibrated = true;
        }
        notifyListeners();
        onComplete();
      }
    });
  }

  // Start Ride Flow
  Future<void> startRide() async {
    final hasPermission = await _locationService.checkAndRequestPermissions();
    if (!hasPermission) {
      throw Exception("Location permission is required to start tracking.");
    }

    // WakeLock to keep screen on
    await WakelockPlus.enable();

    // Reset stats
    maxLeanRight = 0.0;
    maxLeanLeft = 0.0;
    currentSpeedKmh = 0.0;
    avgSpeedKmh = 0.0;
    maxSpeedKmh = 0.0;
    totalDistanceKm = 0.0;
    stopCount = 0;
    pitPauseCount = 0;
    rideDuration = Duration.zero;
    routePoints.clear();
    pitStops.clear();
    lastPosition = null;
    showAutoStopWarning = false;
    _secondsBelowTwoKmh = 0;
    _isStoppedDetected = false;
    _secondsAtZeroSpeed = 0;

    isRiding = true;
    isPaused = false;
    rideStartTime = DateTime.now();

    rideStopwatch.reset();
    rideStopwatch.start();

    // Fetch start coordinates & geocode
    final currentPos = await _locationService.getCurrentPosition();
    if (currentPos != null) {
      lastPosition = currentPos;
      currentPosition = currentPos;
      final startLatLng = LatLng(currentPos.latitude, currentPos.longitude);
      routePoints.add(startLatLng);
      startLocationName = await _locationService.getPlaceName(currentPos.latitude, currentPos.longitude);
    } else {
      startLocationName = "Unknown Start Location";
    }

    // Start location updates stream
    _locationSubscription?.cancel();
    _locationSubscription = _locationService.getPositionStream().listen(
      _onLocationUpdate,
      onError: (err) {
        debugPrint("Location stream error: $err");
      },
    );

    // Periodic UI and logic timer
    _uiTimer?.cancel();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isPaused) {
        rideDuration = rideStopwatch.elapsed;

        // Calculate Average Speed
        if (rideDuration.inSeconds > 0) {
          avgSpeedKmh = (totalDistanceKm / (rideDuration.inSeconds / 3600.0));
        }

        // Manage stops count: speed < 2 km/h for > 5 seconds
        if (currentSpeedKmh < 2.0) {
          _secondsBelowTwoKmh++;
          if (_secondsBelowTwoKmh > 5 && !_isStoppedDetected) {
            _isStoppedDetected = true;
            stopCount++;
          }
        } else {
          _secondsBelowTwoKmh = 0;
          _isStoppedDetected = false;
        }

        // Auto-stop detection: speed is 0 for > 3 minutes (180 seconds)
        if (currentSpeedKmh < 0.5) {
          _secondsAtZeroSpeed++;
          if (_secondsAtZeroSpeed >= 180 && !showAutoStopWarning) {
            showAutoStopWarning = true;
          }
        } else {
          _secondsAtZeroSpeed = 0;
        }
      }
      notifyListeners();
    });

    notifyListeners();
  }

  void dismissAutoStopWarning() {
    showAutoStopWarning = false;
    _secondsAtZeroSpeed = 0;
    notifyListeners();
  }

  void _onLocationUpdate(Position pos) {
    if (!isRiding || isPaused) return;

    currentPosition = pos;
    // Speed from Geolocator is in m/s, convert to km/h
    currentSpeedKmh = pos.speed * 3.6;

    if (currentSpeedKmh > maxSpeedKmh) {
      maxSpeedKmh = currentSpeedKmh;
    }

    LatLng newPoint = LatLng(pos.latitude, pos.longitude);

    if (lastPosition != null) {
      double distanceMeters = Geolocator.distanceBetween(
        lastPosition!.latitude,
        lastPosition!.longitude,
        pos.latitude,
        pos.longitude,
      );

      // Filter out small GPS jitters
      if (distanceMeters > 1.0) {
        totalDistanceKm += (distanceMeters / 1000.0);
        routePoints.add(newPoint);
        lastPosition = pos;
      }
    } else {
      routePoints.add(newPoint);
      lastPosition = pos;
    }

    notifyListeners();
  }

  // Pit Pause / Resume Flow
  Future<String> pauseRide() async {
    if (!isRiding || isPaused) return "Not active or already paused";

    isPaused = true;
    pitPauseCount++;
    rideStopwatch.stop();

    final pitTime = DateTime.now();
    currentPitStartTime = pitTime;

    double lat = 0.0;
    double lng = 0.0;
    if (currentPosition != null) {
      lat = currentPosition!.latitude;
      lng = currentPosition!.longitude;
    } else if (lastPosition != null) {
      lat = lastPosition!.latitude;
      lng = lastPosition!.longitude;
    }

    final newPitNumber = pitPauseCount;
    final temporaryStop = PitStopModel(
      pitNumber: newPitNumber,
      timestamp: pitTime,
      lat: lat,
      lng: lng,
      locationName: "Resolving location...",
      duration: Duration.zero,
    );

    pitStops.add(temporaryStop);
    notifyListeners();

    // Resolve address asynchronously
    _locationService.getPlaceName(lat, lng).then((resolvedName) {
      final index = pitStops.indexWhere((stop) => stop.pitNumber == newPitNumber);
      if (index != -index) {
        pitStops[index] = PitStopModel(
          id: pitStops[index].id,
          rideId: pitStops[index].rideId,
          pitNumber: pitStops[index].pitNumber,
          timestamp: pitStops[index].timestamp,
          lat: pitStops[index].lat,
          lng: pitStops[index].lng,
          locationName: resolvedName,
          duration: pitStops[index].duration,
        );
        notifyListeners();
      }
    });

    return "Pit stop recorded";
  }

  void resumeRide() {
    if (!isRiding || !isPaused) return;

    isPaused = false;
    rideStopwatch.start();

    if (currentPitStartTime != null && pitStops.isNotEmpty) {
      final duration = DateTime.now().difference(currentPitStartTime!);
      final lastIndex = pitStops.length - 1;
      final lastStop = pitStops[lastIndex];

      pitStops[lastIndex] = PitStopModel(
        id: lastStop.id,
        rideId: lastStop.rideId,
        pitNumber: lastStop.pitNumber,
        timestamp: lastStop.timestamp,
        lat: lastStop.lat,
        lng: lastStop.lng,
        locationName: lastStop.locationName,
        duration: duration,
      );
      currentPitStartTime = null;
    }

    notifyListeners();
  }

  // Stop Ride Flow
  Future<RideModel> stopRide() async {
    isRiding = false;
    isPaused = false;
    rideStopwatch.stop();

    // Disable screen keep awake
    await WakelockPlus.disable();

    _locationSubscription?.cancel();
    _locationSubscription = null;
    _uiTimer?.cancel();
    _uiTimer = null;

    final endTime = DateTime.now();

    // End position coordinates
    double endLat = 0.0;
    double endLng = 0.0;
    if (currentPosition != null) {
      endLat = currentPosition!.latitude;
      endLng = currentPosition!.longitude;
    } else if (lastPosition != null) {
      endLat = lastPosition!.latitude;
      endLng = lastPosition!.longitude;
    }

    // Save initial coordinates
    double startLat = 0.0;
    double startLng = 0.0;
    if (routePoints.isNotEmpty) {
      startLat = routePoints.first.latitude;
      startLng = routePoints.first.longitude;
    }

    // Resolve end location name synchronously (fast) or default to coordinates
    try {
      endLocationName = await _locationService.getPlaceName(endLat, endLng);
    } catch (_) {
      endLocationName = "Location (${endLat.toStringAsFixed(4)}, ${endLng.toStringAsFixed(4)})";
    }

    // Generate automatic name based on date (e.g. "Morning Ride · 25 Jun")
    final String timeOfDay;
    final hour = rideStartTime?.hour ?? 9;
    if (hour < 12) {
      timeOfDay = "Morning Ride";
    } else if (hour < 17) {
      timeOfDay = "Afternoon Ride";
    } else if (hour < 21) {
      timeOfDay = "Evening Ride";
    } else {
      timeOfDay = "Night Ride";
    }

    final day = rideStartTime?.day ?? DateTime.now().day;
    final months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
    final month = months[(rideStartTime?.month ?? DateTime.now().month) - 1];
    final defaultRideName = "$timeOfDay · $day $month";

    final rideModel = RideModel(
      name: defaultRideName,
      startTime: rideStartTime ?? DateTime.now().subtract(rideDuration),
      endTime: endTime,
      totalDistanceKm: double.parse(totalDistanceKm.toStringAsFixed(1)),
      avgSpeedKmh: double.parse(avgSpeedKmh.toStringAsFixed(1)),
      maxSpeedKmh: double.parse(maxSpeedKmh.toStringAsFixed(1)),
      maxLeanRight: double.parse(maxLeanRight.toStringAsFixed(1)),
      maxLeanLeft: double.parse(maxLeanLeft.toStringAsFixed(1)),
      stopCount: stopCount,
      pitPauseCount: pitPauseCount,
      rideDuration: rideDuration,
      startLocationName: startLocationName,
      endLocationName: endLocationName,
      startLat: startLat,
      startLng: startLng,
      endLat: endLat,
      endLng: endLng,
      routePoints: List.from(routePoints),
      pitStops: List.from(pitStops),
    );

    // Reset variables that are run-dependent
    currentSpeedKmh = 0.0;
    notifyListeners();

    return rideModel;
  }

  Future<void> loadLifetimeStats() async {
    lifetimeDistanceKm = await _dbService.getLifetimeDistance();
    notifyListeners();
  }

  Future<void> saveRide(RideModel ride) async {
    await _dbService.insertRide(ride);
    await loadLifetimeStats();
    notifyListeners();
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    _locationSubscription?.cancel();
    _uiTimer?.cancel();
    _dateTimer?.cancel();
    super.dispose();
  }
}
