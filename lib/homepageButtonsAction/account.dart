import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supervisor/login.dart';

/// A page that displays the current supervisor's account details,
/// including their name, phone number, and a list of assigned buses.
/// It also provides a way to log out.
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

/// The state class for the [AccountPage], managing its UI and data.
class _AccountPageState extends State<AccountPage> {
  final _storage = const FlutterSecureStorage();
  String? _userName;
  String? _userPhone;
  List<dynamic> _assignedBuses = [];

  /// Initializes the state and triggers the loading of user data from secure storage.
  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Loads the supervisor's name, phone number, and assigned buses from secure storage.
  /// It updates the UI with the fetched data.
  Future<void> _loadUserData() async {
    final userName = await _storage.read(key: 'user_name');
    final userPhone = await _storage.read(key: 'user_phone');
    final assignedBusesJson = await _storage.read(key: 'assigned_buses');

    if (assignedBusesJson != null) {
      if (mounted) {
        setState(() {
          _assignedBuses = json.decode(assignedBusesJson);
        });
      }
    }

    if (mounted) {
      setState(() {
        _userName = userName;
        _userPhone = userPhone;
      });
    }
  }

  /// Handles the logout process by deleting all data from secure storage
  /// and navigating the user back to the [Login] page.
  Future<void> _logout() async {
    await _storage.deleteAll();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const Login()),
            (Route<dynamic> route) => false,
      );
    }
  }

  /// A helper widget to build a consistent row for displaying a title and a value.
  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  /// Builds the user interface for the account page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('MY ACCOUNT', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.3), spreadRadius: 2, blurRadius: 8)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_userName != null) _buildDetailRow('Name:', _userName!),
                  if (_userPhone != null) _buildDetailRow('Phone:', _userPhone!),
                  const SizedBox(height: 24),
                  const Text('ASSIGNED BUSES:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(thickness: 1, height: 20),
                  if (_assignedBuses.isNotEmpty)
                    ..._assignedBuses.map((bus) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailRow('Bus Number:', bus['bus_number'] ?? 'N/A'),
                            _buildDetailRow('Bus Route:', '${bus['route_from'] ?? ''} to ${bus['route_to'] ?? ''}'),
                            _buildDetailRow('Departure:', bus['departure_time'] ?? 'N/A'),
                          ],
                        ),
                      );
                    }).toList(),
                  if (_assignedBuses.isEmpty)
                    const Text('No buses assigned.', style: TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _logout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: const Text('LOG OUT', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
