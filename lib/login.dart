import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supervisor/api_config.dart';
import 'package:supervisor/selectbus.dart';

/// A custom [TextEditingController] designed for handling phone numbers with a fixed prefix.
/// It ensures the prefix is always present and handles cursor placement.
class PhoneNumberController extends TextEditingController {
  final String prefix;

  PhoneNumberController({required this.prefix}) {
    text = prefix;
  }

  /// Overridden to ensure the prefix is always at the start of the text.
  @override
  set text(String newText) {
    if (!newText.startsWith(prefix)) {
      super.text = prefix;
    } else {
      super.text = newText;
    }
    moveCursorToEnd();
  }

  /// Overridden to control the text value and selection, preventing prefix deletion.
  @override
  set value(TextEditingValue newValue) {
    var newText = newValue.text;

    if (newText.length < prefix.length || !newText.startsWith(prefix)) {
      newText = prefix;
    }

    int newSelectionStart = newValue.selection.start;
    if (newSelectionStart < prefix.length) {
      newSelectionStart = newText.length;
    }

    super.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newSelectionStart),
    );
  }

  /// Moves the cursor to the end of the text field.
  void moveCursorToEnd() {
    selection = TextSelection.fromPosition(TextPosition(offset: text.length));
  }

  /// A getter to retrieve only the numeric part of the phone number, without the prefix.
  String get number => text.substring(prefix.length);
}

/// The [Login] page widget, which is a [StatefulWidget] to handle dynamic state changes.
class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

/// The state class for the [Login] page, containing the UI and business logic.
class _LoginState extends State<Login> {
  final PhoneNumberController _phoneController =
  PhoneNumberController(prefix: '+880');

  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  final _storage = const FlutterSecureStorage();

  /// Cleans up the controllers when the widget is removed from the widget tree.
  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handles the login process by sending a request to the API.
  /// It validates user input, manages loading states, and handles navigation.
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final phone = _phoneController.text;
      final password = _passwordController.text;

      if (_phoneController.number.length < 10) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please enter a valid 11-digit phone number.')),
        );
        setState(() => _isLoading = false);
        return;
      }

      final url = Uri.parse(ApiConfig.login);
      final requestBody = {'phone': phone, 'password': password};

      final response = await http
          .post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final user = data['user'] as Map<String, dynamic>?;
        final role = user?['role'] as String?;
        final accessToken = data['access_token'] as String?;

        final assignedBuses = data['assigned_buses'] as List<dynamic>?;
        String? assignedBusesJson;

        if (assignedBuses != null && assignedBuses.isNotEmpty) {
          assignedBusesJson = json.encode(assignedBuses);
        }

        if (role == 'supervisor') {
          if (accessToken != null) {
            await _storage.write(key: 'access_token', value: accessToken);
            await _storage.write(key: 'user_name', value: user?['name']);
            await _storage.write(key: 'user_phone', value: phone);
            if (assignedBusesJson != null) {
              await _storage.write(
                  key: 'assigned_buses', value: assignedBusesJson);
            }

            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const SelectBusPage()),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text(
                      'Login failed: Required data not provided by server.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Only supervisors can log in.')),
          );
        }
      } else {
        String errorMessage = 'Login failed. Please try again.';
        try {
          final errorData = json.decode(response.body);
          if (errorData['message'] != null) {
            errorMessage = errorData['message'];
          }
        } catch (e) {
          // Ignore if parsing fails
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Cannot connect to server. Please check your connection.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Builds the user interface for the login page.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 50),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 40, color: Colors.black),
                  SizedBox(width: 10),
                  Text(
                    'BUS AGENT',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'LOGIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 50),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(30.0),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Icon(
                      Icons.person,
                      size: 90,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textAlign: TextAlign.center,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(14),
                      ],
                      decoration: InputDecoration(
                        hintText: 'Enter phone',
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.black,
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: 'Enter Password',
                        hintStyle:
                        TextStyle(color: Colors.white.withOpacity(0.7)),
                        filled: true,
                        fillColor: Colors.black,
                        contentPadding:
                        const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30.0),
                          borderSide:
                          const BorderSide(color: Colors.blue, width: 2.0),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : Hero(
                  tag: 'login_button',
                  child: ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
