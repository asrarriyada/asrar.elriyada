import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../match_details_screen.dart';

class MatchesTickerWidget extends StatefulWidget {
  final String selectedDayKey;

  const MatchesTickerWidget({super.key, this.selectedDayKey = 'today'});

  @override
  State<MatchesTickerWidget> createState() => _MatchesTickerWidgetState();
}

class _MatchesTickerWidgetState extends State<MatchesTickerWidget> {
  final ScrollController _scrollController = ScrollController();

  String _getTargetDateString() {
    DateTime now = DateTime.now();
    DateTime targetDate;

    if (widget.selectedDayKey == 'yesterday') {
      targetDate = now.subtract(const Duration(days: 1));
    } else if (widget.selectedDayKey == 'tomorrow') {
      targetDate = now.add(const Duration(days: 1));
    } else {
      targetDate = now;
    }

    String year = targetDate.year.toString();
    String month = targetDate.month.toString().padLeft(2, '0');
    String day = targetDate.day.toString().padLeft(2, '0');

    return '$year-$month-$day';
  }

  void _scroll(bool toRight) {
    double offset = toRight ? 300.0 : -300.0;
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.offset + offset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  String _formatStartTime(dynamic startTimeField) {
    if (startTimeField == null) return '';
    try {
      if (startTimeField is Timestamp) {
        DateTime dt = startTimeField.toDate();
        int hour = dt.hour;
        String period = 'ص';
        if (hour >= 12) {
          period = 'م';
          if (hour > 12) hour -= 12;
        }
        if (hour == 0) hour = 12;
        String minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute $period';
      }
      return startTimeField.toString();
    } catch (e) {
      return '';
    }
  }

  String _getArabicStatus(Map<String, dynamic> matchData) {
    final rawStatus = matchData['status'];
    final startTimeField = matchData['startTime'];
    String timeFormatted = _formatStartTime(startTimeField);

    if (rawStatus == null) {
      return timeFormatted.isNotEmpty ? timeFormatted : 'قريباً';
    }

    String status = rawStatus.toString().toLowerCase();

    if (status.contains('قادم') || status == 'ns' || status == 'tbd' || status.isEmpty) {
      return timeFormatted.isNotEmpty ? timeFormatted : rawStatus.toString();
    }
    
    if (status.contains('جارية') || status == '1h' || status == '2h' || status == 'et' || status == 'p' || status.contains('live')) {
      return 'جارية الان';
    }
    
    if (status.contains('استراحة') || status == 'ht') {
      return 'استراحة';
    }
    
    if (status.contains('انتهت') || status == 'ft' || status == 'aet' || status == 'pen') {
      return 'انتهت';
    }

    return timeFormatted.isNotEmpty ? timeFormatted : rawStatus.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String targetDateQuery = _getTargetDateString();

    return Container(
      width: double.infinity,
      color: Colors.black87,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 6 : 10,
        horizontal: isMobile ? 8 : 16,
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            IconButton(
              onPressed: () => _scroll(false),
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.amber, size: 18),
            ),
            Expanded(
              child: SizedBox(
                height: isMobile ? 85 : 75,
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .where('date', isEqualTo: targetDateQuery)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.amber, strokeWidth: 2),
                        ),
                      );
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          'لا توجد مباريات مسجلة',
                          style: TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      );
                    }

                    final docs = List.from(snapshot.data!.docs);
                    
                    // الترتيب الزمني الصحيح: الأبكر أولاً (تصاعدياً)
                    docs.sort((a, b) {
                      final timeA = (a.data() as Map<String, dynamic>)['startTime'];
                      final timeB = (b.data() as Map<String, dynamic>)['startTime'];
                      
                      if (timeA == null && timeB == null) return 0;
                      if (timeA == null) return 1;
                      if (timeB == null) return -1;

                      if (timeA is Timestamp && timeB is Timestamp) {
                        return timeA.compareTo(timeB);
                      }
                      return 0;
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      reverse: false, // اتجاه طبيعي بدون عكس
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        return Padding(
                          padding: EdgeInsets.only(left: isMobile ? 8.0 : 12.0),
                          child: _buildMatchCard(
                            context: context,
                            matchData: data,
                            isMobile: isMobile,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
            IconButton(
              onPressed: () => _scroll(true),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.amber, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard({
    required BuildContext context,
    required Map<String, dynamic> matchData,
    required bool isMobile,
  }) {
    final tournament = matchData['league'] ?? 'بطولة';
    final team1 = matchData['teamA'] ?? 'الفريق الأول';
    final team2 = matchData['teamB'] ?? 'الفريق الثاني';
    final score1 = matchData['scoreA'] ?? '0';
    final score2 = matchData['scoreB'] ?? '0';

    String displayStatus = _getArabicStatus(matchData);
    bool isLive = displayStatus == 'جارية الان';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchDetailsScreen(matchData: matchData),
          ),
        );
      },
      child: Container(
        width: isMobile ? 190 : 230,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade800),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              tournament,
              style: TextStyle(color: Colors.amber, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    team1,
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 12),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red[800],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$score1 - $score2',
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 10 : 11, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: Text(
                    team2,
                    style: TextStyle(color: Colors.white, fontSize: isMobile ? 11 : 12),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              displayStatus,
              style: TextStyle(
                color: isLive ? Colors.greenAccent : Colors.grey,
                fontSize: isMobile ? 9 : 10,
                fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}