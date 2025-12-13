import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supervisor/api_config.dart';

/// A page that displays a list of pending seat booking requests.
/// Supervisors can accept or reject these requests.
class SeatRequestPage extends StatefulWidget {
  const SeatRequestPage({super.key});

  @override
  _SeatRequestPageState createState() => _SeatRequestPageState();
}

/// The state class for the [SeatRequestPage], managing its UI and data.
class _SeatRequestPageState extends State<SeatRequestPage> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  Completer<void>? _refreshCompleter;

  /// Initializes the state and triggers the initial fetch of booking requests.
  @override
  void initState() {
    super.initState();
    _fetchBookingRequests();
  }

  /// Fetches booking requests from the API for the current bus.
  /// It handles authentication, loading states, and error messages.
  Future<void> _fetchBookingRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authToken = await _storage.read(key: 'access_token');
      if (authToken == null || authToken.isEmpty) {
        throw Exception('Authentication token not found. Please log in again.');
      }

      final busId = await _storage.read(key: 'bus_id');
      if (busId == null || busId.isEmpty) {
        throw Exception('Bus ID not found. Please select a bus first.');
      }

      final uri = Uri.parse(ApiConfig.getBookingRequests).replace(
          queryParameters: {'bus_id': busId});

      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      ).timeout(const Duration(seconds: 15));

      debugPrint('--------------------------------------------------');
      debugPrint('Seat Request API Status Code: ${response.statusCode}');
      debugPrint('Seat Request API Response Body:');
      debugPrint(response.body);
      debugPrint('--------------------------------------------------');

      if (mounted) {
        if (response.statusCode == 200) {
          final decodedBody = json.decode(response.body);
          if (decodedBody is List) {
            setState(() {
              _requests = decodedBody;
            });
          } else {
            throw Exception('API response is not in the expected list format.');
          }
        } else {
          final error = json.decode(response.body);
          throw Exception('Failed to load requests: ${error['detail'] ??
              'Server returned status ${response.statusCode}'}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (_refreshCompleter?.isCompleted == false) {
          _refreshCompleter!.complete();
        }
      }
    }
  }

  /// Enables pull-to-refresh functionality by re-fetching booking requests.
  Future<void> _handleRefresh() {
    _refreshCompleter = Completer<void>();
    _fetchBookingRequests();
    return _refreshCompleter!.future;
  }

  /// Saves the result of an accepted or rejected request to local secure storage.
  /// This creates a history of actions taken by the supervisor.
  Future<void> _saveRequestHistory(String bookingId, String status,
      {Map<String, dynamic>? passengerDetails}) async {
    try {
      final supervisorId = await _storage.read(key: 'user_id');
      if (supervisorId == null) return;

      final historyKey = 'inbox_history_$supervisorId';
      final existingHistory = await _storage.read(key: historyKey) ?? '[]';
      List<dynamic> history = json.decode(existingHistory);

      history.insert(0, {
        'requestId': bookingId,
        'status': status,
        'timestamp': DateTime.now().toIso8601String(),
        'passenger': passengerDetails,
      });

      if (history.length > 50) history = history.sublist(0, 50);
      await _storage.write(key: historyKey, value: json.encode(history));
    } catch (e) {
      debugPrint("Error saving request history: $e");
    }
  }

  /// Handles the supervisor's action to either accept or reject a booking request.
  /// It sends the appropriate API call and updates the UI upon completion.
  Future<void> _handleRequest(String bookingId, bool accept) async {
    final url = accept ? ApiConfig.acceptBooking : ApiConfig.rejectBooking;
    final status = accept ? 'accepted' : 'rejected';

    try {
      final authToken = await _storage.read(key: 'access_token');
      final response = await http.post(Uri.parse(url), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      }, body: json.encode({'booking_id': bookingId}));

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        final passengerDetails = responseData['passenger'] as Map<
            String,
            dynamic>?;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Request $status successfully!')));
        }
        await _saveRequestHistory(
            bookingId, status, passengerDetails: passengerDetails);
        await _fetchBookingRequests();
      } else {
        final error = json.decode(response.body);
        throw Exception(
            'Failed to update request: ${error['detail'] ?? 'Unknown error'}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    }
  }

  /// Formats an ISO 8601 date-time string into a more readable format.
  String _formatRequestTime(String isoDateTime) {
    try {
      final dateTime = DateTime.parse(isoDateTime);
      return DateFormat("yyyy-MM-dd 'Time:' HH:mm").format(dateTime);
    } catch (e) {
      return isoDateTime;
    }
  }

  /// Builds the main body of the widget, displaying loading indicators,
  /// error messages, or the list of booking requests.
  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchBookingRequests,
                child: const Text('Try Again'),
              )
            ],
          ),
        ),
      );
    }

    if (_requests.isEmpty) {
      return const Center(child: Text(
          'No pending seat requests.', textAlign: TextAlign.center));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final request = _requests[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID:${request['id']}', style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 8),
              Text('Request Time: ${_formatRequestTime(
                  request['request_time'])}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
              if (request['status'] == 'pending')
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () =>
                          _handleRequest(request['id'].toString(), false),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                          'REJECT', style: TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () =>
                          _handleRequest(request['id'].toString(), true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                          'ACCEPT', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main scaffold and app bar for the Seat Request page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.of(context).pop()),
        title: const Row(children: [
          Icon(Icons.event_seat, color: Colors.black),
          SizedBox(width: 8),
          Text('Seat Requests', style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold)),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: _buildBody(),
      ),
    );
  }
}
