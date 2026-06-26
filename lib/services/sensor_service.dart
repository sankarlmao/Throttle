import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _accelSubscription;
  StreamSubscription<GyroscopeEvent>? _gyroSubscription;

  Stream<AccelerometerEvent> get accelerometerEventsStream => accelerometerEvents;
  Stream<GyroscopeEvent> get gyroscopeEventsStream => gyroscopeEvents;

  void startListening({
    required void Function(AccelerometerEvent) onAccelerometerData,
    required void Function(GyroscopeEvent) onGyroscopeData,
    void Function(dynamic)? onError,
  }) {
    _accelSubscription?.cancel();
    _accelSubscription = accelerometerEvents.listen(onAccelerometerData, onError: onError, cancelOnError: true);

    _gyroSubscription?.cancel();
    _gyroSubscription = gyroscopeEvents.listen(onGyroscopeData, onError: onError, cancelOnError: true);
  }

  Future<void> stopListening() async {
    await _accelSubscription?.cancel();
    _accelSubscription = null;
    await _gyroSubscription?.cancel();
    _gyroSubscription = null;
  }
}
