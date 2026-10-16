import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'add_news_page.dart';
import 'widgets/dashboard_widgets/dashboard_matches_tab.dart';
import 'widgets/dashboard_widgets/dashboard_social_tab.dart';
import 'widgets/dashboard_videos_tab.dart';
import 'widgets/dashboard_widgets/dashboard_clubs_tab.dart'; // <--- استيراد صفحة إدارة الأندية الجديدة

class DashboardScreen extends StatefulWidget {
  final bool isAdminMaster;
  final String? adminName;

  const DashboardScreen({
    super.key,
    this.isAdminMaster = true,
    this.adminName,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  void _openAddNewsPage() async {
    String author = widget.isAdminMaster ? '' : (widget.adminName ?? '');
    
    final newNewsItem = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddNewsPage(authorName: author),
      ),
    );

    if (newNewsItem != null && newNewsItem is Map<String, dynamic>) {
      try {
        await FirebaseFirestore.instance.collection('news').add({
          'title': newNewsItem['title'],
          'content': newNewsItem['content'],
          'category': newNewsItem['category'],
          'imageUrl': newNewsItem['imageUrl'],
          'image': newNewsItem['image'],
          'inlineImageUrl': newNewsItem['inlineImageUrl'],
          'authorImage': newNewsItem['authorImage'],
          'videoUrl': newNewsItem['videoUrl'],
          'videoLink': newNewsItem['videoLink'],
          'feedbackLink': newNewsItem['feedbackLink'],
          'feedbackTitle': newNewsItem['feedbackTitle'],
          'dateTime': newNewsItem['dateTime'],
          'author': newNewsItem['author'],
          'fontFamily': newNewsItem['fontFamily'],
          'fontSize': newNewsItem['fontSize'],
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر وحفظ المقال/الخبر بنجاح!'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ في الحفظ: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> specialties = [];
    bool fullAccess = widget.isAdminMaster;

    if (!widget.isAdminMaster && widget.adminName != null) {
      var account = AdminStorage.accounts[widget.adminName];
      if (account != null) {
        specialties = account['specialties'] ?? [];
        fullAccess = account['fullAccess'] ?? false;
      }
    }

    List<Widget> pages = [];
    List<NavigationRailDestination> destinations = [];

    // 1. الرئيسية والترحيب
    pages.add(
      SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isAdminMaster 
                  ? 'مرحباً بكِ في لوحة التحكم الرئيسية (Master)' 
                  : 'مرحباً بك، ${widget.adminName}', 
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))
            ),
            const SizedBox(height: 12),
            const Text('نظرة عامة على لوحة تحكم موقع أسرار الرياضة.', style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 24),
            if (widget.isAdminMaster)
              Row(
                children: [
                  _buildStatCard('المشرفين المسجلين', '${AdminStorage.accounts.length}', Icons.people, Colors.orange),
                ],
              ),
          ],
        ),
      ),
    );
    destinations.add(
      const NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('الرئيسية')),
    );

    // التحقق من الصلاحيات
    bool hasArticlePermission = fullAccess || 
        specialties.any((s) => s.contains('مقالات') || s.contains('أخبار') || s.contains('المحلية') || s.contains('العالمية') || s.contains('المحترفون'));
        
    bool hasMatchPermission = fullAccess || 
        specialties.any((s) => s.contains('مباريات') || s.contains('المباريات'));

    // 2. قسم الأخبار والمقالات
    if (hasArticlePermission) {
      pages.add(
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('إدارة الأخبار والمقالات الرياضية', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة مقال أو خبر جديد'),
                    onPressed: _openAddNewsPage,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('news').orderBy('createdAt', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('لا توجد مقالات أو أخبار منشورة حالياً.', style: TextStyle(color: Colors.grey)));
                    }

                    final newsDocs = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: newsDocs.length,
                      itemBuilder: (context, index) {
                        var doc = newsDocs[index];
                        var newsData = doc.data() as Map<String, dynamic>;
                        String title = newsData['title'] ?? 'بدون عنوان';
                        String category = newsData['category'] ?? 'عام';
                        String author = newsData['author'] ?? 'أسرار الرياضة';
                        String dateTime = newsData['dateTime'] ?? '';

                        return Card(
                          elevation: 1,
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                            side: BorderSide(color: Colors.grey.shade200),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                            child: Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Color(0xFFB71C1C),
                                  radius: 18,
                                  child: Icon(Icons.article, color: Colors.white, size: 18),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'التصنيف: $category | الكاتب: $author ${dateTime.isNotEmpty ? "| التاريخ: $dateTime" : ""}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                      tooltip: 'تعديل',
                                      onPressed: () async {
                                        String authorName = widget.isAdminMaster ? '' : (widget.adminName ?? '');
                                        
                                        final updatedNews = await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => AddNewsPage(
                                              authorName: authorName,
                                              existingNews: newsData,
                                            ),
                                          ),
                                        );

                                        if (updatedNews != null && updatedNews is Map<String, dynamic>) {
                                          await FirebaseFirestore.instance.collection('news').doc(doc.id).update({
                                            'title': updatedNews['title'],
                                            'content': updatedNews['content'],
                                            'category': updatedNews['category'],
                                            'imageUrl': updatedNews['imageUrl'],
                                            'image': updatedNews['image'],
                                            'inlineImageUrl': updatedNews['inlineImageUrl'],
                                            'authorImage': updatedNews['authorImage'],
                                            'videoUrl': updatedNews['videoUrl'],
                                            'videoLink': updatedNews['videoLink'],
                                            'feedbackLink': updatedNews['feedbackLink'],
                                            'feedbackTitle': updatedNews['feedbackTitle'],
                                            'dateTime': updatedNews['dateTime'],
                                            'author': updatedNews['author'],
                                            'fontFamily': updatedNews['fontFamily'],
                                            'fontSize': updatedNews['fontSize'],
                                          });

                                          if (!context.mounted) return;
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('تم تعديل وحفظ المقال بنجاح!'), backgroundColor: Colors.green),
                                          );
                                        }
                                      },
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      tooltip: 'حذف',
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('news').doc(doc.id).delete();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
      destinations.add(
        const NavigationRailDestination(icon: Icon(Icons.article), label: Text('الأخبار والمقالات')),
      );
    }

    // 3. قسم المباريات
    if (hasMatchPermission) {
      pages.add(const DashboardMatchesTab());
      destinations.add(
        const NavigationRailDestination(icon: Icon(Icons.sports_soccer), label: Text('المباريات')),
      );
    }

    // 4. قسم الفيديوهات والصور
    pages.add(const DashboardVideosTab());
    destinations.add(
      const NavigationRailDestination(icon: Icon(Icons.video_library), label: Text('فيديوهات وصور')),
    );

    // 5. قسم السوشيال ميديا
    pages.add(const DashboardSocialTab());
    destinations.add(
      const NavigationRailDestination(icon: Icon(Icons.forum), label: Text('السوشيال ميديا')),
    );

    // 6. قسم الأندية والاتحادات الجديد
    pages.add(const DashboardClubsTab());
    destinations.add(
      const NavigationRailDestination(icon: Icon(Icons.shield), label: Text('الأندية')),
    );

    // 7. إدارة المشرفين (للأدمن الرئيسي Master فقط)
    if (widget.isAdminMaster) {
      pages.add(
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إدارة المشرفين والصلاحيات', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C))),
              const SizedBox(height: 20),
              Expanded(
                child: AdminStorage.accounts.isEmpty
                    ? const Center(child: Text('لا توجد طلبات انضمام مشرفين حتى الآن', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: AdminStorage.accounts.keys.length,
                        itemBuilder: (context, index) {
                          String name = AdminStorage.accounts.keys.elementAt(index);
                          var account = AdminStorage.accounts[name]!;
                          List accSpecialties = account['specialties'] ?? [];
                          bool isApproved = account['approved'] ?? false;
                          bool accFullAccess = account['fullAccess'] ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Chip(
                                        label: Text(isApproved ? 'نشط ومفعل' : 'بانتظار الموافقة'),
                                        backgroundColor: isApproved ? Colors.green.shade100 : Colors.orange.shade100,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text('التخصصات: ${accSpecialties.join("، ")}'),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: isApproved ? Colors.red : Colors.green, foregroundColor: Colors.white),
                                        onPressed: () => setState(() => account['approved'] = !isApproved),
                                        child: Text(isApproved ? 'تعطيل الحساب' : 'موافقة وتفعيل'),
                                      ),
                                      const SizedBox(width: 12),
                                      OutlinedButton(
                                        onPressed: () => setState(() => account['fullAccess'] = !accFullAccess),
                                        child: Text(accFullAccess ? 'إلغاء الصلاحيات الكاملة' : 'منح صلاحيات كاملة'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
      destinations.add(
        const NavigationRailDestination(icon: Icon(Icons.people), label: Text('Admins')),
      );
    }

    if (_selectedIndex >= pages.length) {
      _selectedIndex = 0;
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.isAdminMaster ? 'لوحة تحكم أسرار الرياضة (Master)' : 'لوحة تحكم المشرف: ${widget.adminName}'),
          backgroundColor: const Color(0xFFB71C1C),
          actions: [
            IconButton(
              icon: const Icon(Icons.home, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen())),
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen())),
            ),
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) => setState(() => _selectedIndex = index),
              labelType: NavigationRailLabelType.all,
              selectedIconTheme: const IconThemeData(color: Color(0xFFB71C1C)),
              destinations: destinations,
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: pages[_selectedIndex],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: color.withOpacity(0.1), radius: 25, child: Icon(icon, color: color, size: 28)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 4),
                Text(count, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}