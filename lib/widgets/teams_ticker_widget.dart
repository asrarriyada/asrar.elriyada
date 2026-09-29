import 'package:flutter/material.dart';
import '../category_news_screen.dart';

class TeamsTickerWidget extends StatefulWidget {
  const TeamsTickerWidget({super.key});

  @override
  State<TeamsTickerWidget> createState() => _TeamsTickerWidgetState();
}

class _TeamsTickerWidgetState extends State<TeamsTickerWidget> {
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> teams = const [
    {
      'name': 'الاتحاد المصري لكرة القدم',
      'logo': 'assets/images/teams/egypt-national.png'
    },
    {
      'name': 'أبو قير للأسمدة',
      'logo': 'assets/images/teams/abu_qir.png'
    },
    {
      'name': 'الاتحاد السكندري',
      'logo': 'assets/images/teams/al_ittihad.png'
    },
    {
      'name': 'الأهلي',
      'logo': 'assets/images/teams/al-ahly.png'
    },
    {
      'name': 'البنك الأهلي',
      'logo': 'assets/images/teams/national-bank.png'
    },
    {
      'name': 'الجونة',
      'logo': 'assets/images/teams/el-gouna.png'
    },
    {
      'name': 'الزمالك',
      'logo': 'assets/images/teams/zamalek_sc.png'
    },
    {
      'name': 'الشرقية إنبي',
      'logo': 'assets/images/teams/sharkia_enppi.png'
    },
    {
      'name': 'القناة',
      'logo': 'assets/images/teams/el_qanah.png'
    },
    {
      'name': 'المصري',
      'logo': 'assets/images/teams/al-masry.png'
    },
    {
      'name': 'المقاولون العرب',
      'logo': 'assets/images/teams/al_mokawloon.png'
    },
    {
      'name': 'بترول أسيوط',
      'logo': 'assets/images/teams/asyut-petroleum.png'
    },
    {
      'name': 'بيراميدز',
      'logo': 'assets/images/teams/pyramids.png'
    },
    {
      'name': 'سيراميكا كليوباترا',
      'logo': 'assets/images/teams/ceramica_cleopatra.png'
    },
    {
      'name': 'سموحة',
      'logo': 'assets/images/teams/smouha.png'
    },
    {
      'name': 'طلائع الجيش',
      'logo': 'assets/images/teams/talaea-el-gaish.png'
    },
    {
      'name': 'غزل المحلة',
      'logo': 'assets/images/teams/ghazal_el_mahalla.png'
    },
    {
      'name': 'مودرن سبورت',
      'logo': 'assets/images/teams/modern_sport.png'
    },
    {
      'name': 'منتخب السويس بتروجت',
      'logo': 'assets/images/teams/Montakhab_El-Suez_Petrojet.jpg'
    },
    {
      'name': 'وادي دجلة',
      'logo': 'assets/images/teams/wadi-degla.png'
    },
    {
      'name': 'زد',
      'logo': 'assets/images/teams/zed-fc.png'
    },
  ];

  void _scroll(bool right) {
    final double offset = right ? 250 : -250;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey),
              onPressed: () => _scroll(false),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                itemCount: teams.length,
                padding: const EdgeInsets.symmetric(horizontal: 5),
                itemBuilder: (context, index) {
                  final team = teams[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) =>
                                CategoryNewsScreen(categoryName: team['name']!),
                            transitionsBuilder: (context, animation, secondaryAnimation, child) {
                              return child;
                            },
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  team['logo']!,
                                  width: 24,
                                  height: 24,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.sports_soccer, size: 20, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              team['name']!,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey),
              onPressed: () => _scroll(true),
            ),
          ],
        ),
      ),
    );
  }
}