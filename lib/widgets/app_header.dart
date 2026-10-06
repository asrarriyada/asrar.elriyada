import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../category_news_screen.dart';
import '../category_videos_screen.dart';
import '../about_screen.dart';
import '../home_screen.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  String _formatCurrentTime() {
    final now = DateTime.now();
    const days = ['الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];

    String dayName = days[now.weekday - 1];
    String monthName = months[now.month - 1];
    
    int hour = now.hour;
    String period = 'ص';
    if (hour >= 12) {
      period = 'م';
      if (hour > 12) hour -= 12;
    }
    if (hour == 0) hour = 12;

    String minute = now.minute.toString().padLeft(2, '0');

    return '$dayName، ${now.day} $monthName | $hour:$minute $period';
  }

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      height: 52, // تقليل الارتفاع ليصبح رفيعاً وأنيقاً
      color: const Color(0xFFB71C1C),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 1. أقصى اليمين: شعار الموقع واسمه بحجم متناسق
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => const AboutScreen(),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
                    transitionDuration: Duration.zero,
                  ),
                );
              },
              borderRadius: BorderRadius.circular(4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 38,
                    child: Image.asset(
                      'assets/images/logo/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 6),
                    const Text(
                      'أسرار الرياضة',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            
            // 2. المنتصف: أزرار الأقسام بشكل منسق وشيك
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildHomeItem(context, 'الرئيسية'),
                      _buildNavItem(context, 'مصر'),
                      _buildNavItem(context, 'عالمي'),
                      _buildNavItem(context, 'المحترفون', isHighlight: true),
                      _buildNavItem(context, 'الدوري المصري'),
                      _buildNavItem(context, 'مقالات'),
                      _buildNavItem(context, 'مباريات'),
                      _buildNavItem(context, 'ألعاب أخرى'),
                      _buildVideoNavItem(context, 'فيديوهات وصور'),
                    ],
                  ),
                ),
              ),
            ),

            // 3. أقصى اليسار: التاريخ وأزرار السوشيال الميديا المدمجة
            if (!isMobile)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatCurrentTime(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSocialBox('فيسبوك', 'https://www.facebook.com/asrarelryidaa'),
                      _buildSocialBox('يوتيوب', 'https://www.youtube.com/@AsrarElryida'),
                      _buildSocialBox('انستجرام', 'https://www.instagram.com/asrarelryida2026/'),
                      _buildSocialBox('تويتر', 'https://x.com/ASRARELRAYIDA'),
                      _buildSocialBox('تيك توك', 'https://www.tiktok.com/@asrarelryida'),
                      _buildSocialBox('واتساب', 'https://whatsapp.com'),
                      _buildSocialBox('تليجرام', 'https://telegram.org'),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeItem(BuildContext context, String title) {
    return InkWell(
      onTap: () {
        if (kIsWeb) {
          try {
            // استخراج النطاق الأساسي فقط وإعادة توجيه المتصفح لتنظيف الـ ID والـ Query Parameters تماماً
            final currentUri = Uri.parse(html.window.location.href);
            final cleanOrigin = '${currentUri.scheme}://${currentUri.authority}${currentUri.path}';
            html.window.location.href = cleanOrigin;
            return;
          } catch (_) {}
        }
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
          (route) => false,
        );
      },
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, String title, {bool isHighlight = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => CategoryNewsScreen(categoryName: title),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      },
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          title,
          style: TextStyle(
            color: isHighlight ? Colors.amberAccent : Colors.white,
            fontSize: 12,
            fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildVideoNavItem(BuildContext context, String title, {bool isHighlight = false}) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const CategoryVideosScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      },
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBox(String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: InkWell(
        onTap: () => _launchURL(url),
        borderRadius: BorderRadius.circular(3),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.15),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 0.6,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}