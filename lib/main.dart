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

    if (kIsWeb) {
      html.window.onPopState.listen((event) {
        _parseUrlAndSetArticle();
      });

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

  void _clearArticleUrl() {
    if (kIsWeb) {
      try {
        html.window.history.pushState(null, 'أسرار الرياضة', '/asrar.elriyada/');
      } catch (_) {}
    }
    setState(() {
      _currentArticleParam = null;
    });
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
      home: _currentArticleParam != null && _currentArticleParam!.isNotEmpty
          ? PopScope(
              canPop: true,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) {
                  _clearArticleUrl();
                }
              },
              child: DirectArticleScreen(articleTitle: _currentArticleParam!),
            )
          : const WelcomeClockOverlay(
              child: HomeScreen(),
            ),
    );
  }
}