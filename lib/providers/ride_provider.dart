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

  // Phone Orientation vectors (calibrated)
  Vector3 uZ = Vector3(0.0, 0.0, 1.0); // vertical axis (downward gravity)
  Vector3 uX = Vector3(1.0, 0.0, 0.0); // lateral axis (right)
  Vector3 uY = Vector3(0.0, 1.0, 0.0); // longitudinal axis (forward)
  double lastAccelLeanAngle = 0.0;
  Stopwatch? _gyroStopwatch;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  // Lean Angle
  double currentLeanAngle = 0.0;
  double maxLeanRight = 0.0;
  double maxLeanLeft = 0.0;

  // Rider Profile (inspired by F1 / MotoGP paddock)
  String riderName = "Alex Rider";
  Color helmetColor = const Color(0xFFFF5722); // Racing Orange
  String riderCountry = "Indonesia";
  int riderPoints = 245;
  String currentClass = "Division 1";

  void updateRiderProfile({required String name, required Color color, required String country}) {
    riderName = name;
    helmetColor = color;
    riderCountry = country;
    notifyListeners();
  }

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
  List<double> routeSpeeds = [];
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
    try {
      _sensorSubscription?.cancel();
      _sensorSubscription = _sensorService.accelerometerEventsStream.listen(
        _onAccelerometerEvent,
        onError: (error) {
          debugPrint("Accelerometer stream error: $error");
        },
      );

      _gyroSubscription?.cancel();
      _gyroSubscription = _sensorService.gyroscopeEventsStream.listen(
        _onGyroscopeEvent,
        onError: (error) {
          debugPrint("Gyroscope stream error: $error");
        },
      );
    } catch (e) {
      debugPrint("Sensors not available in this environment: $e");
    }
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
    if (!isCalibrated) return;

    double mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    if (mag > 0.1) {
      double cosTheta = (event.x * uZ.x + event.y * uZ.y + event.z * uZ.z) / mag;
      cosTheta = cosTheta.clamp(-1.0, 1.0);
      double angle = acos(cosTheta) * (180.0 / pi);

      // Determine sign using lateral projection
      double lateralProj = event.x * uX.x + event.y * uX.y + event.z * uX.z;
      if (lateralProj < 0.0) {
        angle = -angle;
      }
      lastAccelLeanAngle = angle;
    }
  }

  void _onGyroscopeEvent(GyroscopeEvent event) {
    if (!isCalibrated) return;

    double dt = 0.0;
    if (_gyroStopwatch == null) {
      _gyroStopwatch = Stopwatch()..start();
      return;
    } else {
      dt = _gyroStopwatch!.elapsedMicroseconds / 1000000.0;
      _gyroStopwatch!.reset();
    }

    if (dt <= 0.0 || dt > 0.5) return;

    // Project gyroscope onto longitudinal axis to get roll rate
    double gyroRollRate = event.x * uY.x + event.y * uY.y + event.z * uY.z;

    // Project gyroscope onto vertical axis to get yaw rate
    double gyroYawRate = event.x * uZ.x + event.y * uZ.y + event.z * uZ.z;

    double speedMps = currentSpeedKmh / 3.6;
    double g = 9.80665;
    double physicsLeanAngle = 0.0;

    if (speedMps > 1.0) {
      physicsLeanAngle = atan(speedMps * gyroYawRate / g) * (180.0 / pi);
    }

    double refLeanAngle = 0.0;
    if (speedMps > 2.0) {
      refLeanAngle = physicsLeanAngle;
    } else {
      refLeanAngle = lastAccelLeanAngle;
    }

    double alpha = 0.98;
    if (speedMps > 3.0 && gyroYawRate.abs() > 0.05) {
      alpha = 0.995;
    }

    double rollRateDeg = gyroRollRate * (180.0 / pi);
    double newLeanAngle = alpha * (currentLeanAngle + rollRateDeg * dt) + (1.0 - alpha) * refLeanAngle;

    if (newLeanAngle > 60.0) newLeanAngle = 60.0;
    if (newLeanAngle < -60.0) newLeanAngle = -60.0;

    currentLeanAngle = newLeanAngle;

    if (isRiding && !isPaused) {
      if (currentLeanAngle > 0.0) {
        if (currentLeanAngle > maxLeanRight) {
          maxLeanRight = currentLeanAngle;
        }
      } else {
        double leftAbs = currentLeanAngle.abs();
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
          double x = _latestRawEvent!.x;
          double y = _latestRawEvent!.y;
          double z = _latestRawEvent!.z;
          double mag = sqrt(x * x + y * y + z * z);
          if (mag > 0.1) {
            uZ = Vector3(x / mag, y / mag, z / mag);
          } else {
            uZ = Vector3(0.0, 0.0, 1.0);
          }

          double absX = x.abs();
          double absY = y.abs();
          double absZ = z.abs();

          if (absY >= absX && absY >= absZ) {
            uX = Vector3(1.0, 0.0, 0.0);
          } else if (absX >= absY && absX >= absZ) {
            uX = Vector3(0.0, 1.0, 0.0);
          } else {
            uX = Vector3(1.0, 0.0, 0.0);
          }

          double dot = uX.x * uZ.x + uX.y * uZ.y + uX.z * uZ.z;
          double uxX = uX.x - dot * uZ.x;
          double uxY = uX.y - dot * uZ.y;
          double uxZ = uX.z - dot * uZ.z;
          double uxMag = sqrt(uxX * uxX + uxY * uxY + uxZ * uxZ);
          if (uxMag > 0.1) {
            uX = Vector3(uxX / uxMag, uxY / uxMag, uxZ / uxMag);
          } else {
            uX = Vector3(1.0, 0.0, 0.0);
          }

          double uyX = uZ.y * uX.z - uZ.z * uX.y;
          double uyY = uZ.z * uX.x - uZ.x * uX.z;
          double uyZ = uZ.x * uX.y - uZ.y * uX.x;
          uY = Vector3(uyX, uyY, uyZ);

          calibrationOffset = Vector3(x, y, z);
          isCalibrated = true;
        } else {
          uZ = Vector3(0.0, 0.0, 1.0);
          uX = Vector3(1.0, 0.0, 0.0);
          uY = Vector3(0.0, 1.0, 0.0);
          calibrationOffset = Vector3.zero();
          isCalibrated = true;
        }
        _gyroStopwatch = null;
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
    routeSpeeds.clear();
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
      routeSpeeds.add(0.0);
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
        routeSpeeds.add(currentSpeedKmh);
        lastPosition = pos;
      }
    } else {
      routePoints.add(newPoint);
      routeSpeeds.add(currentSpeedKmh);
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
      routeSpeeds: List.from(routeSpeeds),
      pitStops: List.from(pitStops),
    );

    // Reset variables that are run-dependent
    currentSpeedKmh = 0.0;
    notifyListeners();

    return rideModel;
  }

  Future<void> loadLifetimeStats() async {
    try {
      lifetimeDistanceKm = await _dbService.getLifetimeDistance();
    } catch (e) {
      // Fallback for mock/test environments without native sqflite binding
      lifetimeDistanceKm = 0.0;
    }
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
    _gyroSubscription?.cancel();
    _locationSubscription?.cancel();
    _uiTimer?.cancel();
    _dateTimer?.cancel();
    super.dispose();
  }
}
