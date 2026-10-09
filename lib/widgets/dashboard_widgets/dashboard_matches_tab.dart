import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardMatchesTab extends StatefulWidget {
  const DashboardMatchesTab({super.key});

  @override
  State<DashboardMatchesTab> createState() => _DashboardMatchesTabState();
}

class _DashboardMatchesTabState extends State<DashboardMatchesTab> {
  final TextEditingController _customLeagueController = TextEditingController();
  final TextEditingController _teamAController = TextEditingController();
  final TextEditingController _teamBController = TextEditingController();
  final TextEditingController _scoreAController = TextEditingController(text: '0');
  final TextEditingController _scoreBController = TextEditingController(text: '0');

  String _selectedSportType = 'كرة قدم';
  final List<String> _sportTypes = ['كرة قدم', 'كرة يد', 'كرة سلة', 'كرة طائرة', 'ألعاب أخرى'];

  String _selectedMatchStatus = 'جارية الآن';
  final List<String> _matchStatuses = ['اليوم', 'بعد قليل', 'جارية الآن', 'استراحة', 'انتهت', 'مباريات قادمة'];
  DateTime _selectedMatchDateTime = DateTime.now();

  String? _editingMatchId;
  
  // متغير للتحكم في إظهار أو إخفاء المباريات المنتهية (الأرشيف)
  bool _showArchivedMatches = false;

  void _clearForm() {
    _customLeagueController.clear();
    _teamAController.clear();
    _teamBController.clear();
    _scoreAController.text = '0';
    _scoreBController.text = '0';
    setState(() {
      _selectedSportType = 'كرة قدم';
      _selectedMatchStatus = 'جارية الآن';
      _selectedMatchDateTime = DateTime.now();
      _editingMatchId = null;
    });
  }

  void _loadMatchForEditing(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    setState(() {
      _editingMatchId = doc.id;
      _selectedSportType = data['sportType'] ?? 'كرة قدم';
      _customLeagueController.text = data['league'] ?? '';
      _teamAController.text = data['teamA'] ?? '';
      _teamBController.text = data['teamB'] ?? '';
      _scoreAController.text = (data['scoreA'] ?? '0').toString();
      _scoreBController.text = (data['scoreB'] ?? '0').toString();
      _selectedMatchStatus = data['status'] ?? 'جارية الآن';
      
      if (data['startTime'] != null && data['startTime'] is Timestamp) {
        _selectedMatchDateTime = (data['startTime'] as Timestamp).toDate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingMatchId == null ? 'إدارة ونشر المباريات (جميع الألعاب والبطولات) ⚽ 🏀' : 'تعديل بيانات المباراة ✏️',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                ),
                if (_editingMatchId != null)
                  OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.close),
                    label: const Text('إلغاء التعديل'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _editingMatchId == null ? 'إضافة مباراة جديدة (شاملة الألعاب والنتائج والأشواط)' : 'تعديل المباراة الحالية',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFB71C1C)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedSportType,
                    items: _sportTypes.map((sport) {
                      return DropdownMenuItem(value: sport, child: Text(sport));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSportType = val!),
                    decoration: const InputDecoration(labelText: 'نوع الرياضة (قدم، سلة، طائرة، يد)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customLeagueController,
                    decoration: const InputDecoration(
                      labelText: 'اسم البطولة (مثال: الدوري المصري، كأس مصر، دوري السلة...)', 
                      prefixIcon: Icon(Icons.emoji_events, color: Color(0xFFB71C1C)), 
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _selectedMatchStatus,
                    items: _matchStatuses.map((status) {
                      return DropdownMenuItem(value: status, child: Text(status));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedMatchStatus = val!),
                    decoration: const InputDecoration(labelText: 'موقف وحالة المباراة (جارية، استراحة، انتهت...)', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                      alignment: Alignment.centerRight,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    onPressed: () async {
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: _selectedMatchDateTime,
                        firstDate: DateTime(2025),
                        lastDate: DateTime(2030),
                      );
                      if (pickedDate != null) {
                        TimeOfDay? pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_selectedMatchDateTime),
                        );
                        if (pickedTime != null) {
                          setState(() {
                            _selectedMatchDateTime = DateTime(
                              pickedDate.year, pickedDate.month, pickedDate.day,
                              pickedTime.hour, pickedTime.minute,
                            );
                          });
                        }
                      }
                    },
                    icon: const Icon(Icons.calendar_today, color: Color(0xFFB71C1C)),
                    label: Text(
                      'موعد المباراة: ${_selectedMatchDateTime.year}-${_selectedMatchDateTime.month}-${_selectedMatchDateTime.day}    ${_selectedMatchDateTime.hour}:${_selectedMatchDateTime.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: _teamAController, decoration: const InputDecoration(labelText: 'الفريق الأول (يمين)', border: OutlineInputBorder())),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        child: TextField(controller: _scoreAController, decoration: const InputDecoration(labelText: 'النتيجة / الأشواط', border: OutlineInputBorder())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(controller: _teamBController, decoration: const InputDecoration(labelText: 'الفريق الثاني (يسار)', border: OutlineInputBorder())),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 130,
                        child: TextField(controller: _scoreBController, decoration: const InputDecoration(labelText: 'النتيجة / الأشواط', border: OutlineInputBorder())),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFB71C1C), 
                        foregroundColor: Colors.white, 
                      ),
                      onPressed: () async {
                        if (_customLeagueController.text.trim().isEmpty || _teamAController.text.trim().isEmpty || _teamBController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('الرجاء كتابة اسم البطولة والفريقين!'), backgroundColor: Colors.red),
                          );
                          return;
                        }

                        try {
                          Map<String, dynamic> matchData = {
                            'sportType': _selectedSportType,
                            'league': _customLeagueController.text.trim(),
                            'teamA': _teamAController.text.trim(),
                            'teamB': _teamBController.text.trim(),
                            'scoreA': _scoreAController.text.trim(),
                            'scoreB': _scoreBController.text.trim(),
                            'status': _selectedMatchStatus,
                            'startTime': Timestamp.fromDate(_selectedMatchDateTime),
                            'createdAt': FieldValue.serverTimestamp(),
                            'date': "${_selectedMatchDateTime.year}-${_selectedMatchDateTime.month.toString().padLeft(2, '0')}-${_selectedMatchDateTime.day.toString().padLeft(2, '0')}",
                          };

                          if (_editingMatchId == null) {
                            await FirebaseFirestore.instance.collection('matches').add(matchData);
                          } else {
                            await FirebaseFirestore.instance.collection('matches').doc(_editingMatchId).update(matchData);
                          }

                          _clearForm();

                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(_editingMatchId == null ? 'تم نشر المباراة بنجاح! 🏆' : 'تم تعديل المباراة بنجاح! ✅'), backgroundColor: Colors.green),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      child: Text(_editingMatchId == null ? 'نشر المباراة' : 'حفظ التعديلات', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            
            // --- عنوان القائمة وزر إظهار/إخفاء الأرشيف ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('قائمة المباريات المسجلة:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _showArchivedMatches ? Colors.grey.shade700 : Colors.grey.shade200,
                    foregroundColor: _showArchivedMatches ? Colors.white : Colors.black87,
                    elevation: 0,
                  ),
                  onPressed: () {
                    setState(() {
                      _showArchivedMatches = !_showArchivedMatches;
                    });
                  },
                  icon: Icon(_showArchivedMatches ? Icons.visibility_off : Icons.visibility, size: 18),
                  label: Text(_showArchivedMatches ? 'إخفاء المباريات المنتهية' : 'إظهار المباريات المنتهية (الأرشيف)'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('matches').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFFB71C1C)),
                  ));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Text('لا توجد مباريات مضافة حالياً.', style: TextStyle(color: Colors.grey));
                }

                // --- الفلترة بحسب الزر: إذا لم يتم تفعيل عرض الأرشيف، يتم استبعاد المنتهية ---
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  if (!_showArchivedMatches) {
                    return data['status'] != 'انتهت'; // إخفاء المنتهية افتراضياً
                  }
                  return true; // إظهار الكل إذا تم الضغط على زر إظهار الأرشيف
                }).toList();

                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('لا توجد مباريات نشطة حالياً (تم إخفاء المباريات المنتهية).', style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final bool isFinished = data['status'] == 'انتهت';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(
                          color: isFinished ? Colors.grey.shade400 : Colors.grey.shade300,
                        ),
                      ),
                      color: isFinished ? Colors.grey.shade50 : Colors.white, // تمييز المباريات المنتهية بلون خفيف
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        title: Text(
                          '${data['teamA']} (${data['scoreA'] ?? 0})  VS  (${data['scoreB'] ?? 0}) ${data['teamB']}', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold, 
                            fontSize: 15,
                            color: isFinished ? Colors.grey.shade700 : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'البطولة: ${data['league']} | الرياضة: ${data['sportType']} | الحالة: ${data['status']}',
                          style: TextStyle(color: isFinished ? Colors.grey.shade500 : Colors.grey, fontSize: 13),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _loadMatchForEditing(doc),
                              tooltip: 'تعديل',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await FirebaseFirestore.instance.collection('matches').doc(doc.id).delete();
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم حذف المباراة بنجاح'), backgroundColor: Colors.red),
                                );
                              },
                              tooltip: 'حذف',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}