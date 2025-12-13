import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supervisor/login.dart';

/// A splash screen widget that displays an entry animation when the application starts.
/// It shows a sequence of two Lottie animations before navigating to the [Login] page.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

/// The state class for the [SplashScreen], managing the animation controllers and the UI.
class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _inController;
  late final AnimationController _outController;
  bool _showFirst = true;

  /// Initializes the state and sets up the animation controllers and their listeners.
  @override
  void initState() {
    super.initState();
    _inController = AnimationController(vsync: this);
    _outController = AnimationController(vsync: this);

    // Listen for the completion of the first animation to trigger the second.
    _inController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFirst = false;
        });
        _outController.forward();
      }
    });

    // Listen for the completion of the second animation to navigate to the Login page.
    _outController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    });
  }

  /// Cleans up the animation controllers when the widget is disposed.
  @override
  void dispose() {
    _inController.dispose();
    _outController.dispose();
    super.dispose();
  }

  /// Builds the user interface for the splash screen, displaying the Lottie animations.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _showFirst
            ? Lottie.asset(
                'assets/IconOUT.json', // The first animation asset.
                controller: _inController,
                width: 250,
                height: 250,
                onLoaded: (composition) {
                  // Configure and start the first animation once loaded.
                  _inController
                    ..duration = const Duration(seconds: 2)
                    ..forward();
                },
              )
            : Lottie.asset(
                'assets/iconIN.json', // The second animation asset.
                controller: _outController,
                width: 250,
                height: 250,
                onLoaded: (composition) {
                  // Configure and start the second animation once loaded.
                  _outController
                    ..duration = const Duration(seconds: 2)
                    ..forward();
                },
              ),
      ),
    );
  }
}
