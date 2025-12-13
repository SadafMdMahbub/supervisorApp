import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// A class that manages background location tracking and uploading.
/// It handles permissions, listens for location changes, and periodically sends updates to the server.
class LocationTracker {
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUploadTimer;
  Position? _lastKnownPosition;
  final _storage = const FlutterSecureStorage();

  /// Checks for and requests location permissions from the user.
  /// Returns `true` if permissions are granted, `false` otherwise.
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled.
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User denied the permission request.
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // User has permanently denied location permissions.
      return false;
    }

    return true;
  }

  /// Starts the location tracking service.
  /// It requests permissions and then begins listening for and uploading location updates.
  void startTracking(BuildContext context, String busId) {
    _handleLocationPermission().then((hasPermission) async {
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to share bus location.')),
        );
        return;
      }

      final authToken = await _storage.read(key: 'access_token');
      if (authToken == null) {
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Updates will trigger if the device moves 10 meters.
      );
      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position? position) {
          if (position != null) {
            _lastKnownPosition = position;
          }
        },
        onError: (error) {
          // Handle errors from the position stream.
        }
      );

      _locationUploadTimer?.cancel();
      // Upload the location to the server every 10 seconds.
      _locationUploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (_lastKnownPosition == null) {
          return;
        }
        _uploadLocation(_lastKnownPosition!, busId, authToken);
      });
    });
  }

  /// Uploads the device's current location to the server.
  Future<void> _uploadLocation(Position position, String busId, String authToken) async {
    try {
      final uri = Uri.parse(ApiConfig.updateBusLocation(busId)).replace(queryParameters: {
        'lat': position.latitude.toString(),
        'lng': position.longitude.toString(),
      });

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode != 200) {
        // Handle failed upload.
      }
    } catch (e) {
      // Handle exceptions.
    }
  }

  /// Stops the location tracking service and cancels any active subscriptions or timers.
  void stopTracking() {
    _positionStreamSubscription?.cancel();
    _locationUploadTimer?.cancel();
    _lastKnownPosition = null;
  }
}
