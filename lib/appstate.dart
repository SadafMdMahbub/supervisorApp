import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisor/location_tracker.dart';

/// Manages the global state of the application using the [ChangeNotifier] pattern.
/// It keeps track of the journey status and controls location tracking.
class AppState extends ChangeNotifier {
  bool _isJourneyStarted = false;
  final LocationTracker _locationTracker = LocationTracker();
  final _storage = const FlutterSecureStorage();

  /// A getter to check if the journey is currently active.
  bool get isJourneyStarted => _isJourneyStarted;

  /// Starts the journey and initiates location tracking for the selected bus.
  /// It reads the `bus_id` from secure storage and begins tracking.
  void startJourney(BuildContext context) async {
    if (!_isJourneyStarted) {
      print("Starting journey and location tracking...");
      _isJourneyStarted = true;

      final busId = await _storage.read(key: 'bus_id');
      if (busId != null) {
        _locationTracker.startTracking(context, busId);
      } else {
        print("Bus ID not found. Cannot start tracking.");
      }
      
      notifyListeners();
    }
  }

  /// Ends the journey and stops the location tracking service.
  /// It updates the state and notifies all listeners.
  void endJourney() {
    if (_isJourneyStarted) {
      print("Ending journey and stopping location tracking...");
      _isJourneyStarted = false;
      _locationTracker.stopTracking();
      notifyListeners();
    }
  }
}
