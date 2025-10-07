import 'package:flutter/material.dart';

class TroubleshootingPage extends StatelessWidget {
  const TroubleshootingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Generator Troubleshooting',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTroubleshootingSection(
            context,
            'Won\'t Start',
            'Generator fails to start or crank.',
            Icons.power_off,
            Colors.red,
          ),
          _buildTroubleshootingSection(
            context,
            'No Power Output',
            'Generator runs but produces no electricity.',
            Icons.flash_off,
            Colors.orange,
          ),
          _buildTroubleshootingSection(
            context,
            'Overheating',
            'Generator temperature is too high.',
            Icons.thermostat,
            Colors.red,
          ),
          _buildTroubleshootingSection(
            context,
            'Low Power Output',
            'Generator produces less power than expected.',
            Icons.battery_alert,
            Colors.yellow,
          ),
          _buildTroubleshootingSection(
            context,
            'Unusual Noises',
            'Strange sounds during operation.',
            Icons.volume_up,
            Colors.purple,
          ),
          _buildTroubleshootingSection(
            context,
            'Fuel Issues',
            'Problems with fuel consumption or supply.',
            Icons.local_gas_station,
            Colors.blue,
          ),
          _buildTroubleshootingSection(
            context,
            'Battery Problems',
            'Starting battery issues.',
            Icons.battery_std,
            Colors.green,
          ),
          _buildTroubleshootingSection(
            context,
            'Other Issues',
            'Miscellaneous problems and solutions.',
            Icons.help,
            Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(
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
              builder: (context) => TroubleshootingDetailPage(title: title),
            ),
          );
        },
      ),
    );
  }
}

class TroubleshootingDetailPage extends StatelessWidget {
  final String title;

  const TroubleshootingDetailPage({super.key, required this.title});

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
              'Follow these troubleshooting steps in order. Always ensure safety first before attempting any repairs.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'Step-by-Step Troubleshooting:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Safety Check: Ensure generator is off and safe to work on.\n'
              '2. Visual Inspection: Look for obvious signs of damage.\n'
              '3. Check Fuel: Verify fuel level and quality.\n'
              '4. Battery Test: Check battery charge and connections.\n'
              '5. System Test: Test individual components.\n'
              '6. Professional Help: Contact service if needed.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Common Causes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Low fuel level\n'
              '• Dead battery\n'
              '• Faulty starter\n'
              '• Clogged fuel filter\n'
              '• Overloaded circuit',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue resolved!')),
                    );
                  },
                  child: const Text('Issue Resolved'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    // Navigate to contact page
                    Navigator.of(context).pushNamed('/contact');
                  },
                  child: const Text('Contact Support'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
