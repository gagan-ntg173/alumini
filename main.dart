import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'splash.dart';

String? _firebaseSetupError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    _firebaseSetupError = error.message ?? error.code;
    debugPrint('Firebase initialization failed: $_firebaseSetupError');
  }
  runApp(const AlumMatchApp());
}

class AlumMatchApp extends StatelessWidget {
  const AlumMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SkillMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: SplashScreen(firebaseReady: _firebaseSetupError == null),
    );
  }
}
