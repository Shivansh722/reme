import 'package:flutter/material.dart';
import 'package:reme/src/views/auth/loginView.dart';
import 'package:reme/src/views/auth/registerView.dart';

class LoginOrRegister extends StatefulWidget {
  const LoginOrRegister({super.key});

  @override
  State<LoginOrRegister> createState() => _LoginOrRegisterState();
}

class _LoginOrRegisterState extends State<LoginOrRegister> {

  //initially show login view
   bool showLoginView = true;


  // toggle between login and register view
  void toggleView() {
    setState(() {
      showLoginView = !showLoginView;
    });
  }



  @override
  Widget build(BuildContext context) {
    if(showLoginView) {
      return Loginview(
        onTap: toggleView,
      );
    } else {
      return Registerview(
        onTap: toggleView,
      );
    }
  }
}