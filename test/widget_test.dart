import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:throttle/providers/ride_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock sensors_plus channel
    const MethodChannel sensorsChannel = MethodChannel('dev.fluttercommunity.plus/sensors/method');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sensorsChannel, (MethodCall methodCall) async {
      return null;
    });

    // Mock geolocator channel
    const MethodChannel geolocatorChannel = MethodChannel('flutter.baseflow.com/geolocator');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(geolocatorChannel, (MethodCall methodCall) async {
      return null;
    });
  });

  test('RideProvider initialization and customization test', () {
    final provider = RideProvider();

    // Verify initial paddock / racer profile state
    expect(provider.riderName, "Alex Rider");
    expect(provider.riderCountry, "Indonesia");
    expect(provider.helmetColor, const Color(0xFFFF5722)); // Default MotoGP orange

    // Test profile update
    provider.updateRiderProfile(
      name: "Valentin",
      color: const Color(0xFFE10600), // F1 Red
      country: "Italy",
    );

    expect(provider.riderName, "Valentin");
    expect(provider.helmetColor, const Color(0xFFE10600));
    expect(provider.riderCountry, "Italy");
  });
}
