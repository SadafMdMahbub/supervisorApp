import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';

/// A service class responsible for the business logic of adding a new boarding point.
/// This includes geocoding the location name, checking distance constraints, and posting to the API.
class AddBoardingPointService {
  
  /// The main method to handle the addition of a boarding point.
  /// It orchestrates the geocoding, distance check, and final API call.
  Future<String> addBoardingPoint({
    required String stopName,
    required String busId,
    required String authToken,
  }) async {
    try {
      // Step 1: Geocode the stop name to get coordinates.
      final geocodedPosition = await _geocodeStopName(stopName, authToken);
      if (geocodedPosition == null) {
        return 'Invalid boarding point. Location could not be found.';
      }

      // Step 2: Get the supervisor's current location.
      final supervisorPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Step 3: Check if the new point is within a 20km radius.
      final distance = Geolocator.distanceBetween(
        supervisorPosition.latitude,
        supervisorPosition.longitude,
        geocodedPosition['lat']!,
        geocodedPosition['lng']!,
      );

      if (distance > 20000) { // 20,000 meters = 20 km
        return 'Boarding point is too far away (over 20km).';
      }

      // Step 4: If within radius, add the boarding point to the server.
      final success = await _postNewBoardingPoint(
        stopName: stopName,
        lat: geocodedPosition['lat']!,
        lng: geocodedPosition['lng']!,
        busId: busId,
        authToken: authToken,
      );

      final resultMessage = success ? 'Boarding point added successfully!' : 'Failed to add boarding point on server.';
      return resultMessage;

    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  /// Calls the geocoding API to find latitude and longitude for a given address string.
  Future<Map<String, double>?> _geocodeStopName(String address, String authToken) async {
    try {
      final uri = Uri.parse(ApiConfig.geocodeAddress);
      final requestBody = {'address': address};

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'lat': data['lat'], 'lng': data['lng']};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Posts the new, validated boarding point to the server.
  /// It first determines the correct sequence order for the new stop.
  Future<bool> _postNewBoardingPoint({
    required String stopName,
    required double lat,
    required double lng,
    required String busId,
    required String authToken,
  }) async {
    try {
      final stopsUri = Uri.parse(ApiConfig.busStops(busId));
      final stopsResponse = await http.get(
        stopsUri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      int nextSequenceOrder = 1;
      if (stopsResponse.statusCode == 200) {
        final List<dynamic> stops = json.decode(stopsResponse.body);
        nextSequenceOrder = stops.length + 1;
      }

      final requestBody = {
        'name': stopName,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'sequence_order': nextSequenceOrder,
      };

      final uri = Uri.parse(ApiConfig.busStops(busId));
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
