import 'package:flutter/material.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Learn About Generators',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildLearnSection(
            context,
            'Basic Operation',
            'Learn how to start, stop, and operate generators safely.',
            Icons.power,
          ),
          _buildLearnSection(
            context,
            'Safety Procedures',
            'Important safety guidelines for working with generators.',
            Icons.security,
          ),
          _buildLearnSection(
            context,
            'Generator Components',
            'Understanding the main parts and their functions.',
            Icons.settings,
          ),
          _buildLearnSection(
            context,
            'Fuel Systems',
            'How fuel systems work and maintenance requirements.',
            Icons.local_gas_station,
          ),
          _buildLearnSection(
            context,
            'Electrical Systems',
            'Understanding electrical output and connections.',
            Icons.electrical_services,
          ),
          _buildLearnSection(
            context,
            'Cooling Systems',
            'How generators stay cool during operation.',
            Icons.ac_unit,
          ),
        ],
      ),
    );
  }

  Widget _buildLearnSection(
      BuildContext context, String title, String description, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Colors.blue),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          // Navigate to detailed learning content
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => LearnDetailPage(title: title),
            ),
          );
        },
      ),
    );
  }
}

class LearnDetailPage extends StatelessWidget {
  final String title;

  const LearnDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Detailed information about this topic will be displayed here. '
              'This includes step-by-step guides, diagrams, and important safety information.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Key Points:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Point 1\n• Point 2\n• Point 3\n• Point 4'),
          ],
        ),
      ),
    );
  }
}
