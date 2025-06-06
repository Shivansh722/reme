import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:reme/src/features/auth/Views/login_or_register.dart';
import 'package:reme/src/features/home/homeView.dart';


class Authgate extends StatelessWidget {
  const Authgate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // user is logged in
          if(snapshot.hasData) {
            return const Homeview(); // Replace with your home view
          } else {
            // user not logged in
            return const LoginOrRegister(); // Replace with your login or register view
          }
        },
      ),
    );
  }
}