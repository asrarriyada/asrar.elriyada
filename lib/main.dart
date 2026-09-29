import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'widgets/welcome_clock_overlay.dart'; // استيراد ملف الساعة الترحيبية المنفصل

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAWbnSugLxehHyOETDL5Enf0vDTvcse6z0",
      appId: "1:637313305746:web:accbb2beaede780b0daa4b",
      messagingSenderId: "637313305746",
      projectId: "asrar-elriyada-8ee46",
      authDomain: "asrar-elriyada-8ee46.firebaseapp.com",
      storageBucket: "asrar-elriyada-8ee46.firebasestorage.app",
    ),
  );

  runApp(const AsrarElriyadaApp());
}

class AsrarElriyadaApp extends StatelessWidget {
  const AsrarElriyadaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أسرار الرياضة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      // ربط الساعة الترحيبية الشفافة بكلمة ASE فوق الموقع
      home: const WelcomeClockOverlay(
        child: HomeScreen(),
      ),
    );
  }
}
