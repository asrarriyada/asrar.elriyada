import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'widgets/app_header.dart';
import 'widgets/matches_tabs_banner.dart';
import 'widgets/matches_ticker_widget.dart';
import 'widgets/news_section_center.dart'; 
import 'widgets/matches_and_sections_body.dart'; 
import 'login_screen.dart';
import 'widgets/teams_ticker_widget.dart';
import 'category_videos_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentSelectedDay = 'today'; // اليوم الافتراضي

  @override
  void initState() {
    super.initState();
    // تنظيف رابط المتصفح بأمان وإزالة الـ ID فقط عند التواجد في الرئيسية
    if (kIsWeb) {
      try {
        final currentHref = html.window.location.href;
        if (currentHref.contains('?id=')) {
          final cleanUrl = currentHref.split('?')[0];
          html.window.history.replaceState({}, '', cleanUrl);
        }
      } catch (_) {}
    }
  }

  // دالة استخراج كود الفيديو من أي رابط يوتيوب
  String? _extractYouTubeId(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.host.contains('youtu.be')) {
        return uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
      } else if (uri.host.contains('youtube.com')) {
        return uri.queryParameters['v'];
      }
    } catch (_) {}
    return null;
  }

  // دالة تشغيل الفيديو داخل نافذة منبثقة في الصفحة الرئيسية
  void _playVideoInsideModal(BuildContext context, String videoUrl, String title) {
    final videoId = _extractYouTubeId(videoUrl);

    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رابط الفيديو غير صالح أو غير مدعوم للمشغل الداخلي')),
      );
      return;
    }

    final controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: true,
        showFullscreenButton: true,
        strictRelatedVideos: true,
      ),
    );

    showDialog(
      context: context,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: SizedBox(
            width: 700,
            height: 400,
            child: YoutubePlayer(
              controller: controller,
              aspectRatio: 16 / 9,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                controller.close();
                Navigator.pop(context);
              },
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const AppHeader(),
              // البانر الرمادي الأساسي يتحكم في اليوم المختار
              MatchesTabsBanner(
                onDaySelected: (dayKey) {
                  setState(() {
                    _currentSelectedDay = dayKey;
                  });
                },
              ),
              // الشريط الأسود يعرض المباريات مفلترة حسب اختيار البانر الرمادي
              MatchesTickerWidget(selectedDayKey: _currentSelectedDay),
              const SizedBox(height: 10),
              const TeamsTickerWidget(),
              const SizedBox(height: 20),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12.0 : 24.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1050),
                    child: Column(
                      children: [
                        const NewsSectionCenter(),
                        const SizedBox(height: 24),
                        
                        // --- قسم الفيديوهات والصور المصغر في الصفحة الرئيسية ---
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    '| فيديوهات وصور',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const CategoryVideosScreen()),
                                      );
                                    },
                                    child: const Text('المزيد -', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              StreamBuilder<QuerySnapshot>(
                                stream: FirebaseFirestore.instance.collection('videos_and_photos').orderBy('createdAt', descending: true).limit(3).snapshots(),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                                    return const Padding(
                                      padding: EdgeInsets.all(20.0),
                                      child: Center(child: Text('لا توجد فيديوهات منشورة حالياً في الرئيسية.', style: TextStyle(color: Colors.grey, fontSize: 13))),
                                    );
                                  }
                                  final docs = snapshot.data!.docs;

                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool isScreenMobile = constraints.maxWidth < 768;
                                      return GridView.builder(
                                        shrinkWrap: true,
                                        physics: const NeverScrollableScrollPhysics(),
                                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: isScreenMobile ? 1 : 3, // 3 فيديوهات بالعرض في الشاشات الكبيرة
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 16 / 10,
                                        ),
                                        itemCount: docs.length,
                                        itemBuilder: (context, index) {
                                          final data = docs[index].data() as Map<String, dynamic>;
                                          String title = data['title'] ?? '';
                                          String imageUrl = data['imageUrl'] ?? '';
                                          String videoUrl = data['videoUrl'] ?? data['videoLink'] ?? '';

                                          return InkWell(
                                            onTap: () => _playVideoInsideModal(context, videoUrl, title),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(color: Colors.grey.shade200),
                                              ),
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Stack(
                                                      alignment: Alignment.center,
                                                      children: [
                                                        ClipRRect(
                                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                                          child: imageUrl.isNotEmpty
                                                              ? Image.network(imageUrl, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200))
                                                              : Container(color: Colors.grey.shade200),
                                                        ),
                                                        Container(
                                                          padding: const EdgeInsets.all(8),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFB71C1C).withOpacity(0.85),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Icon(Icons.play_arrow, color: Colors.white, size: 24),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding: const EdgeInsets.all(8.0),
                                                    child: Text(
                                                      title,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // ----------------------------------------------------

                        const SizedBox(height: 24),
                        const MatchesAndSectionsBody(),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              // البانر الأسود الرفيع الأنيق تحت خالص في الصفحة الرئيسية
              Container(
                width: double.infinity,
                color: const Color(0xFF1A1A1A),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'جميع الحقوق محفوظة لموقع أسرار الرياضة 2026',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Text(
                      'asrarelriyada@gmail.com',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'دخول الإدارة',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}