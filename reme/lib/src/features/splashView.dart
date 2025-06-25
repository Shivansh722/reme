import 'package:flutter/material.dart';
import 'dart:async';
import 'package:reme/src/features/auth/Views/authGate.dart';

class Splashview extends StatefulWidget {
  const Splashview({super.key});

  @override
  State<Splashview> createState() => _SplashviewState();
}

class _SplashviewState extends State<Splashview> {
  @override
  void initState() {
    super.initState();
    // Set timer to navigate after 2 seconds
    Timer(
      const Duration(seconds: 2),
      () => Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Authgate()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              width: 400,
              height: 400,
            ),
          ],
        ),
      ),
    );
  }
}