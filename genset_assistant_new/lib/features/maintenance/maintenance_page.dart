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
        'color': const Color(0xFF4CAF50),
        'gradient': const [Color(0xFF4CAF50), Color(0xFF66BB6A)],
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
        'color': const Color(0xFF2196F3),
        'gradient': const [Color(0xFF2196F3), Color(0xFF42A5F5)],
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
        'color': const Color(0xFFFF9800),
        'gradient': const [Color(0xFFFF9800), Color(0xFFFFB74D)],
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
        'color': const Color(0xFF9C27B0),
        'gradient': const [Color(0xFF9C27B0), Color(0xFFBA68C8)],
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
        'color': const Color(0xFFF44336),
        'gradient': const [Color(0xFFF44336), Color(0xFFEF5350)],
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
        'icon': Icons.warning_amber,
        'color': const Color(0xFFFF5722),
        'gradient': const [Color(0xFFFF5722), Color(0xFFFF7043)],
        'pages': [
          {
            "text": "⚠️ In case of breakdown:\n1. Stop the generator immediately.\n2. Follow safety shutdown procedure.\n3. Contact maintenance team."
          },
        ]
      },
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 40),
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
                children: [
                  Icon(
                    Icons.settings,
                    size: 48,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Generator Maintenance',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Regular care for optimal performance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Maintenance Sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 100.0),
                children: sections.asMap().entries.map((entry) {
                  final index = entry.key;
                  final section = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: (section['color'] as Color).withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
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
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  section['icon'] as IconData,
                                  size: 28,
                                  color: Theme.of(context).colorScheme.onPrimary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      section['title'] as String,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      section['description'] as String,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Theme.of(context).colorScheme.onSecondary,
                                        height: 1.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Theme.of(context).colorScheme.tertiary,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
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
            color: isActive ? Theme.of(context).colorScheme.tertiary : Theme.of(context).colorScheme.onSecondary,
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
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
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
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSecondary,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
                onPressed: _currentIndex > 0
                    ? () => _pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.ease,
                )
                    : null,
                child: const Text('Previous'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                  foregroundColor: Theme.of(context).colorScheme.onTertiary,
                ),
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
          : Center(child: Text("No content available", style: TextStyle(color: Theme.of(context).colorScheme.onSecondary))),
    );
  }
}
