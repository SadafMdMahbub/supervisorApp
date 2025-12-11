import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supervisor/appstate.dart'; // Import the AppState
import 'package:supervisor/splash_screen.dart'; // Your initial screen

void main() {
  runApp(
    // ChangeNotifierProvider creates and provides an instance of AppState
    // to all descendant widgets in the application.
    ChangeNotifierProvider(
      create: (context) => AppState(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // MaterialApp is now a child of ChangeNotifierProvider.
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Supervisor App', // It's good practice to add a title
      theme: ThemeData(
        // You can define a global theme here
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      // Your app correctly starts with the SplashScreen.
      home: const SplashScreen(),
    );
  }
}
