import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supervisor/api_config.dart';
import 'package:supervisor/appstate.dart';
import 'package:supervisor/homepageButtonsAction/managebus2.dart';

/// A page that displays the details of a selected bus before the supervisor starts the journey.
/// It fetches bus information from the API and provides the option to start the trip.
class ManageBusPage extends StatefulWidget {
  final int busId;
  const ManageBusPage({super.key, required this.busId});

  @override
  State<ManageBusPage> createState() => _ManageBusPageState();
}

/// The state class for the [ManageBusPage], managing its UI and data.
class _ManageBusPageState extends State<ManageBusPage> {
  Map<String, dynamic>? _busDetails;
  bool _isLoading = true;
  String? _error;
  final _storage = const FlutterSecureStorage();

  /// Initializes the state and triggers the fetching of bus details.
  @override
  void initState() {
    super.initState();
    _fetchBusDetails();
  }

  /// Fetches the details of the selected bus from the API.
  /// It handles authentication, loading states, and various error conditions.
  Future<void> _fetchBusDetails() async {
    try {
      final String? authToken = await _storage.read(key: 'access_token');

      if (authToken == null || authToken.isEmpty) {
        if (mounted) {
          setState(() {
            _error = "Authentication Token not found. Please log in again.";
            _isLoading = false;
          });
        }
        return;
      }

      final url = Uri.parse('${ApiConfig.baseUrl}/buses/${widget.busId}');
      
      final response = await http.get(url, headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $authToken',
      });

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _busDetails = json.decode(response.body);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            if (response.statusCode == 404) {
                _error = "The bus has been deactivated by the owner.";
            } else if (response.statusCode == 401 || response.statusCode == 403) {
                _error = "Authentication failed. Please log in again.";
            } else {
                _error = "Failed to load bus details. Status code: ${response.statusCode}";
            }
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'An error occurred: $e';
          _isLoading = false;
        });
      }
    }
  }

  /// Formats a date-time string into a more readable format (e.g., 'Jan 1, 2023, 05:30 PM').
  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return DateFormat('MMM d, yyyy, hh:mm a').format(dateTime);
    } catch (e) {
      return dateTimeString;
    }
  }

  /// Builds the user interface for the manage bus page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(children: [
          Icon(Icons.directions_bus, color: Colors.black),
          SizedBox(width: 8),
          Text('START BUS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.blueAccent, width: 1.5),
                ),
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center,))
                    : _buildBusInfo(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_busDetails == null) ? null : () { 
                  context.read<AppState>().startJourney(context);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const ManageBus2Page()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8BC34A),
                  disabledBackgroundColor: Colors.grey, 
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('START BUS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the widget that displays the detailed information of the bus.
  Widget _buildBusInfo() {
    if (_busDetails == null) return const Center(child: Text('No bus details available.'));
    final String routeFrom = _busDetails!['route_from'] ?? 'N/A';
    final String routeTo = _busDetails!['route_to'] ?? 'N/A';
    final String busNumber = _busDetails!['bus_number'] ?? 'N/A';
    final String departureTime = _formatDateTime(_busDetails!['departure_time']);
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('BUS INFO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        _buildInfoRow('BUS NUMBER:', busNumber),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _buildInfoColumn('STARTING POINT:', routeFrom),
          _buildInfoColumn('END POINT:', routeTo, crossAxisAlignment: CrossAxisAlignment.end),
        ]),
        const SizedBox(height: 24),
        _buildInfoRow('Journey starts at:', departureTime),
      ]),
    );
  }

  /// A helper widget to create a consistent row for displaying a label and a value.
  Widget _buildInfoRow(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
    ]);
  }

  /// A helper widget to create a column for displaying a label and a value, with alignment options.
  Widget _buildInfoColumn(String label, String value, {CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start}) {
    return Column(crossAxisAlignment: crossAxisAlignment, children: [
      Text(label, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500)),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
    ]);
  }
}
