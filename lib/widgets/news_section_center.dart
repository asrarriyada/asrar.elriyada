import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main_news_slider.dart';
import 'app_header.dart';
import 'breaking_news_ticker.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../screens/direct_article_screen.dart';

class NewsSectionCenter extends StatefulWidget {
  const NewsSectionCenter({super.key});

  @override
  State<NewsSectionCenter> createState() => _NewsSectionCenterState();
}

class _NewsSectionCenterState extends State<NewsSectionCenter> {
  void _openNewsDetails(BuildContext context, Map<String, dynamic> newsData, String docId) {
    final title = newsData['title'] ?? '';
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DirectArticleScreen(
          articleTitle: title,
          documentId: docId, // تمرير المعرف الفريد لفتح الخبر الصحيح بدقة
        ),
      ),
    );
  }

  Widget _buildSubNewsItem(BuildContext context, DocumentSnapshot doc, bool isMobile) {
    final newsData = doc.data() as Map<String, dynamic>;
    final docId = doc.id;

    return InkWell(
      onTap: () => _openNewsDetails(context, newsData, docId),
      child: Container(
        height: isMobile ? 85 : null,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              child: SizedBox(
                width: isMobile ? 110 : 100,
                height: double.infinity,
                child: _buildNewsImage(newsData['imageUrl'] ?? newsData['image']),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      newsData['category'] ?? 'أخبار',
                      style: const TextStyle(fontSize: 10, color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      newsData['title'] ?? 'بدون عنوان',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 11.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = MediaQuery.of(context).size.width < 900;

    var query = FirebaseFirestore.instance
        .collection('news')
        .orderBy('createdAt', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('خطأ في الاتصال: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'لا توجد أخبار منشورة حالياً في قاعدة البيانات.',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          );
        }

        final newsDocs = snapshot.data!.docs;
        
        final sliderNewsList = newsDocs.take(10).map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          data['id'] = doc.id; // دمج الـ ID مع بيانات السلايدر لضمان دقة النقر
          return data;
        }).toList();

        final subNews = newsDocs.skip(1).take(4).toList();
        final titlesList = newsDocs.map((doc) => (doc.data() as Map<String, dynamic>)['title'] ?? '').toList().cast<String>();

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              BreakingNewsTicker(titles: titlesList),
              const SizedBox(height: 10),
              isMobile
                  ? Column(
                      children: [
                        SizedBox(
                          height: 240,
                          child: MainNewsSlider(
                            sliderNewsList: sliderNewsList,
                            onNewsTap: (context, newsData) {
                              _openNewsDetails(context, newsData, newsData['id'] ?? '');
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...subNews.map((doc) => _buildSubNewsItem(context, doc, isMobile)),
                      ],
                    )
                  : Container(
                      height: 364,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: subNews.map((doc) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 4.0),
                                    child: _buildSubNewsItem(context, doc, isMobile),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              height: 364,
                              child: MainNewsSlider(
                                sliderNewsList: sliderNewsList,
                                onNewsTap: (context, newsData) {
                                  _openNewsDetails(context, newsData, newsData['id'] ?? '');
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }

  // دالة عرض الصور السليمة تماماً والتي كانت تعمل سابقاً
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