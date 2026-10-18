import 'dart:async';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude, this.address});
  final double latitude;
  final double longitude;
  final String? address;
}

class LocationService {
  Future<PermissionStatus> checkPermissions() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return PermissionStatus.values.firstWhere(
      (e) => e.toString().split('.').last == perm.toString().split('.').last,
      orElse: () => PermissionStatus.denied,
    );
  }

  Future<GeoPoint> getCurrentLocation() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return const GeoPoint(latitude: 0.0, longitude: 0.0);
      }
      final perm = await checkPermissions();
      if (perm == PermissionStatus.denied || perm == PermissionStatus.deniedForever) {
        return const GeoPoint(latitude: 0.0, longitude: 0.0);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return GeoPoint(latitude: pos.latitude, longitude: pos.longitude);
    } catch (e) {
      return const GeoPoint(latitude: 0.0, longitude: 0.0);
    }
  }
}

enum PermissionStatus {
  denied,
  deniedForever,
  whileInUse,
  always,
}
