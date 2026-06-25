import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermissions();
      if (!hasPermission) return null;
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Stream<Position> getPositionStream() {
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5, // update every 5 meters
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  Future<String> getPlaceName(double lat, double lng) async {
    try {
      final List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String locality = place.locality ?? "";
        final String subLocality = place.subLocality ?? "";
        final String subAdminArea = place.subAdministrativeArea ?? "";
        final String adminArea = place.administrativeArea ?? "";

        String city = locality.isNotEmpty ? locality : subLocality;
        String region = subAdminArea.isNotEmpty ? subAdminArea : adminArea;

        if (city.isNotEmpty && region.isNotEmpty) {
          return "$city, $region";
        } else if (city.isNotEmpty) {
          return city;
        } else if (region.isNotEmpty) {
          return region;
        } else {
          return place.name ?? "Unknown Place";
        }
      }
    } catch (e) {
      // Return a basic coordinates placeholder if geocoding fails or is rate-limited
      return "Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})";
    }
    return "Unknown Location";
  }
}
