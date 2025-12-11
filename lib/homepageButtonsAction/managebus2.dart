import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:supervisor/appstate.dart';
import 'package:supervisor/homepage.dart';
import 'package:supervisor/homepageButtonsAction/addBoardingpoint.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ManageBus2Page extends StatefulWidget {
  final String busName;
  const ManageBus2Page({super.key, this.busName = "BUS LOCATION"});

  @override
  State<ManageBus2Page> createState() => _ManageBus2PageState();
}

class _ManageBus2PageState extends State<ManageBus2Page> {
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStreamSubscription;
  LatLng? _currentLocation;
  bool _isMapReady = false;
  final _storage = const FlutterSecureStorage();
  final AddBoardingPointService _addBoardingPointService = AddBoardingPointService();

  @override
  void initState() {
    super.initState();
    _startLiveLocationUpdates();
  }

  void _startLiveLocationUpdates() {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      if (!mounted) return;
      
      final newLocation = LatLng(position.latitude, position.longitude);

      // Only update state and move map if the location has actually changed.
      if (_currentLocation == null || 
          _currentLocation!.latitude != newLocation.latitude || 
          _currentLocation!.longitude != newLocation.longitude) {
        
        setState(() {
          _currentLocation = newLocation;
        });

        // **FIX:** Only move the map if it has been rendered.
        if (_isMapReady) {
          _mapController.move(newLocation, _mapController.camera.zoom);
        }
      }
    });
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  void _endJourneyAndGoHome() {
    context.read<AppState>().endJourney();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _showAddBoardingPointDialog() async {
    final stopNameController = TextEditingController();
    final stopName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: const Text(
          'ADD NEW BOARDING POINT',
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        content: TextField(
          controller: stopNameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Enter the stop name',
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black54),
            ),
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('cancel', style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(stopNameController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('ADD', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (stopName != null && stopName.isNotEmpty) {
      _addBoardingPoint(stopName);
    }
  }

  Future<void> _addBoardingPoint(String name) async {
    final authToken = await _storage.read(key: 'access_token');
    final busId = await _storage.read(key: 'bus_id');

    if (authToken == null || busId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not add point. Authentication details are missing.')),
      );
      return;
    }

    final resultMessage = await _addBoardingPointService.addBoardingPoint(
      stopName: name,
      busId: busId,
      authToken: authToken,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildAddBoardingPointButton(),
          Expanded(child: _buildMap()),
          _buildEndJourneyButton(),
        ],
      ),
    );
  }

   AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      shadowColor: Colors.black26,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Row(children: [
        const Icon(Icons.directions_bus, color: Colors.black),
        const SizedBox(width: 8),
        Text(widget.busName, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 18)),
      ]),
    );
  }

  Widget _buildAddBoardingPointButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ElevatedButton.icon(
        onPressed: _showAddBoardingPointDialog,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: const Text('ADD BOARDING POINT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildMap() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: _currentLocation == null
            ? const Center(child: CircularProgressIndicator())
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _currentLocation!,
                  initialZoom: 16.0,
                  onMapReady: () {
                    // **FIX:** Signal that the map is now ready to be controlled.
                    setState(() {
                      _isMapReady = true;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        width: 80.0,
                        height: 80.0,
                        point: _currentLocation!,
                        child: const Icon(Icons.my_location, color: Colors.blue, size: 30.0),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEndJourneyButton() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: _endJourneyAndGoHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: const Text('END JOURNEY', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}
