import 'package:flutter/material.dart';
import '../user_manual/user_manual_page.dart'; // 引入 user manual 页面

class LearnPage extends StatefulWidget {
  const LearnPage({super.key});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward(); // 页面一进来就启动动画
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modules = [
      {
        'title': 'Basic Operation',
        'desc': 'Learn how to start, stop, and operate safely.',
        'icon': Icons.power,
        'color': Colors.redAccent,
      },
      {
        'title': 'Safety Procedures',
        'desc': 'Important safety guidelines for working with generators.',
        'icon': Icons.security,
        'color': Colors.orangeAccent,
      },
      {
        'title': 'Generator Components',
        'desc': 'Understand main parts and their functions.',
        'icon': Icons.settings,
        'color': Colors.blueAccent,
      },
      {
        'title': 'Fuel Systems',
        'desc': 'Fuel system working and maintenance requirements.',
        'icon': Icons.local_gas_station,
        'color': Colors.teal,
      },
      {
        'title': 'Electrical Systems',
        'desc': 'Understanding electrical output and connections.',
        'icon': Icons.electrical_services,
        'color': Colors.deepPurple,
      },
      {
        'title': 'Cooling Systems',
        'desc': 'How generators stay cool during operation.',
        'icon': Icons.ac_unit,
        'color': Colors.cyan,
      },
      {
        'title': 'User Manual',
        'desc': 'Step by step guide for using MGM Oversight.',
        'icon': Icons.menu_book,
        'color': Colors.green,
        'isManual': true,
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Learn Center",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding to avoid navigation bar overlap
        child: GridView.builder(
          itemCount: modules.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 每行两个方块
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final module = modules[index];
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                // 让卡片逐个淡入
                final animation = CurvedAnimation(
                  parent: _controller,
                  curve: Interval(
                    (index / modules.length),
                    1.0,
                    curve: Curves.easeOut,
                  ),
                );
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildModuleCard(
                context,
                module['title'] as String,
                module['desc'] as String,
                module['icon'] as IconData,
                module['color'] as Color,
                isUserManual: module['isManual'] == true,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildModuleCard(
      BuildContext context,
      String title,
      String description,
      IconData icon,
      Color color, {
        bool isUserManual = false,
      }) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      onTapCancel: () => setState(() {}),
      onTap: () {
        if (isUserManual) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserManualPage()),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearnDetailPage(title: title),
            ),
          );
        }
      },
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: child,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, size: 30, color: color),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  height: 1.3,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------- LearnDetailPage ----------
class LearnDetailPage extends StatelessWidget {
  final String title;

  const LearnDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Card(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 3,
          shadowColor: Colors.black.withOpacity(0.1),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: ListView(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00B14F),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Detailed information about this topic will be displayed here. '
                      'This includes step-by-step guides, diagrams, and important safety information.',
                  style: TextStyle(
                      fontSize: 15, color: Colors.black87, height: 1.5),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Key Points:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '• Point 1\n• Point 2\n• Point 3\n• Point 4',
                  style: TextStyle(
                      fontSize: 15, color: Colors.black87, height: 1.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
