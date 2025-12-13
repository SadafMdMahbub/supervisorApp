import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';

/// A page that provides an overview of the bus's seat and revenue status.
/// It displays details such as total seats, available seats, and total revenue.
class SeatManagementPage extends StatefulWidget {
  const SeatManagementPage({super.key});

  @override
  State<SeatManagementPage> createState() => _SeatManagementPageState();
}

/// The state class for the [SeatManagementPage], managing its UI and data.
class _SeatManagementPageState extends State<SeatManagementPage> {
  bool _isLoading = true;
  String _errorMessage = '';
  Map<String, dynamic>? _busDetails;
  Map<String, dynamic>? _ticketReport;

  /// Initializes the state and triggers the initial data fetch.
  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  /// Fetches both bus details and the ticket report concurrently from the API.
  /// It manages loading states and handles any errors that occur.
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final storage = const FlutterSecureStorage();
      final authToken = await storage.read(key: 'access_token');
      final busId = await storage.read(key: 'bus_id');

      if (authToken == null || busId == null) {
        throw Exception('Authentication details not found. Please log in again.');
      }

      final results = await Future.wait([
        _fetchBusDetails(busId, authToken),
        _fetchTicketReport(busId, authToken),
      ]);

      if (mounted) {
        setState(() {
          _busDetails = results[0];
          _ticketReport = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  /// Fetches the details for a specific bus from the API.
  Future<Map<String, dynamic>> _fetchBusDetails(String busId, String authToken) async {
    final uri = Uri.parse(ApiConfig.busById(busId));
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $authToken'});
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load bus details: ${response.statusCode}');
    }
  }

  /// Fetches the ticket report for a specific bus from the API.
  Future<Map<String, dynamic>> _fetchTicketReport(String busId, String authToken) async {
    final uri = Uri.parse(ApiConfig.ownerTickets).replace(queryParameters: {'bus_id': busId});
    final response = await http.get(uri, headers: {'Authorization': 'Bearer $authToken'});
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['breakdown_by_bus'].isNotEmpty ? data['breakdown_by_bus'][0] : {};
    } else {
      throw Exception('Failed to load ticket reports: ${response.statusCode}');
    }
  }

  /// Builds the user interface for the seat management page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Row(children: [
          Icon(Icons.event_seat, color: Colors.black),
          SizedBox(width: 8),
          Text('SEAT MANAGEMENT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red, fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _fetchData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400, width: 1.5),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      child: _buildBusInfoCard(),
                    ),
                  ),
                ),
    );
  }

  /// Builds the card that displays the bus information.
  Widget _buildBusInfoCard() {
    final busNumber = _busDetails?['bus_number'] ?? 'N/A';
    final routeFrom = _busDetails?['route_from'] ?? 'N/A';
    final routeTo = _busDetails?['route_to'] ?? 'N/A';
    final totalSeats = _busDetails?['seat_capacity'] ?? 0;
    final ticketsSold = _ticketReport?['tickets_sold'] ?? 0;
    final availableSeats = totalSeats - ticketsSold;
    final revenue = _ticketReport?['revenue']?.toStringAsFixed(2) ?? '0.00';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoRow('Bus Number :', busNumber, isHeader: true),
        const SizedBox(height: 20),
        const Text('ROUTE :', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
          child: Row(
            children: [
              Expanded(
                child: _buildInfoRow('FROM:', routeFrom),
              ),
              Expanded(
                child: _buildInfoRow('TO:', routeTo),
              ),
            ],
          ),
        ),
        const SizedBox(height: 60),
        _buildInfoRow('TOTAL SEATS:', totalSeats.toString()),
        const SizedBox(height: 12),
        _buildInfoRow('AVAILABLE SEATS:', availableSeats.toString()),
        const SizedBox(height: 40),
        _buildInfoRow('REVENUE : ', '$revenue Taka'),
      ],
    );
  }

  /// A helper widget to create a consistent row for displaying a label and a value.
  Widget _buildInfoRow(String label, String value, {bool isHeader = false, TextAlign textAlign = TextAlign.start}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(
          fontSize: isHeader ? 18 : 16,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        )),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, textAlign: textAlign, style: TextStyle(
            fontSize: isHeader ? 18 : 16,
            fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          )),
        ),
      ],
    );
  }
}
