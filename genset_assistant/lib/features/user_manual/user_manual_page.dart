import 'package:flutter/material.dart';
import '../ai_chat/ai_chat_page.dart';
import 'package:url_launcher/url_launcher.dart';

class UserManualPage extends StatefulWidget {
  const UserManualPage({super.key});

  @override
  State<UserManualPage> createState() => _UserManualPageState();
}

class _UserManualPageState extends State<UserManualPage> {
  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 20; // Add safe area padding

    final List<Map<String, dynamic>> sections = [
      {
        'title': 'How To Operate A Genset',
        'description': 'Step-by-step guide to start, stop, and operate the genset safely.',
        'icon': Icons.power,
        'pages': [
          {
            "images": ["assets/images/A1.png", "assets/images/A2.png"],
            "text": "🔹 1: Check Engine Oil\n"
                "• Pull Out Dip Stick & Check Oil Level. Ensure level is at the marked area."
          },
          {
            "images": ["assets/images/A3.png"],
            "text": "🔹 2: Check Water Level\n"
                "• Water Level Must be Full at Radiator Cap."
          },
          {
            "images": ["assets/images/A4.png"],
            "text": "🔹 3: Turn On Battery Switch\n"
                "• Rotate The Battery To Turn ON and OFF Battery Before And After Use."
          },
          {
            "images": ["assets/images/A5.png"],
            "text": "🔹 4: Engine Start\n"
                "• Press the “hand button“ and then press green button."
          },
          {
            "images": ["assets/images/A6.png"],
            "text": "🔹 5: Engine Stop\n"
                "• Push the red button once & wait for generator to stop."
          },
        ],
      },
      {
        'title': 'How To Perform Maintenance On The Genset',
        'description': 'Learn how to replace filters, lubricant oil, and check running hours.',
        'icon': Icons.build,
        'pages': [
          {
            "images": ["assets/images/B1.png"],
            "text": "🔹 Replace Air Filter\n"
                "1. Remove safety pin and loosen the nuts.\n"
                "2. Remove the old filter.\n"
                "3. Change it to a new one if used over 600 hours."
          },
          {
            "images": ["assets/images/B2.png"],
            "text": "🔹 Replace Fuel Filter\n"
                "1. Loosen and remove fuel filter by twisting it (usually twisting to the right).\n"
                "2. Fill diesel into filter about ¾ full.\n"
                "3. Install and tighten the filter.\n"
                "4. Change it to a new one if used over 450 hours."
          },
          {
            "images": ["assets/images/B3.png", "assets/images/B4.png"],
            "text": "🔹 Replace Lubricant Oil Filter\n"
                "1. Loosen and remove filter by twisting it (usually to the right).\n"
                "2. Remove oil filter.\n"
                "3. Change it to a new one if used over 450 hours.\n"
                "4. There may be more than 1 lubricant oil filter on certain gensets."
          },
          {
            "images": ["assets/images/B5.png", "assets/images/B6.png"],
            "text": "🔹 Fill in Lubricant Oil Into Engine\n"
                "1. Fill In Lubricant Oil Into The Engine from the engine oil cap.\n"
                "2. Use the Dip Stick to check the level. Stop filling when the oil level is at the correct mark."
          },
          {
            "images": ["assets/images/B7.png"],
            "text": "🔹 Check Genset Running Hours\n"
                "• Press arrow up until running hours appear.\n"
                "• Record down the hours and write it in your maintenance journal."
          },
        ],
      },
      {
        'title': 'General Troubleshooting Guide',
        'description': 'Fix issues like fail to start, shutdown alarms, fuel problems.',
        'icon': Icons.error,
        'pages': [
          {
            "text": "🔹 Generator Fail to Start\n\n"
                "• Weak Battery:\n"
                "- Replace when it cannot hold charge.\n"
                "- Check weekly/monthly for standby use.\n"
                "- Ensure voltage >12V/24V depending on starter.\n"
                "- Correct size: N100 / N150.\n"
                "- Maintain battery water level.\n"
                "- Test charging with multimeter.\n\n"
                "• Out of Fuel / Air Lock:\n"
                "- Engine cranks but won’t start.\n"
                "- Use priming pump to pump diesel.\n"
                "- Release air locks through filters.\n"
                "- Ensure sufficient diesel."
          },
          {
            "text": "🔹 Shutdown Due to Alarm\n\n"
                "• Low Lubricant Oil Alarm:\n"
                "- Check oil daily and keep at FULL mark.\n"
                "- Add engine oil if level is low.\n\n"
                "• High Temperature Alarm:\n"
                "- Alarm if engine >95°C.\n"
                "- Check coolant in radiator spare tank.\n"
                "- ⚠️ Never open radiator cap when hot!\n"
                "- Blocked heater hoses can cause overheating."
          },
          {
            "text": "🔹 Emergency Stop\n\n"
                "- Engine will not start if emergency stop button is pressed.\n"
                "- Ensure button is released.\n"
                "- Press STOP button again to reset the alarm.\n\n"
                "⚠️ WARNING ALARM ICONS\n\n"
                "Warnings are non-critical alarm conditions and do not affect the operation "
                "of the generator system; they serve to draw the operators attention to an undesirable condition.\n\n"
                "By default, warning alarms are self-resetting when the fault condition is removed. "
                "However enabling *all warnings are latched* causes warning alarms to latch until reset manually. "
                "This is enabled using the DSE Configuration Suite in conjunction with a compatible PC.",
          },
          {
            "images": ["assets/images/C1.png"],
          },
          {
            "images": ["assets/images/C2.png"],
          },
        ],
      },
      {
        'title': 'AI Chatbot Assistant',
        'description': 'Get instant help from our AI-powered chatbot for generator questions.',
        'icon': Icons.chat,
        'isDirectNavigation': true,
        'navigationType': 'chatbot',
      },
      {
        'title': 'WhatsApp Support',
        'description': 'Connect directly with our support team via WhatsApp.',
        'icon': Icons.message,
        'isDirectNavigation': true,
        'navigationType': 'whatsapp',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Manual'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 12),
          const Text(
            'GENSET MANUAL GUIDE',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: Icon(
                  section['icon'] as IconData,
                  size: 40,
                  color: Colors.blue,
                ),
                title: Text(
                  section['title'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(section['description'] as String),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () async {
                  final section = sections[index];
                  final isDirectNavigation = section['isDirectNavigation'] as bool? ?? false;

                  if (isDirectNavigation) {
                    final navigationType = section['navigationType'] as String?;
                    if (navigationType == 'chatbot') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AiChatPage()),
                      );
                    } else if (navigationType == 'whatsapp') {
                      await _launchWhatsApp();
                    }
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LearnDetailPage(
                          sections: sections,
                          currentSectionIndex: index,
                        ),
                      ),
                    );
                  }
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _launchWhatsApp() async {
    const phoneNumber = '+60129689816';
    const message = 'Hello from Genset Assistant';

    // Try WhatsApp web URL first (works on mobile browsers)
    final webUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';

    // Try WhatsApp app URL (works if WhatsApp is installed)
    final appUrl = 'whatsapp://send?phone=$phoneNumber&text=${Uri.encodeComponent(message)}';

    try {
      // First try the web URL
      final webUri = Uri.parse(webUrl);
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }

      // Fallback to app URL
      final appUri = Uri.parse(appUrl);
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
        return;
      }

      // If neither works, show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed or cannot be opened'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Handle any errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening WhatsApp: $e'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// ---------- LearnDetailPage ----------
class LearnDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> sections;
  final int currentSectionIndex;

  const LearnDetailPage({
    super.key,
    required this.sections,
    required this.currentSectionIndex,
  });

  @override
  State<LearnDetailPage> createState() => _LearnDetailPageState();
}

class _LearnDetailPageState extends State<LearnDetailPage> {
  late final PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    _pageController = PageController();
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDots(int count, int activeIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 12 : 8,
          height: isActive ? 12 : 8,
          decoration: BoxDecoration(
            color: isActive ? Colors.blue : Colors.grey[300],
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = widget.sections[widget.currentSectionIndex]['pages']
    as List<Map<String, dynamic>>;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom + 20; // Add safe area padding

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sections[widget.currentSectionIndex]['title'] as String,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pages.isNotEmpty
          ? Padding(
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final page = pages[index];
                final images =
                    (page["images"] as List?)?.cast<String>() ?? [];
                final text = page["text"] as String? ?? "";

                // ✅ Special zoomable C1/C2 images
                if (images.contains("assets/images/C1.png") ||
                    images.contains("assets/images/C2.png")) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1,
                      maxScale: 3,
                      child: Image.asset(
                        images.first,
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    ),
                  );
                }

                // Normal image pages
                if (images.isNotEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ListView(
                            children: images.map((imgPath) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.asset(
                                    imgPath,
                                    height: 280,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          text,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Pure text pages
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          _buildDots(pages.length, _currentIndex),
          const SizedBox(height: 8),
          Text(
            "Page ${_currentIndex + 1} of ${pages.length}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: _currentIndex > 0
                    ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                )
                    : null,
                child: const Text('Previous'),
              ),
              ElevatedButton(
                onPressed: _currentIndex < pages.length - 1
                    ? () => _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                )
                    : null,
                child: const Text('Next'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
          )
          : const Center(child: Text("No content available")),
    );
  }
}
