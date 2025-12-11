import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:supervisor/appstate.dart';
import 'package:supervisor/api_config.dart';
import 'package:supervisor/homepageButtonsAction/account.dart';
import 'package:supervisor/homepageButtonsAction/managebus.dart';
import 'package:supervisor/homepageButtonsAction/managebus2.dart';
import 'package:supervisor/homepageButtonsAction/seatManagement.dart';
import 'package:supervisor/homepageButtonsAction/seatRequest.dart';
import 'package:supervisor/homepageButtonsAction/inbox.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _seatRequestCount = 0;
  String? _busId;
  final _storage = const FlutterSecureStorage();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBusIdAndFetchData();
    // This timer will call the function to fetch seat requests every 10 seconds.
    _timer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      if (mounted) {
        _fetchSeatRequestCount();
      }
    });
  }

  @override
  void dispose() {
    // It's important to cancel the timer when the widget is removed from the screen.
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBusIdAndFetchData() async {
    final busId = await _storage.read(key: 'bus_id');
    if (mounted) {
      setState(() {
        _busId = busId;
      });
    }
    if (_busId != null) {
      _fetchSeatRequestCount();
    }
  }

  Future<void> _fetchSeatRequestCount() async {
    if (_busId == null) {
      if (mounted) setState(() => _seatRequestCount = 0);
      return;
    }

    try {
      final authToken = await _storage.read(key: 'access_token');
      final uri = Uri.parse(ApiConfig.getBookingRequests).replace(
          queryParameters: {'bus_id': _busId!});

      final response = await http.get(
          uri, headers: {'Authorization': 'Bearer $authToken'});

      if (response.statusCode == 200) {
        final List<dynamic> requests = json.decode(response.body);
        if (mounted) {
          setState(() {
            _seatRequestCount = requests.length;
          });
        }
      } else {
        if (mounted) setState(() => _seatRequestCount = 0);
      }
    } catch (e) {
      if (mounted) setState(() => _seatRequestCount = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: const Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.black, size: 30),
                SizedBox(width: 8),
                Text('BUS AGENT', style: TextStyle(color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24)),
              ],
            ),
            automaticallyImplyLeading: false,
            actions: [
              InkWell(
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const AccountPage())),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_circle_outlined, color: Colors.black,
                          size: 28),
                      Text('Account',
                          style: TextStyle(color: Colors.black, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchSeatRequestCount,
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text('Homepage', style: const TextStyle(color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30.0, vertical: 10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300,
                            width: 1),
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildStartBusButton(appState),
                          _buildSeatManagementButton(),
                          _buildSeatRequestButton(),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                      left: 30.0, bottom: 20.0, top: 10.0, right: 30.0),
                  child: Row(
                    children: [
                      _buildInboxButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartBusButton(AppState appState) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () async {
            if (appState.isJourneyStarted) {
              Navigator.push(context, MaterialPageRoute(
                  builder: (context) => const ManageBus2Page()));
            } else {
              if (_busId != null) {
                final busId = int.tryParse(_busId!);
                Navigator.push(context, MaterialPageRoute(
                    builder: (context) => ManageBusPage(busId: busId!)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Bus ID not found.')));
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
          ),
          child: Text(
            appState.isJourneyStarted ? 'MANAGE BUS' : 'START BUS',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          appState.isJourneyStarted ? 'Manage your Journey' : 'Start JOURNEY',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSeatManagementButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: () async {
            Navigator.push(context, MaterialPageRoute(
                builder: (context) => const SeatManagementPage()));
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(vertical: 20),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28)),
          ),
          child: const Text(
            'SEAT MANAGEMENT',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Manage Bus Seats',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey[700], fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildSeatRequestButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 140,
          width: 140,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              decoration: const BoxDecoration(
                  color: Colors.black, shape: BoxShape.circle),
              child: Center(
                child: InkWell(
                  onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(
                        builder: (context) => const SeatRequestPage()));
                    _fetchSeatRequestCount();
                  },
                  customBorder: const CircleBorder(),
                  child: const Center(
                      child: Text('SEAT\nREQUEST',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ))),
                ),
              ),
            ),
            if (_seatRequestCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: Text(_seatRequestCount.toString(),
                      style: const TextStyle(color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 8),
        Text('See Seat Requests',
            style: TextStyle(color: Colors.grey[700], fontSize: 14)),
      ],
    );
  }

  Widget _buildInboxButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => const InboxPage()));
          },
          icon: const Icon(Icons.inbox, color: Colors.black, size: 36),
          iconSize: 36,
        ),
        const Text(
            'INBOX', style: TextStyle(color: Colors.black, fontSize: 12)),
      ],
    );
  }
}