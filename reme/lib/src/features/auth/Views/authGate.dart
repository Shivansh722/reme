import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/Views/login_or_register.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/features/diagnosis/views/detailedAnalysisScreen.dart';

class Authgate extends StatelessWidget {
  final Map<String, dynamic>? pendingAnalysisData;
  
  const Authgate({super.key, this.pendingAnalysisData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if(snapshot.hasData) {
            // Check if there's pending analysis data to show
            if (pendingAnalysisData != null) {
              // Navigate to detailed analysis after login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HomeviewMain(
                      initialTab: 3,
                      faceImage: pendingAnalysisData?['faceImage'],
                      analysisResult: pendingAnalysisData?['analysisResult'],
                      scores: pendingAnalysisData?['scores'],
                    ),
                  ),
                );
              });
              return const Center(child: CircularProgressIndicator());
            } else {
              return const HomeviewMain();
            }
          } else {
            // user not logged in
            return LoginOrRegister(pendingAnalysisData: pendingAnalysisData);
          }
        },
      ),
    );
  }
}