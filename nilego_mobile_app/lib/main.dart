import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'auth/auth_page.dart'; // <--- Make sure this file exists!
//import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // This connects your app to the Firebase Console you set up
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false, // Removes the little "Debug" banner
      home: AuthPage(), // Start at the Gatekeeper (Login Check)
    );
  }
}