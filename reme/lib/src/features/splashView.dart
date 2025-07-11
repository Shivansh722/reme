import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/Views/authGate.dart';
import 'package:reme/src/features/diagnosis/views/diagnosisView.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Splashview extends StatefulWidget {
  const Splashview({super.key});

  @override
  State<Splashview> createState() => _SplashviewState();
}

// Simple test function you can call from somewhere in your app
Future<void> testFirestoreConnection() async {
  try {
    await FirebaseFirestore.instance.collection('test').add({
      'timestamp': FieldValue.serverTimestamp(),
      'testField': 'This is a test'
    });
    print('Firestore is connected and working!');
  } catch (e) {
    print('Firestore error: $e');
  }
}

class _SplashviewState extends State<Splashview> {
  @override
  void initState() {
    super.initState();
    // Test Firestore connection
    testFirestoreConnection();
    
    // Set timer to navigate after 2 seconds
    Timer(
      const Duration(seconds: 2),
      () => _navigateToNextScreen(),
    );
  }
  
  // Check auth state and navigate accordingly
  void _navigateToNextScreen() {
    // Check if user is logged in
    final User? currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser != null) {
      // User is logged in, navigate to HomeviewMain
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeviewMain()),
      );
    } else {
      // User is not logged in, navigate to DiagnosisView (default flow)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DiagnosisView()),
      );
    }
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