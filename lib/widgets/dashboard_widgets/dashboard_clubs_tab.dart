import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardClubsTab extends StatefulWidget {
  const DashboardClubsTab({super.key});

  @override
  State<DashboardClubsTab> createState() => _DashboardClubsTabState();
}

class _DashboardClubsTabState extends State<DashboardClubsTab> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _foundingYearController = TextEditingController();
  final TextEditingController _presidentController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  
  final List<TextEditingController> _imageControllers = [TextEditingController()];

  bool _isLoading = false;

  void _addImageField() {
    setState(() {
      _imageControllers.add(TextEditingController());
    });
  }

  void _removeImageField(int index) {
    setState(() {
      _imageControllers[index].dispose();
      _imageControllers.removeAt(index);
    });
  }

  Future<void> _saveClubData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      List<String> achievementsList = _achievementsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      List<String> imagesList = _imageControllers
          .map((controller) => controller.text.trim())
          .where((url) => url.isNotEmpty)
          .toList();

      String clubId = _idController.text.trim();

      await FirebaseFirestore.instance.collection('clubs').doc(clubId).set({
        'clubName': _nameController.text.trim(),
        'foundingYear': _foundingYearController.text.trim(),
        'president': _presidentController.text.trim(),
        'description': _descriptionController.text.trim(),
        'achievements': achievementsList,
        'playersImages': imagesList,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حفظ وتحديث تفاصيل النادي وصوره بنجاح!'), backgroundColor: Colors.green),
      );

      _formKey.currentState!.reset();
      _idController.clear();
      _nameController.clear();
      _foundingYearController.clear();
      _presidentController.clear();
      _descriptionController.clear();
      _achievementsController.clear();
      for (var controller in _imageControllers) {
        controller.clear();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء الحفظ: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'إدارة وتحديث بيانات الأندية والاتحادات (التاريخ، الرئاسة، والإنجازات)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
            ),
            const SizedBox(height: 8),
            const Text(
              'أدخل المعرف الإنجليزي بدقة (مثل: abu_qir أو al_ahly أو egypt_football_association) لتحديث بيانات النادي.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _idController,
              decoration: const InputDecoration(
                labelText: 'معرف النادي بالإنجليزية (Document ID)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال المعرف' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم النادي الكامل (clubName)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.isEmpty ? 'يرجى إدخال اسم النادي' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _foundingYearController,
              decoration: const InputDecoration(
                labelText: 'تاريخ أو سنة التأسيس (foundingYear)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _presidentController,
              decoration: const InputDecoration(
                labelText: 'من تولى الرئاسة / مجلس الإدارة (president)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'النبذة التعريفية والتاريخية (description)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _achievementsController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'أهم الإنجازات والبطولات (افصل بين كل إنجاز بفاصلة ,)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'صور أشهر مشاهير ونجوم النادي (حتى 20 صورة وأكثر)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFB71C1C)),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: _addImageField,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة حقل صورة جديد'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _imageControllers.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageControllers[index],
                          decoration: InputDecoration(
                            labelText: 'رابط الصورة رقم ${index + 1}',
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      if (_imageControllers.length > 1) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeImageField(index),
                          tooltip: 'حذف هذا الحقل',
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB71C1C), foregroundColor: Colors.white),
                onPressed: _isLoading ? null : _saveClubData,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'حفظ ونشر البيانات في فايربيز',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}