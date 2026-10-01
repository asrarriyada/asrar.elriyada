import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/app_header.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

class CategoryNewsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryNewsScreen({super.key, required this.categoryName});

  // دالة لفتح تفاصيل الخبر وتحديث الرابط بشكل مباشر ومطابق للرئيسية
  void _openNewsDetails(BuildContext context, Map<String, dynamic> newsData) {
    final title = newsData['title'] ?? '';

    if (kIsWeb) {
      try {
        final encodedTitle = Uri.encodeComponent(title);
        // توجيه المتصفح للرابط المباشر بنفس هيكل الرئيسية ليقوم main.dart بالتقاطه فوراً
        html.window.location.href = '${html.window.location.origin}${html.window.location.pathname}?title=$encodedTitle';
      } catch (_) {}
    }
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
              // الهيدر الأساسي للموقع باللوجو والأقسام في أعلى صفحة القسم
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
                        // زر العودة للرئيسية جهة اليمين مع إزالة الباراميتر من الرابط
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              if (kIsWeb) {
                                try {
                                  html.window.location.href = '${html.window.location.origin}${html.window.location.pathname}';
                                } catch (_) {}
                              } else {
                                Navigator.pop(context);
                              }
                            },
                            icon: const Icon(Icons.arrow_forward, size: 16, color: Color(0xFFB71C1C)),
                            label: const Text(
                              'الرئيسية',
                              style: TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),

                        // عنوان القسم بشكل أنيق
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

                        // جلب وعرض أخبار القسم في كروت شبكية صغيرة وجميلة
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