import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

class NewsDetailPage extends StatelessWidget {
  final dynamic post;

  const NewsDetailPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    String title = post['title']['rendered'] ?? 'No Title';
    String content = post['content']['rendered'] ?? 'No content';
    String date = post['date'] ?? '';
    if (date.isNotEmpty) {
      date = DateTime.parse(date).toLocal().toString().split(' ')[0];
    }

    String imageUrl = '';
    if (post['_embedded'] != null &&
        post['_embedded']['wp:featuredmedia'] != null &&
        post['_embedded']['wp:featuredmedia'].isNotEmpty) {
      imageUrl = post['_embedded']['wp:featuredmedia'][0]['source_url'] ?? '';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'News Detail',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrl,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.image,
                      size: 50,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Html(
              data: content,
              style: {
                'p': Style(
                  fontSize: FontSize(16),
                  lineHeight: LineHeight(1.6),
                  color: Colors.black87,
                ),
                'h1': Style(
                  fontSize: FontSize(22),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                'h2': Style(
                  fontSize: FontSize(20),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                'h3': Style(
                  fontSize: FontSize(18),
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                'img': Style(
                  width: Width(double.infinity),
                  height: Height.auto(),
                  margin: Margins.symmetric(vertical: 16),
                ),
              },
            ),
          ],
        ),
      ),
    );
  }
}
