import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

class Homeview extends StatelessWidget {
  const Homeview({super.key});

  // Function to handle logout
  void logout() {
    FirebaseAuth.instance.signOut().then((value) {
      // Optionally, you can navigate to the login screen or show a message
      print("User logged out");
    }).catchError((error) {
      // Handle any errors that occur during logout
      print("Logout error: $error");
    });
  } // Missing closing bracket for logout method

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),

        //logout button
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: logout, // Missing closing parenthesis
          ), // Missing closing parenthesis for IconButton
        ], // Missing closing bracket for actions
      ), // Missing closing parenthesis for AppBar
      body: Center(
        child: Text(
          "RE: ME, Home View!",
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    );
  }
}