import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/app_header.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class CategoryNewsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryNewsScreen({super.key, required this.categoryName});

  // دالة موحدة لفتح تفاصيل الخبر وتحديث رابط الـ URL لحظياً في الويب
  void _openNewsDetails(BuildContext context, Map<String, dynamic> newsData) {
    final title = newsData['title'] ?? '';

    if (kIsWeb) {
      try {
        final encodedTitle = Uri.encodeComponent(title);
        html.window.history.pushState(null, '', '?title=$encodedTitle');
      } catch (_) {}
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            body: SingleChildScrollView(
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
                                onPressed: () {
                                  // عند العودة، نمسح الباراميتر من الـ URL ليعود لرابط القسم أو الرئيسية
                                  if (kIsWeb) {
                                    try {
                                      html.window.history.pushState(null, '', '');
                                    } catch (_) {}
                                  }
                                  Navigator.pop(context);
                                },
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
                                      style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    newsData['title'] ?? 'بدون عنوان',
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
                                            style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.w600, fontSize: 13),
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
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F9),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppHeader(),
              const SizedBox(height: 24),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1050),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFB71C1C)),
                            label: const Text(
                              'الرئيسية',
                              style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              color: const Color(0xFFB71C1C),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'قسم: $categoryName',
                              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance.collection('news').snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            final docs = snapshot.data!.docs.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final newsCategory = (data['category'] ?? '').toString().trim();
                              return newsCategory == categoryName.trim();
                            }).toList();

                            if (docs.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 40.0),
                                child: Center(
                                  child: Text(
                                    'لا توجد أخبار مضافة حالياً في قسم "$categoryName"',
                                    style: const TextStyle(color: Colors.grey, fontSize: 16),
                                  ),
                                ),
                              );
                            }

                            return Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              children: docs.map((doc) {
                                final news = doc.data() as Map<String, dynamic>;
                                return SizedBox(
                                  width: 320,
                                  height: 180,
                                  child: InkWell(
                                    onTap: () => _openNewsDetails(context, news),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.04),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          _buildNewsImage(news['imageUrl'] ?? news['image']),
                                          Positioned(
                                            bottom: 0,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                  colors: [
                                                    Colors.black.withOpacity(0.85),
                                                    Colors.black.withOpacity(0.4),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                              child: Text(
                                                news['title'] ?? 'بدون عنوان',
                                                style: const TextStyle(
                                                  fontSize: 13.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  height: 1.25,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
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
      child: const Icon(Icons.article, color: Color(0xFFB71C1C), size: 30),
    );
  }
}