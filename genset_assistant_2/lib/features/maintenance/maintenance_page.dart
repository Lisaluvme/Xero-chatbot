import 'package:flutter/material.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    final sections = [
      {
        'title': 'Daily Checks',
        'description': 'Essential checks to perform every day.',
        'icon': Icons.today,
        'color': Colors.green,
        'pages': [
          {
            "text": "🔹 Check oil levels\nEnsure the oil level is within the marked range."
          },
          {
            "text": "🔹 Inspect fuel system\nCheck for leaks and fuel levels."
          },
          {
            "text": "🔹 Test battery charge\nMake sure the battery voltage is sufficient."
          },
        ]
      },
      {
        'title': 'Weekly Maintenance',
        'description': 'Maintenance tasks for weekly intervals.',
        'icon': Icons.calendar_view_week,
        'color': Colors.blue,
        'pages': [
          {
            "text": "🔹 Clean air filters\nRemove dust and dirt from the filters."
          },
          {
            "text": "🔹 Inspect cooling system\nCheck coolant level and radiator."
          },
        ]
      },
      {
        'title': 'Monthly Service',
        'description': 'Important monthly maintenance procedures.',
        'icon': Icons.calendar_month,
        'color': Colors.orange,
        'pages': [
          {
            "text": "🔹 Inspect electrical connections\nEnsure all wires are secure."
          },
          {
            "text": "🔹 Test emergency stop\nVerify that the emergency stop works correctly."
          },
        ]
      },
      {
        'title': 'Quarterly Inspection',
        'description': 'Comprehensive quarterly inspections.',
        'icon': Icons.calendar_today,
        'color': Colors.purple,
        'pages': [
          {
            "text": "🔹 Full system inspection\nPerform detailed check of all major systems."
          },
        ]
      },
      {
        'title': 'Annual Service',
        'description': 'Complete annual maintenance schedule.',
        'icon': Icons.event,
        'color': Colors.red,
        'pages': [
          {
            "text": "🔹 Replace oil & filters\nDo a complete oil and filter replacement."
          },
          {
            "text": "🔹 Overhaul engine if needed\nCheck wear and schedule overhaul if required."
          },
        ]
      },
      {
        'title': 'Emergency Procedures',
        'description': 'What to do in case of breakdowns.',
        'icon': Icons.warning,
        'color': Colors.red,
        'pages': [
          {
            "text": "⚠️ In case of breakdown:\n1. Stop the generator immediately.\n2. Follow safety shutdown procedure.\n3. Contact maintenance team."
          },
        ]
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Generator Maintenance"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: Container(
                decoration: BoxDecoration(
                  color: (section['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(section['icon'] as IconData, size: 28, color: section['color'] as Color),
              ),
              title: Text(
                section['title'] as String,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(section['description'] as String, style: const TextStyle(fontSize: 14)),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MaintenanceDetailPage(
                      sections: sections,
                      currentSectionIndex: index,
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}

class MaintenanceDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> sections;
  final int currentSectionIndex;

  const MaintenanceDetailPage({
    super.key,
    required this.sections,
    required this.currentSectionIndex,
  });

  @override
  State<MaintenanceDetailPage> createState() => _MaintenanceDetailPageState();
}

class _MaintenanceDetailPageState extends State<MaintenanceDetailPage> {
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
    final pages = widget.sections[widget.currentSectionIndex]['pages'] as List<Map<String, dynamic>>;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sections[widget.currentSectionIndex]['title'] as String),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pages.isNotEmpty
          ? Column(
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
                final text = page["text"] ?? "";

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Text(
                      text,
                      style: const TextStyle(fontSize: 16, height: 1.6),
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
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
          const SizedBox(height: 80), // Added bottom padding to avoid navigation bar overlap
        ],
      )
          : const Center(child: Text("No content available")),
    );
  }
}
