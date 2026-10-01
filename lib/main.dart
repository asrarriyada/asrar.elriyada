import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'home_screen.dart';
import 'screens/direct_article_screen.dart';
import 'widgets/welcome_clock_overlay.dart'; 

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

class AsrarElriyadaApp extends StatefulWidget {
  const AsrarElriyadaApp({super.key});

  @override
  State<AsrarElriyadaApp> createState() => _AsrarElriyadaAppState();
}

class _AsrarElriyadaAppState extends State<AsrarElriyadaApp> {
  String? _currentArticleTitle;

  @override
  void initState() {
    super.initState();
    _parseUrlAndSetArticle();

    // الاستماع لتغييرات الـ URL (مثل أزرار الرجوع والتقدم في المتصفح)
    if (kIsWeb) {
      html.window.onPopState.listen((event) {
        _parseUrlAndSetArticle();
      });
    }
  }

  void _parseUrlAndSetArticle() {
    try {
      final uri = Uri.base;
      String? titleParam;
      if (uri.queryParameters.containsKey('title')) {
        titleParam = uri.queryParameters['title'];
      } else if (uri.queryParameters.containsKey('code')) {
        titleParam = uri.queryParameters['code'];
      }

      setState(() {
        _currentArticleTitle = titleParam;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أسرار الرياضة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      // بناء الشاشة بناءً على العنوان الحالي في الـ URL ديناميكياً
      home: _currentArticleTitle != null && _currentArticleTitle!.isNotEmpty
          ? DirectArticleScreen(articleTitle: _currentArticleTitle!)
          : const WelcomeClockOverlay(
              child: HomeScreen(),
            ),
    );
  }
}