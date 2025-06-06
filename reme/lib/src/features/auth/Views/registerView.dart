import 'package:flutter/material.dart';
import 'package:reme/src/helpers/helper_functions.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/widgets/customTextField.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class Registerview extends StatefulWidget {

  // Callback function to handle tap events
  final void Function()? onTap;

  const Registerview({super.key, required this.onTap});

  @override
  State<Registerview> createState() => _RegisterviewState();
}

class _RegisterviewState extends State<Registerview> {
  //text controllers
  TextEditingController emailController = TextEditingController();

  TextEditingController passwordController = TextEditingController();

  TextEditingController confirmPasswordController = TextEditingController();

  TextEditingController userNameController = TextEditingController();

  //registerMethod
  void registerUser() async { // Added async here

    //show loading indicator
    showDialog(
      context: context,
      builder: (context) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    });

    //if pasword don't match, show error message
    if(passwordController.text != confirmPasswordController.text) {

      //hide loading indicator
      Navigator.pop(context);

      //show error message using our helper function
      showErrorMessage(context, 'Passwords do not match');
      return;
    } 

    //try creating the user
    else {
      try  {
        //create user
        UserCredential? userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      
          //pop loading circle
        if (context.mounted) Navigator.pop(context); // Added context.mounted check
      } on FirebaseAuthException catch (e) { // Corrected typo
      
        //hide loading indicator
        if (context.mounted) Navigator.pop(context); // Added context.mounted check
      
        //show error message using our helper function
        if (context.mounted) showErrorMessage(context, e.message.toString()); // Added context.mounted check
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        
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


              //username
              Customtextfield(
                hintText: 'Username',
                obscureText: false,
                controller: userNameController,
              ),

              const SizedBox(height: 10),

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

              //confirm password
                   Customtextfield(
                hintText: 'Confirm Password',
                obscureText: true,
                controller: confirmPasswordController,
              ),
          
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
              Custombutton(text: 'Register', onTap: registerUser),
          
              //don't have an account? Register
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account? ',
                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onTap, 
                    child: Text('Login',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.tertiary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              )

            ],
              ),
        )
      ),
    );
  }
}