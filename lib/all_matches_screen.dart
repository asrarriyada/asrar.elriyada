import 'package:flutter/material.dart';
import 'widgets/app_header.dart';
import 'match_details_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AllMatchesScreen extends StatefulWidget {
  const AllMatchesScreen({super.key});

  @override
  State<AllMatchesScreen> createState() => _AllMatchesScreenState();
}

class _AllMatchesScreenState extends State<AllMatchesScreen> {
  String? _selectedFilterDate; // لو null يعني عرض الجدول الشامل لكل المباريات
  bool _isDateInitialized = false;

  // دالة لجلب اسم اليوم بالعربي بناءً على التاريخ
  String _getDayName(String dateStr) {
    try {
      DateTime dt = DateTime.parse(dateStr);
      List<String> days = ['الأحد', 'الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت'];
      return days[dt.weekday % 7];
    } catch (e) {
      return 'اليوم';
    }
  }

  // دالة لتنسيق وعرض وقت المباراة
  String _formatMatchTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    DateTime dt = timestamp.toDate();
    String hour = dt.hour.toString().padLeft(2, '0');
    String minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // دالة لاختيار تاريخ من التقويم (لتصفح شهر كامل أو أي يوم سابق)
  Future<void> _pickDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_selectedFilterDate != null && _selectedFilterDate!.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_selectedFilterDate!);
      } catch (_) {}
    }

    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB71C1C), // لون الأزرار والهيدر التقويمي
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilterDate = "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 1. الهيدر الأساسي فوق
              const AppHeader(),
              const SizedBox(height: 15),

              // 2. عنوان الصفحة وزر الرجوع
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'جدول مباريات الأسبوع والبطولات',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_forward, color: Colors.black87),
                      tooltip: 'العودة',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 15),

              // 3. شريط أزرار التحكم في التواريخ والتقويم الشامل
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24),
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('matches').snapshots(),
                  builder: (context, snapshot) {
                    List<String> availableDates = [];
                    if (snapshot.hasData) {
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data['date'] != null && !availableDates.contains(data['date'])) {
                          availableDates.add(data['date']);
                        }
                      }
                      availableDates.sort(); // ترتيب الأيام تصاعدياً
                    }

                    // اختيار أول تاريخ افتراضي يحتوي على مباريات إذا لم يتم الاختيار بعد
                    if (!_isDateInitialized && availableDates.isNotEmpty) {
                      String todayStr = "${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}";
                      if (availableDates.contains(todayStr)) {
                        _selectedFilterDate = todayStr;
                      } else {
                        _selectedFilterDate = availableDates.last; 
                      }
                      _isDateInitialized = true;
                    }

                    return Row(
                      children: [
                        // زر اختيار تاريخ مخصص
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFB71C1C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () => _pickDate(context),
                          icon: const Icon(Icons.calendar_month, size: 18),
                          label: Text(_selectedFilterDate == null ? 'اختر تاريخاً' : 'التاريخ: $_selectedFilterDate'),
                        ),
                        const SizedBox(width: 12),
                        // زر عرض الجدول الشامل لكل المباريات
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFB71C1C),
                            side: const BorderSide(color: Color(0xFFB71C1C)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _selectedFilterDate = null; // عرض الكل
                            });
                          },
                          icon: const Icon(Icons.list_alt, size: 18),
                          label: const Text('عرض الجدول الشامل (الكل)'),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // 4. جدول المباريات الحقيقي (DataTable)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _selectedFilterDate == null
                          ? FirebaseFirestore.instance.collection('matches').orderBy('createdAt', descending: true).snapshots()
                          : FirebaseFirestore.instance.collection('matches').where('date', isEqualTo: _selectedFilterDate).snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator(color: Color(0xFFB71C1C)));
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(40),
                            alignment: Alignment.center,
                            child: Text(
                              _selectedFilterDate == null
                                  ? 'لا توجد مباريات مسجلة في النظام.'
                                  : 'لا توجد مباريات مسجلة بتاريخ ($_selectedFilterDate).',
                              style: const TextStyle(fontSize: 15, color: Colors.grey),
                            ),
                          );
                        }

                        final docs = snapshot.data!.docs;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFB71C1C)),
                              headingTextStyle: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              dataRowMaxHeight: 60,
                              columns: const [
                                DataColumn(label: Text('اليوم')),
                                DataColumn(label: Text('التاريخ والوقت')), // تم تعديل العنوان ليوضح احتواء الوقت
                                DataColumn(label: Text('الفريق الأول')),
                                DataColumn(label: Text('النتيجة')),
                                DataColumn(label: Text('الفريق الثاني')),
                                DataColumn(label: Text('البطولة')),
                                DataColumn(label: Text('الحالة / التفاصيل')),
                              ],
                              rows: docs.map((doc) {
                                final data = doc.data() as Map<String, dynamic>;
                                String dateStr = data['date'] ?? '';
                                String dayName = _getDayName(dateStr);
                                String timeStr = _formatMatchTime(data['startTime']);

                                return DataRow(
                                  cells: [
                                    DataCell(Text(dayName, style: const TextStyle(fontWeight: FontWeight.bold))),
                                    // عرض التاريخ وتحته الوقت بشكل منسق دون الإخلال بالشكل
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(dateStr, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                          if (timeStr.isNotEmpty)
                                            Text(
                                              timeStr,
                                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                                            ),
                                        ],
                                      ),
                                    ),
                                    DataCell(Text(data['teamA'] ?? 'الفريق الأول', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade700,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '${data['scoreA'] ?? 0} - ${data['scoreB'] ?? 0}',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(data['teamB'] ?? 'الفريق الثاني', style: const TextStyle(fontWeight: FontWeight.bold))),
                                    DataCell(Text(data['league'] ?? 'بطولة', style: const TextStyle(color: Colors.blueGrey))),
                                    DataCell(
                                      InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MatchDetailsScreen(matchData: data),
                                            ),
                                          );
                                        },
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              data['status'] ?? 'قريباً',
                                              style: const TextStyle(color: Color(0xFFB71C1C), fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}