import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:reme/src/features/shared/services/firestore_service.dart'; // Add this import


class Authservice {
  final FirestoreService _firestoreService = FirestoreService();

  Future<UserCredential> signInWithGoogle() async {
    // Begin interactive sign-in with Google
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
   
    // Obtain auth details from request
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;
    
    // Create a new credential for user
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );

    // Sign in with Firebase
    final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
    
    // Save user data to Firestore
    await _firestoreService.saveUserData(
      userId: userCredential.user!.uid,
      email: userCredential.user!.email ?? '',
      displayName: userCredential.user!.displayName,
      photoURL: userCredential.user!.photoURL,
      provider: 'google',
    );

    return userCredential;
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

  // Add method to save email/password user data
  Future<void> saveEmailPasswordUserData(User user, String? displayName) async {
    await _firestoreService.saveUserData(
      userId: user.uid,
      email: user.email ?? '',
      displayName: displayName,
      provider: 'email',
    );
  }
}
