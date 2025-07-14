import 'package:flutter/material.dart';
import 'package:reme/src/features/auth/Views/loginView.dart';
import 'package:reme/src/features/auth/Views/registerView.dart';

class LoginOrRegister extends StatefulWidget {
  final Map<String, dynamic>? pendingAnalysisData;
  
  const LoginOrRegister({super.key, this.pendingAnalysisData});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {
  // initially, show the login page
  bool showLoginPage = true;

  // toggle between login and register page
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return Loginview(
        onTap: togglePages,
        pendingAnalysisData: widget.pendingAnalysisData,
      );
    } else {
      return Registerview(
        onTap: togglePages,
        pendingAnalysisData: widget.pendingAnalysisData,
      );
    }
  }
}