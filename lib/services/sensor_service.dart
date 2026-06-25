import 'dart:async';
import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  StreamSubscription<AccelerometerEvent>? _subscription;

  Stream<AccelerometerEvent> get accelerometerEventsStream => accelerometerEvents;

  void startListening(void Function(AccelerometerEvent) onData, {void Function(dynamic)? onError}) {
    _subscription?.cancel();
    _subscription = accelerometerEvents.listen(onData, onError: onError, cancelOnError: true);
  }

  Future<void> stopListening() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
