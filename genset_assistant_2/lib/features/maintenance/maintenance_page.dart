import 'package:flutter/material.dart';

class MaintenancePage extends StatelessWidget {
  const MaintenancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Generator Maintenance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildMaintenanceSection(
            context,
            'Daily Checks',
            'Essential checks to perform every day.',
            Icons.today,
            Colors.green,
          ),
          _buildMaintenanceSection(
            context,
            'Weekly Maintenance',
            'Maintenance tasks for weekly intervals.',
            Icons.calendar_view_week,
            Colors.blue,
          ),
          _buildMaintenanceSection(
            context,
            'Monthly Service',
            'Important monthly maintenance procedures.',
            Icons.calendar_month,
            Colors.orange,
          ),
          _buildMaintenanceSection(
            context,
            'Quarterly Inspection',
            'Comprehensive quarterly inspections.',
            Icons.calendar_today,
            Colors.purple,
          ),
          _buildMaintenanceSection(
            context,
            'Annual Service',
            'Complete annual maintenance schedule.',
            Icons.event,
            Colors.red,
          ),
          _buildMaintenanceSection(
            context,
            'Emergency Procedures',
            'What to do in case of breakdowns.',
            Icons.warning,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(
      BuildContext context, String title, String description, IconData icon, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MaintenanceDetailPage(title: title),
            ),
          );
        },
      ),
    );
  }
}

class MaintenanceDetailPage extends StatelessWidget {
  final String title;

  const MaintenanceDetailPage({super.key, required this.title});

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
              'Follow these maintenance procedures carefully to ensure your generator operates safely and efficiently.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Maintenance Checklist:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Check oil levels\n'
              '• Inspect fuel system\n'
              '• Test battery charge\n'
              '• Clean air filters\n'
              '• Check cooling system\n'
              '• Inspect electrical connections\n'
              '• Test emergency stop function',
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Mark as completed
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Maintenance task completed!')),
                );
              },
              child: const Text('Mark as Completed'),
            ),
          ],
        ),
      ),
    );
  }
}
