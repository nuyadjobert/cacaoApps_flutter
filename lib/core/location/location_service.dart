import 'package:geolocator/geolocator.dart';
class LocationService {
  Future<Map<String, dynamic>?> getLocationSnapshot() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
  locationSettings: LocationSettings(
    accuracy: LocationAccuracy.high,
  ),
);

    return {
      'location_lat': pos.latitude,
      'location_lng': pos.longitude,
      'location_accuracy': pos.accuracy,
    };
  }
}
