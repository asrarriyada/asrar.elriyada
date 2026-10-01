import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'home_screen.dart';
import 'screens/direct_article_screen.dart'; // استيراد صفحة عرض المقال المباشر
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

  // التقاط رابط الـ URL ومعرفة إذا كان هناك مقال مطلوب فتحه مباشرة
  String? articleTitleParam;
  try {
    final uri = Uri.base;
    // نفحص لو الرابط يحتوي على باراميتر 'title' أو 'code'
    if (uri.queryParameters.containsKey('title')) {
      articleTitleParam = uri.queryParameters['title'];
    } else if (uri.queryParameters.containsKey('code')) {
      articleTitleParam = uri.queryParameters['code'];
    }
  } catch (_) {}

  runApp(AsrarElriyadaApp(initialArticleTitle: articleTitleParam));
}

class AsrarElriyadaApp extends StatelessWidget {
  final String? initialArticleTitle;

  const AsrarElriyadaApp({super.key, this.initialArticleTitle});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'أسرار الرياضة',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        scaffoldBackgroundColor: const Color(0xFFF4F6F9),
      ),
      // المنطق الذكي: لو فيه رابط مقال في الـ URL افتح شاشة المقال مباشرة، وإلا افتح الرئيسية بشكل طبيعي تماماً
      home: initialArticleTitle != null && initialArticleTitle!.isNotEmpty
          ? DirectArticleScreen(articleTitle: initialArticleTitle!)
          : const WelcomeClockOverlay(
              child: HomeScreen(),
            ),
    );
  }
}