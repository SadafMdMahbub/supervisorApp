import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';

class AddBoardingPointService {
  // Main method to handle the addition of a boarding point.
  Future<String> addBoardingPoint({
    required String stopName,
    required String busId,
    required String authToken,
  }) async {
    try {
      print("--- Starting boarding point process for: $stopName ---");

      // Step 1: Geocode the stop name to get coordinates.
      final geocodedPosition = await _geocodeStopName(stopName, authToken);
      if (geocodedPosition == null) {
        return 'Invalid boarding point. Location could not be found.';
      }

      // Step 2: Get the supervisor's current location.
      final supervisorPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      print("Supervisor's current location: ${supervisorPosition.latitude}, ${supervisorPosition.longitude}");

      // Step 3: Check if the new point is within a 20km radius.
      final distance = Geolocator.distanceBetween(
        supervisorPosition.latitude,
        supervisorPosition.longitude,
        geocodedPosition['lat']!,
        geocodedPosition['lng']!,
      );
      print("Distance to new point: ${(distance / 1000).toStringAsFixed(2)} km");

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
      print("--- Boarding point process finished. Result: $resultMessage ---");
      return resultMessage;

    } catch (e) {
      print('Error in addBoardingPoint service: $e');
      return 'An error occurred: $e';
    }
  }

  // Calls the geocoding API to find coordinates for a location name.
  Future<Map<String, double>?> _geocodeStopName(String address, String authToken) async {
    try {
      final uri = Uri.parse(ApiConfig.geocodeAddress);
      final requestBody = {'address': address};

      print("--- Calling Geocode API: POST $uri ---");
      print("--- With Body: ${json.encode(requestBody)} ---");

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("--- Geocode API Response: ${response.statusCode} ---");
      print(response.body);
      print("------------------------------------");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'lat': data['lat'], 'lng': data['lng']};
      }
      return null;
    } catch (e) {
      print('Error geocoding stop name: $e');
      return null;
    }
  }

  // Adds the validated boarding point to the server.
  Future<bool> _postNewBoardingPoint({
    required String stopName,
    required double lat,
    required double lng,
    required String busId,
    required String authToken,
  }) async {
    try {
      final stopsUri = Uri.parse(ApiConfig.busStops(busId));
      print("--- Getting existing stops: GET $stopsUri ---");
      final stopsResponse = await http.get(
        stopsUri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      print("--- Get Stops Response: ${stopsResponse.statusCode} ---");
      print(stopsResponse.body);

      int nextSequenceOrder = 1;
      if (stopsResponse.statusCode == 200) {
        final List<dynamic> stops = json.decode(stopsResponse.body);
        nextSequenceOrder = stops.length + 1;
      }
      print("--- Next Sequence Order: $nextSequenceOrder ---");

      final requestBody = {
        'name': stopName,
        'lat': lat.toString(),
        'lng': lng.toString(),
        'sequence_order': nextSequenceOrder,
      };

      final uri = Uri.parse(ApiConfig.busStops(busId));
      print("--- Calling Add Stop API: POST $uri ---");
      print("--- With Body: ${json.encode(requestBody)} ---");

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print("--- Add Stop Response: ${response.statusCode} ---");
      print(response.body);
      print("------------------------------------");

      return response.statusCode == 201 || response.statusCode == 200;
    } catch (e) {
      print('Error posting new boarding point: $e');
      return false;
    }
  }
}
