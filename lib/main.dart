import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
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
  String? _currentArticleParam;

  @override
  void initState() {
    super.initState();
    _parseUrlAndSetArticle();

    // الاستماع الفوري لتغييرات الـ URL في المتصفح
    if (kIsWeb) {
      html.window.onPopState.listen((event) {
        _parseUrlAndSetArticle();
      });

      // فحص مستمر خفيف جداً لالتقاط أي تغيير في الـ URL فور حدوثه من الأقسام
      Future.doWhile(() async {
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _parseUrlAndSetArticle();
        }
        return true;
      });
    }
  }

  void _parseUrlAndSetArticle() {
    try {
      final uri = Uri.base;
      String? paramValue;
      
      // التقاط الـ id أو title أو code من الرابط بكل احترافية
      if (uri.queryParameters.containsKey('id')) {
        paramValue = uri.queryParameters['id'];
      } else if (uri.queryParameters.containsKey('title')) {
        paramValue = uri.queryParameters['title'];
      } else if (uri.queryParameters.containsKey('code')) {
        paramValue = uri.queryParameters['code'];
      }

      if (_currentArticleParam != paramValue) {
        setState(() {
          _currentArticleParam = paramValue;
        });
      }
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
      // إذا وجدنا id أو param في الرابط، نفتح DirectArticleScreen فوراً
      home: _currentArticleParam != null && _currentArticleParam!.isNotEmpty
          ? DirectArticleScreen(articleTitle: _currentArticleParam!)
          : const WelcomeClockOverlay(
              child: HomeScreen(),
            ),
    );
  }
}