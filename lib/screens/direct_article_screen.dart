import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import '../home_screen.dart';
import '../widgets/app_header.dart';
import '../widgets/social_share_buttons.dart';

class DirectArticleScreen extends StatefulWidget {
  final String articleTitle;

  const DirectArticleScreen({super.key, required this.articleTitle});

  @override
  State<DirectArticleScreen> createState() => _DirectArticleScreenState();
}

class _DirectArticleScreenState extends State<DirectArticleScreen> {
  String? _extractedId;
  String? _extractedTitleParam;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          final uri = Uri.parse(html.window.location.href);
          final idParam = uri.queryParameters['id'];
          final titleParam = uri.queryParameters['title'];
          
          setState(() {
            if (idParam != null && idParam.isNotEmpty) {
              _extractedId = idParam;
            }
            if (titleParam != null && titleParam.isNotEmpty) {
              _extractedTitleParam = Uri.decodeComponent(titleParam);
            }
          });
        } catch (_) {}
      });
    }
  }

  void _navigateToHome(BuildContext context) {
    if (kIsWeb) {
      try {
        final basePath = html.window.location.href.split('?').first;
        html.window.history.pushState(null, '', basePath);
      } catch (_) {}
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    var query = FirebaseFirestore.instance.collection('news');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: FutureBuilder<QuerySnapshot>(
          future: query.get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildErrorView(context);
            }

            var docs = snapshot.data!.docs;
            QueryDocumentSnapshot? matchedDoc;

            // البحث الذكي الآمن تماماً لضمان جلب المقال دون أي أخطاء
            try {
              if (_extractedId != null && _extractedId!.isNotEmpty) {
                matchedDoc = docs.firstWhere(
                  (doc) => doc.id == _extractedId || (doc.data() as Map<String, dynamic>)['newsId'] == _extractedId,
                  orElse: () => docs.first,
                );
              } else if (_extractedTitleParam != null && _extractedTitleParam!.isNotEmpty) {
                final targetTitle = _extractedTitleParam!.replaceAll('"', '').replaceAll("'", "").trim();
                matchedDoc = docs.firstWhere(
                  (doc) => (doc.data() as Map<String, dynamic>)['title'].toString().contains(targetTitle),
                  orElse: () => docs.first,
                );
              } else if (widget.articleTitle.isNotEmpty) {
                final targetTitle = widget.articleTitle.replaceAll('"', '').replaceAll("'", "").trim();
                matchedDoc = docs.firstWhere(
                  (doc) => (doc.data() as Map<String, dynamic>)['title'].toString().contains(targetTitle),
                  orElse: () => docs.first,
                );
              } else {
                matchedDoc = docs.first;
              }
            } catch (_) {
              matchedDoc = docs.first;
            }

            final newsData = matchedDoc.data() as Map<String, dynamic>;
            final actualTitle = newsData['title'] ?? '';

            if (actualTitle.isEmpty) {
              return _buildErrorView(context);
            }

            if (kIsWeb) {
              try {
                final docId = matchedDoc.id;
                final currentHref = html.window.location.href;
                if (!currentHref.contains('id=$docId') && !currentHref.contains('title=')) {
                  final basePath = currentHref.split('?').first;
                  html.window.history.pushState(null, '', '$basePath?id=$docId');
                }
              } catch (_) {}
            }

            final String currentShareUrl = kIsWeb ? html.window.location.href : 'https://asrarriyada.github.io/asrar.elriyada/';

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppHeader(),
                  const SizedBox(height: 24),
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () => _navigateToHome(context),
                                icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFB71C1C)),
                                label: const Text(
                                  'الرئيسية',
                                  style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(28),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.03),
                                    blurRadius: 6,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFB71C1C).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      newsData['category'] ?? 'أخبار عامة',
                                      style: const TextStyle(
                                        color: Color(0xFFB71C1C),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    actualTitle,
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      height: 1.4,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(Icons.person, size: 16, color: Color(0xFFB71C1C)),
                                          const SizedBox(width: 6),
                                          Text(
                                            'الكاتب: ${newsData['author'] ?? 'أسرار الرياضة'}',
                                            style: const TextStyle(
                                              color: Color(0xFFB71C1C),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        newsData['dateTime'] ?? '',
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 32),
                                  if (newsData['imageUrl'] != null || newsData['image'] != null)
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: SizedBox(
                                          width: double.infinity,
                                          child: _buildNewsImage(newsData['imageUrl'] ?? newsData['image']),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 28),
                                  Text(
                                    newsData['content'] ?? newsData['description'] ?? 'لا يوجد محتوى تفصيلي مضاف لهذا الخبر حتى الآن.',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      height: 1.9,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 35),
                                  SocialShareButtons(
                                    newsTitle: actualTitle,
                                    newsUrl: currentShareUrl,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'عذراً، لم يتم العثور على هذا المقال أو تم حذفه.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
            ),
            onPressed: () => _navigateToHome(context),
            child: const Text('العودة للرئيسية'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewsImage(dynamic img) {
    String url = (img ?? '').toString().trim();
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.split(',').last;
        final bytes = base64Decode(base64Str);
        return Image.memory(
          bytes,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _errorImagePlaceholder(),
        );
      } catch (_) {}
    }
    if (url.isNotEmpty && url.startsWith('http')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _errorImagePlaceholder(),
      );
    }
    return _errorImagePlaceholder();
  }

  Widget _errorImagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(Icons.image, color: Color(0xFFB71C1C), size: 30),
    );
  }
}