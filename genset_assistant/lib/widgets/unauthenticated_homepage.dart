import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import '../features/auth/login_page.dart';
import 'news_detail_page.dart';

class UnauthenticatedHomepage extends StatefulWidget {
  const UnauthenticatedHomepage({super.key});

  @override
  State<UnauthenticatedHomepage> createState() => _UnauthenticatedHomepageState();
}

class _UnauthenticatedHomepageState extends State<UnauthenticatedHomepage> with AutomaticKeepAliveClientMixin {
  List<dynamic> posts = [];
  bool isLoading = true;
  String errorMessage = '';
  late VideoPlayerController _videoController;
  bool _isVideoInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    fetchPosts();
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  void _initializeVideo() async {
    try {
      _videoController = VideoPlayerController.asset('assets/video.mp4');
      await _videoController.initialize();
      setState(() {
        _isVideoInitialized = true;
      });
      // Set video to loop
      _videoController.setLooping(true);
      // Auto-start video playback
      _videoController.play();
    } catch (e) {
      print('Error initializing video: $e');
    }
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(
          'https://genset.com.my/wp-json/wp/v2/posts?_embed&per_page=5'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            posts = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load news: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading news: $e';
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewPadding.bottom + 200,
              left: 0,
              right: 0,
              top: 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Section with Video
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/Genset App Logo.png',
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.flash_on,
                                  color: Color(0xFF1E3A8A),
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Genset Assistant',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Welcome! Discover our premium generator solutions',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Video Section
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _isVideoInitialized
                              ? Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    VideoPlayer(_videoController),
                                    // Play/Pause overlay
                                    GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _videoController.value.isPlaying
                                              ? _videoController.pause()
                                              : _videoController.play();
                                        });
                                      },
                                      child: Container(
                                        color: Colors.transparent,
                                        child: Icon(
                                          _videoController.value.isPlaying
                                              ? Icons.pause_circle_filled
                                              : Icons.play_circle_filled,
                                          color: Colors.white.withOpacity(0.8),
                                          size: 64,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.play_circle_filled,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        'Loading video...',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF14B8A6), Color(0xFF1E3A8A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const LoginPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.login, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Get Started',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Company Description Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF0F766E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Genset Rental & Sales Malaysia',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'We sell and rent power generators to homes, business premises, farms, factories, resort and construction sites.\n\nWe had been in the business for over 11 years where our company started in 2014. Our flagship MGM Generator brand had evolved from Mark 1 to over Mark 15 over the years as seen in our Online Shop. Whether you need a Backup Generator, or a full running one for your premise, our friendly staff will be more than happy to advise you whole heartedly. We also carry other brands such as Cummins, Caterpillar, Perkins, Volvo and MTU. We occasionally will offer flash sale offers to our treasured subscribers, therefore be sure to subscribe below.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Three Column Services Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Our Services',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 600) {
                            // Large screen: horizontal layout
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildServiceColumn(
                                    context,
                                    'Home Generators',
                                    Icons.home,
                                    'It is now time to be self sufficient. Get a backup genset now to be ready in case of power failures. It\'s a worthwhile investment.',
                                    Colors.blue.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildServiceColumn(
                                    context,
                                    'Industrial Generators',
                                    Icons.factory,
                                    'Do you face insufficient power supply issues? Do you also need backup power? If you answer yes to any of these two questions, get a Genset now!',
                                    Colors.orange.shade600,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildServiceColumn(
                                    context,
                                    'Healthcare Industry',
                                    Icons.local_hospital,
                                    'Hospitals, Clinics and Labs absolutely need backup power. Gensets can save lives. Call us now to let us consult you for FREE.',
                                    Colors.red.shade600,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            // Mobile screen: vertical layout
                            return Column(
                              children: [
                                _buildServiceColumn(
                                  context,
                                  'Home Generators',
                                  Icons.home,
                                  'It is now time to be self sufficient. Get a backup genset now to be ready in case of power failures. It\'s a worthwhile investment.',
                                  Colors.blue.shade600,
                                ),
                                const SizedBox(height: 16),
                                _buildServiceColumn(
                                  context,
                                  'Industrial Generators',
                                  Icons.factory,
                                  'Do you face insufficient power supply issues? Do you also need backup power? If you answer yes to any of these two questions, get a Genset now!',
                                  Colors.orange.shade600,
                                ),
                                const SizedBox(height: 16),
                                _buildServiceColumn(
                                  context,
                                  'Healthcare Industry',
                                  Icons.local_hospital,
                                  'Hospitals, Clinics and Labs absolutely need backup power. Gensets can save lives. Call us now to let us consult you for FREE.',
                                  Colors.red.shade600,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Latest News Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Latest News',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (isLoading) const Center(child: CircularProgressIndicator()),
                      if (errorMessage.isNotEmpty)
                        Center(
                          child: Text(
                            errorMessage,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      if (posts.isEmpty && !isLoading && errorMessage.isEmpty)
                        const Center(child: Text('No news available')),
                      if (!isLoading && errorMessage.isEmpty && posts.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return _buildNewsItem(posts[index]);
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNewsItem(dynamic post) {
    String title = post['title']['rendered'] ?? 'No Title';
    String excerpt = post['excerpt']['rendered'] ?? '';
    excerpt = excerpt.replaceAll(RegExp(r'<[^>]*>'), '').trim();
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

    return LayoutBuilder(
      builder: (context, constraints) {
        double cardWidth = constraints.maxWidth > 600 ? 320 : 280;
        double imageHeight = constraints.maxWidth > 600 ? 120 : 100;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NewsDetailPage(post: post)),
            );
          },
          child: SizedBox(
            width: cardWidth,
            height: constraints.maxWidth > 600 ? 240 : 200,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      child: Image.network(
                        imageUrl,
                        height: imageHeight,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                        const SizedBox.shrink(),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFFFFF),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: Text(
                              excerpt,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFFB3B3B3),
                                height: 1.4,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB3B3B3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildServiceColumn(BuildContext context, String title, IconData icon, String description, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: color,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
