import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:supervisor/api_config.dart';

class InboxPage extends StatefulWidget {
  const InboxPage({super.key});

  @override
  _InboxPageState createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage> {
  List<dynamic> _requests = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();

  Completer<void>? _refreshCompleter;

  @override
  void initState() {
    super.initState();
    _fetchBookingRequests();
  }

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
      debugPrint('Inbox API Status Code: ${response.statusCode}');
      debugPrint('Inbox API Response Body:');
      debugPrint(response.body);
      debugPrint('--------------------------------------------------');

      if (mounted) {
        if (response.statusCode == 200) {
          final decodedBody = json.decode(response.body);
          if (decodedBody is List) {
            setState(() {
              _requests = decodedBody.where((req) => req['status'] == 'accepted').toList();
            });
          } else {
            throw Exception('API response is not in the expected list format.');
          }
        } else {
          final error = json.decode(response.body);
          throw Exception("Failed to load requests: ${error['detail'] ?? 'Server returned status ${response.statusCode}'}");
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

  Future<void> _handleRefresh() {
    _refreshCompleter = Completer<void>();
    _fetchBookingRequests();
    return _refreshCompleter!.future;
  }

  String _formatRequestTime(String isoDateTime) {
    try {
      final dateTime = DateTime.parse(isoDateTime);
      return DateFormat("yyyy-MM-dd 'Time:' HH:mm").format(dateTime);
    } catch (e) {
      return isoDateTime;
    }
  }

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
          'No accepted seat requests.', textAlign: TextAlign.center));
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
              Text('Request Time: ${_formatRequestTime(request['request_time'])}',
                  style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

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
          Icon(Icons.inbox, color: Colors.black),
          SizedBox(width: 8),
          Text('Inbox', style: TextStyle(
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
