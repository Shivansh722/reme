import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:reme/src/helpers/helper_functions.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/widgets/customTextField.dart';
import 'package:reme/src/widgets/squareTile.dart';

class Loginview extends StatefulWidget {

  // Callback function to handle tap events
  final void Function() onTap;

  const Loginview({super.key, required this.onTap});

  @override
  State<Loginview> createState() => _LoginviewState();
}

class _LoginviewState extends State<Loginview> {
  //text controllers
  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  //login method
  void login() async {
    
    //show loading indicator
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );

    //try logging in the user
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text,
        password: passwordController.text,
      );

      //pop loading circle
      Navigator.pop(context); 
  }
  //display if any errors
  on FirebaseAuthException catch (e) { 
      //hide loading indicator
      Navigator.pop(context);

      //show error message using our helper function
      showErrorMessage(context, e.code);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  //logo
                
                  //app name
                  const Text('R E: M E ', style: TextStyle(
                    fontSize: 32,
                  )),

                  const SizedBox(height: 20),

                  // //email
                  Customtextfield(
                    hintText: 'Email',
                    obscureText: false,
                    controller: emailController,
                  ),

                  const SizedBox(height: 10),
              
              
                  //password
                  Customtextfield(
                    hintText: 'Password',
                    obscureText: true,
                    controller: passwordController,
                  ),

                  const SizedBox(height: 10),
              
                  //forgot password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('Forgot Password?',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.inversePrimary,
                          fontSize: 16,
                        ),),
                    ],
                  ),
              
                  const SizedBox(height: 24),
                  //login button
                  Custombutton(text: 'Login', onTap: login),
              
                  const SizedBox(height: 40),

                  //divider with or sign in with google
                  Row(children: [
                    //two dividers
                    Expanded
                      (child: Divider(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        thickness: 0.5,
                        )),

                    const SizedBox(width: 10),

                    const Text('Or continue with', style: TextStyle(
                      fontSize: 16,
                    )),

                    const SizedBox(width: 10),

                    Expanded
                      (child: Divider(
                        color: Theme.of(context).colorScheme.inversePrimary,
                        thickness: 0.5,
                      )),
                  ],),

                  const SizedBox(height: 40),
                 
                  //sign in with google button or LINE buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //google button
                      Squaretile(imagePath: 'lib/assets/images/google_logo.png'),
                    
                      const SizedBox(width: 25),

                      // LINE button
                      Squaretile(imagePath: 'lib/assets/images/line_logo.png'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          // Registration link at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Don\'t have an account? ',
                  style: TextStyle(
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onTap, 
                  child: Text('Register here',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.tertiary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}