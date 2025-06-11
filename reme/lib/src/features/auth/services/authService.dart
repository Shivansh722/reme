import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';


class Authservice {

  signInWithGoogle() async {
    //begin interactive sign-in with Google
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
   
    //obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;
    
    //create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    //finally, sign in
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<LoginResult> signInWithLine() async {
    try {
      print("Starting LINE SDK login method in service...");
      print("Expected redirect URI: line3rdp.com.example.reme://auth");
      print("Scopes requested: profile, openid, email");
      
      final result = await LineSDK.instance.login(
        scopes: ["profile", "openid", "email"]
      );
      
      print("LINE SDK login successful in service");
      print("User ID: ${result.userProfile?.userId}");
      print("Display Name: ${result.userProfile?.displayName}");
      
      return result;
    } on PlatformException catch (e) {
      print("LINE SDK PlatformException: ${e.code} - ${e.message}");
      print("LINE SDK PlatformEx  ception details: ${e.details}");
      throw e.toString();
    } catch (e) {
      print("LINE SDK unexpected error: $e");
      throw e.toString();
    }
  }

  Future<void> signOutFromLine() async {
    try {
      await LineSDK.instance.logout();
    } on PlatformException catch (e) {
      throw e.toString();
    }
  }

  void showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
