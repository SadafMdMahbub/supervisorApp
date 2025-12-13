import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisor/homepage.dart';

/// A page where the supervisor selects their assigned bus for the current session.
/// It fetches the list of assigned buses from local storage and displays them.
class SelectBusPage extends StatefulWidget {
  const SelectBusPage({super.key});

  @override
  State<SelectBusPage> createState() => _SelectBusPageState();
}

/// The state class for the [SelectBusPage], managing its UI and data.
class _SelectBusPageState extends State<SelectBusPage> {
  String? _userName;
  List<dynamic> _buses = [];
  String? _selectedBusId;
  final _storage = const FlutterSecureStorage();

  /// Initializes the state and loads the necessary data from secure storage.
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Loads the supervisor's name and the list of assigned buses from secure storage.
  /// It updates the UI with the fetched data.
  Future<void> _loadData() async {
    final userName = await _storage.read(key: 'user_name');
    final assignedBusesJson = await _storage.read(key: 'assigned_buses');

    if (assignedBusesJson != null) {
      final buses = json.decode(assignedBusesJson);
      if (mounted) {
        setState(() {
          _userName = userName;
          _buses = buses;
          if (_buses.isNotEmpty) {
            _selectedBusId = _buses.first['id'].toString();
          }
        });
      }
    }
  }

  /// Saves the selected bus ID to secure storage and navigates to the [HomePage].
  /// It removes the navigation history so the user cannot go back to this page.
  void _navigateToHome() async {
    if (_selectedBusId != null) {
      await _storage.write(key: 'bus_id', value: _selectedBusId);
      final busIds = _buses.map((bus) => bus['id']).toList();
      await _storage.write(key: 'supervisor_bus_ids', value: json.encode(busIds));

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (Route<dynamic> route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a bus to continue.')),
      );
    }
  }

  /// Builds the user interface for the bus selection page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.directions_bus, color: Colors.black, size: 30),
            SizedBox(width: 8),
            Text('BUS AGENT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              const Text(
                'Welcome\nto the Supervisor App',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              if (_userName != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _userName!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.waving_hand, color: Colors.black, size: 30),
                  ],
                ),
              const SizedBox(height: 40),
              const Text(
                'SELECT YOUR ASSIGNED BUS',
                style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline, color: Colors.black),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: _buses.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                        itemCount: _buses.length,
                        itemBuilder: (context, index) {
                          final bus = _buses[index];
                          final busId = bus['id'].toString();
                          return BusCard(
                            bus: bus,
                            isSelected: _selectedBusId == busId,
                            onSelect: () {
                              setState(() {
                                _selectedBusId = busId;
                              });
                            },
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  iconSize: 50,
                  onPressed: _navigateToHome,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable widget that displays the details of a single bus in a card format.
/// It allows the user to select a bus.
class BusCard extends StatelessWidget {
  final Map<String, dynamic> bus;
  final bool isSelected;
  final VoidCallback onSelect;

  const BusCard({
    super.key,
    required this.bus,
    required this.isSelected,
    required this.onSelect,
  });

  /// Builds the user interface for the bus card.
  @override
  Widget build(BuildContext context) {
    final busNumber = bus['bus_number'] ?? 'N/A';
    final from = bus['route_from'] ?? 'N/A';
    final to = bus['route_to'] ?? 'N/A';
    final departure = bus['departure_time'] ?? 'N/A';

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: Colors.white,
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('BUS NUMBER: $busNumber', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('FROM: $from', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('TO: $to', style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('DEPARTURE: $departure', style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
