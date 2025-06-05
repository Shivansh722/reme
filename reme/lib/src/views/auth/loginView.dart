import 'package:flutter/material.dart';

class Loginview extends StatelessWidget {
  const Loginview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //logo

            //app name
            const Text('R E M E ', style: TextStyle(
              fontSize: 32,
            )),
            //email

            

            //password

            //forgot password

            //login button

            //don't have an account? Register
          ],
    )
      ),
    );
  }
} 