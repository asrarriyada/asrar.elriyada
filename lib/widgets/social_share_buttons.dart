import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart'; // مهم للنسخ

class SocialShareButtons extends StatelessWidget {
  final String newsTitle;
  final String newsUrl;

  const SocialShareButtons({
    super.key,
    required this.newsTitle,
    required this.newsUrl,
  });

  Future<void> _launchShareUrl(BuildContext context, String urlString, String platformName, String fullShareText) async {
    // نسخ الرابط والنص مباشرة للحافظة لضمان عدم ضياعه
    await Clipboard.setData(ClipboardData(text: fullShareText));
    
    // إظهار تنبيه صغير للمستخدم أن الرابط تم نسخه
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ رابط $platformName ونصه الحافظة بنجاح! جاهز للصق.'),
        backgroundColor: const Color(0xFFB71C1C),
        duration: const Duration(seconds: 2),
      ),
    );

    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final String targetUrl = newsUrl.isNotEmpty ? newsUrl : (kIsWeb ? Uri.base.toString() : '');

    final encodedTitle = Uri.encodeComponent(newsTitle);
    final encodedUrl = Uri.encodeComponent(targetUrl);

    final facebookUrl = 'https://www.facebook.com/sharer/sharer.php?u=$encodedUrl';
    final twitterUrl = 'https://twitter.com/intent/tweet?text=$encodedTitle&url=$encodedUrl';
    final whatsappUrl = 'https://api.whatsapp.com/send?text=$encodedTitle%20$encodedUrl';
    final telegramUrl = 'https://t.me/share/url?url=$encodedUrl&text=$encodedTitle';

    final fullShareText = '$newsTitle\n$targetUrl';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'نشر الخبر سريعاً على المنصات:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFFB71C1C),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildShareButton(
                title: 'فيسبوك',
                icon: Icons.facebook,
                color: const Color(0xFF1877F2),
                onTap: () => _launchShareUrl(context, facebookUrl, 'فيسبوك', fullShareText),
              ),
              _buildShareButton(
                title: 'تويتر (X)',
                icon: Icons.close,
                color: Colors.black,
                onTap: () => _launchShareUrl(context, twitterUrl, 'تويتر', fullShareText),
              ),
              _buildShareButton(
                title: 'واتساب',
                icon: Icons.chat,
                color: const Color(0xFF25D366),
                onTap: () => _launchShareUrl(context, whatsappUrl, 'واتساب', fullShareText),
              ),
              _buildShareButton(
                title: 'تليجرام',
                icon: Icons.send,
                color: const Color(0xFF0088cc),
                onTap: () => _launchShareUrl(context, telegramUrl, 'تليجرام', fullShareText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}