import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../widgets/app_header.dart';

class ClubDetailsScreen extends StatelessWidget {
  const ClubDetailsScreen({super.key, required this.clubId});
  final String clubId;

  // دالة ذكية لإرجاع مسار الشعار واسم النادي بناءً على الـ clubId لو لسه ممتلاش في فايربيز
  Map<String, String> _getDefaultTeamInfo() {
    switch (clubId) {
      case 'egypt_football_association':
        return {'name': 'الاتحاد المصري لكرة القدم', 'logo': 'assets/images/teams/egypt-national.png'};
      case 'abu_qir':
        return {'name': 'أبو قير للأسمدة', 'logo': 'assets/images/teams/abu_qir.png'};
      case 'al_ittihad':
        return {'name': 'الاتحاد السكندري', 'logo': 'assets/images/teams/al_ittihad.png'};
      case 'al_ahly':
        return {'name': 'الأهلي', 'logo': 'assets/images/teams/al-ahly.png'};
      case 'zamalek':
        return {'name': 'الزمالك', 'logo': 'assets/images/teams/zamalek_sc.png'};
      default:
        return {'name': clubId, 'logo': 'assets/images/teams/egypt-national.png'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultInfo = _getDefaultTeamInfo();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('clubs').doc(clubId).get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const AppHeader(),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                    ),
                  ),
                ],
              );
            }

            final bool hasData = snapshot.hasData && snapshot.data!.exists;
            var data = hasData ? (snapshot.data!.data() as Map<String, dynamic>) : {};

            // لو الاسم متخزن في فايربيز يظهر، لو مفيش ياخد الاسم الافتراضي من القائمة
            String displayName = data['clubName'] ?? defaultInfo['name']!;
            String clubLogo = defaultInfo['logo']!;
            String foundingYear = data['foundingYear'] ?? 'قريباً بالداشبورد';
            String president = data['president'] ?? 'قريباً بالداشبورد';
            String description = data['description'] ?? 'سيتم إضافة النبذة التاريخية والتفاصيل الخاصة بهذا النادي قريباً من لوحة التحكم (الداشبورد).';
            
            var achievementsRaw = data['achievements'];
            List<String> achievements = [];
            if (achievementsRaw is List) {
              achievements = List<String>.from(achievementsRaw);
            } else if (achievementsRaw is String && achievementsRaw.isNotEmpty) {
              achievements = achievementsRaw.split(',').map((e) => e.trim()).toList();
            }

            List playersImages = data['playersImages'] ?? [];

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. هيدر الموقع الرئيسي
                  const AppHeader(),

                  // 2. زر العودة للرئيسية
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                    child: TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_forward, color: Color(0xFFB71C1C)),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        alignment: Alignment.centerRight,
                      ),
                      label: const Text(
                        'العودة للرئيسية',
                        style: TextStyle(color: Color(0xFFB71C1C), fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // 3. المحتوى الأساسي
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFB71C1C), width: 2),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: Image.asset(
                                  clubLogo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.shield, color: Color(0xFFB71C1C), size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    displayName,
                                    style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'سنة التأسيس: $foundingYear  |  الرئيس: $president',
                                    style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 40),

                        const Text(
                          'النبذة التعريفية والتاريخية',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          description,
                          style: const TextStyle(fontSize: 16, height: 1.7, color: Colors.black87),
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          'أهم الإنجازات والبطولات',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                        ),
                        const SizedBox(height: 12),
                        achievements.isEmpty
                            ? Text('سيتم إضافة إنجازات وبطولات النادي عبر الداشبورد قريباً.', style: TextStyle(color: Colors.grey.shade600))
                            : Column(
                                children: achievements.map((ach) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.emoji_events, color: Colors.amber, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(child: Text(ach, style: const TextStyle(fontSize: 16, height: 1.4))),
                                    ],
                                  ),
                                )).toList(),
                              ),
                        const SizedBox(height: 30),

                        const Text(
                          'صور أشهر مشاهير ونجوم النادي',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                        ),
                        const SizedBox(height: 14),
                        playersImages.isEmpty
                            ? Text('جاري إعداد صور نجوم النادي لإضافتها من الداشبورد...', style: TextStyle(color: Colors.grey.shade600))
                            : SizedBox(
                                height: 190,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: playersImages.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      margin: const EdgeInsets.only(left: 12),
                                      width: 230,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: Colors.grey.shade300),
                                        image: DecorationImage(
                                          image: NetworkImage(playersImages[index]),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}