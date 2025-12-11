
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supervisor/login.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _inController;
  late final AnimationController _outController;
  bool _showFirst = true;

  @override
  void initState() {
    super.initState();
    _inController = AnimationController(vsync: this);
    _outController = AnimationController(vsync: this);

    _inController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showFirst = false;
        });
        _outController.forward();
      }
    });

    _outController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const Login()),
        );
      }
    });
  }

  @override
  void dispose() {
    _inController.dispose();
    _outController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _showFirst
            ? Lottie.asset(
                'assets/IconOUT.json',
                controller: _inController,
                width: 250,
                height: 250,
                onLoaded: (composition) {
                  _inController
                    ..duration = const Duration(seconds: 2)
                    ..forward();
                },
              )
            : Lottie.asset(
                'assets/iconIN.json',
                controller: _outController,
                width: 250,
                height: 250,
                onLoaded: (composition) {
                  _outController
                    ..duration = const Duration(seconds: 2)
                    ..forward();
                },
              ),
      ),
    );
  }
}
