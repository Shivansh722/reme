import 'package:flutter/material.dart';
import 'package:reme/src/widgets/customButton.dart';
import 'package:reme/src/widgets/customTextField.dart';

class Registerview extends StatelessWidget {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();




   Registerview({super.key});

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
              const Text('R E M E ', style: TextStyle(
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
              Custombutton(text: 'Register', onTap: () {

              }),
          
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
                  Text('Login',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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