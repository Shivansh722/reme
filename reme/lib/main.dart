import 'package:flutter/material.dart';
import 'package:flutter_line_sdk/flutter_line_sdk.dart';
import 'package:reme/core/theme/light_mode.dart';
import 'package:reme/src/features/auth/Views/authGate.dart';
import 'package:reme/src/features/auth/Views/loginView.dart';
import 'package:reme/src/features/auth/Views/login_or_register.dart';
import 'package:reme/src/features/auth/Views/registerView.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:reme/src/features/home/views/homeView_main.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LineSDK.instance.setup("${2007541783}").then((_) {
    print("LineSDK Prepared");
 });
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Load .env file
  await dotenv.load();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'Flutter Demo',
      theme:lightMode,
      home:  HomeviewMain(),
      //keep here authgate later
    );
  }
}

