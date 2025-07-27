import 'package:flutter/material.dart';
import 'package:reme/src/features/home/views/homeView.dart';
import 'package:reme/src/helpers/helper_functions.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/widgets/customTextField.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth


class Registerview extends StatefulWidget {
  // Callback function to handle tap events
  final void Function()? onTap;
  final Map<String, dynamic>? pendingAnalysisData;

  const Registerview({super.key, required this.onTap, this.pendingAnalysisData});

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
  void registerUser() async {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      }
    );

    if(passwordController.text != confirmPasswordController.text) {
      Navigator.pop(context);
      showErrorMessage(context, 'Passwords do not match');
      return;
    } else {
      try {
        UserCredential? userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
      
        if (context.mounted) Navigator.pop(context);

        // Always go to HomeviewMain with detailed analysis tab
        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => HomeviewMain(
                initialTab: 3,
                faceImage: widget.pendingAnalysisData?['faceImage'],
                analysisResult: widget.pendingAnalysisData?['analysisResult'],
                scores: widget.pendingAnalysisData?['scores'],
              ),
            ),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (context.mounted) Navigator.pop(context);
        if (context.mounted) showErrorMessage(context, e.message.toString());
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