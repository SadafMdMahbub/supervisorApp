import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocationTracker {
  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _locationUploadTimer;
  Position? _lastKnownPosition;
  final _storage = const FlutterSecureStorage();

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print("Location services are disabled.");
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print("Location permissions are denied.");
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print("Location permissions are permanently denied.");
      return false;
    }

    return true;
  }

  void startTracking(BuildContext context, String busId) {
    print("Starting location tracking...");
    _handleLocationPermission().then((hasPermission) async {
      if (!hasPermission) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission is required to share bus location.')),
        );
        return;
      }

      final authToken = await _storage.read(key: 'access_token');
      if (authToken == null) {
        print("Auth token not found. Cannot start tracking.");
        return;
      }

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      );
      _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen(
        (Position? position) {
          if (position != null) {
            _lastKnownPosition = position;
          }
        },
        onError: (error) {
          print('Error on position stream: $error');
        }
      );

      _locationUploadTimer?.cancel();
      _locationUploadTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
        if (_lastKnownPosition == null) {
          print('Waiting for initial location before uploading...');
          return;
        }
        _uploadLocation(_lastKnownPosition!, busId, authToken);
      });
    });
  }

  Future<void> _uploadLocation(Position position, String busId, String authToken) async {
    try {
      // **FIX:** Send lat/lng as query parameters, not in the body.
      final uri = Uri.parse(ApiConfig.updateBusLocation(busId)).replace(queryParameters: {
        'lat': position.latitude.toString(),
        'lng': position.longitude.toString(),
      });

      print('Uploading location via: POST $uri');
      
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
        },
      );

      if (response.statusCode != 200) {
        print('Failed to upload location. Server responded with ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('Error sending location to server: $e');
    }
  }

  void stopTracking() {
    print("Stopping location tracking...");
    _positionStreamSubscription?.cancel();
    _locationUploadTimer?.cancel();
    _lastKnownPosition = null;
  }
}
