import 'package:flutter/material.dart';

class TroubleshootingPage extends StatelessWidget {
  const TroubleshootingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onBackground),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0),
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.search,
                  size: 48,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
                SizedBox(height: 16),
                Text(
                  'Generator Troubleshooting',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'Quick solutions for generator issues',
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Troubleshooting Sections
          _buildTroubleshootingSection(
            context,
            'Won\'t Start',
            'Generator fails to start or crank.',
            Icons.power_off,
            const Color(0xFFDC3545),
          ),
          _buildTroubleshootingSection(
            context,
            'No Power Output',
            'Generator runs but produces no electricity.',
            Icons.flash_off,
            const Color(0xFFFD7E14),
          ),
          _buildTroubleshootingSection(
            context,
            'Overheating',
            'Generator temperature is too high.',
            Icons.thermostat,
            const Color(0xFFDC3545),
          ),
          _buildTroubleshootingSection(
            context,
            'Low Power Output',
            'Generator produces less power than expected.',
            Icons.battery_alert,
            const Color(0xFFFFC107),
          ),
          _buildTroubleshootingSection(
            context,
            'Unusual Noises',
            'Strange sounds during operation.',
            Icons.volume_up,
            const Color(0xFF6F42C1),
          ),
          _buildTroubleshootingSection(
            context,
            'Fuel Issues',
            'Problems with fuel consumption or supply.',
            Icons.local_gas_station,
            const Color(0xFF0D6EFD),
          ),
          _buildTroubleshootingSection(
            context,
            'Battery Problems',
            'Starting battery issues.',
            Icons.battery_std,
            const Color(0xFF198754),
          ),
          _buildTroubleshootingSection(
            context,
            'Other Issues',
            'Miscellaneous problems and solutions.',
            Icons.help_outline,
            const Color(0xFF6C757D),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection(
      BuildContext context, String title, String description, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TroubleshootingDetailPage(title: title),
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
                    icon,
                    size: 32,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
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
  }
}

class TroubleshootingDetailPage extends StatelessWidget {
  final String title;

  const TroubleshootingDetailPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        foregroundColor: Theme.of(context).colorScheme.onBackground,
        title: Text(title),
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Follow these troubleshooting steps in order. Always ensure safety first before attempting any repairs.',
              style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.onSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Step-by-Step Troubleshooting:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '1. Safety Check: Ensure generator is off and safe to work on.\n'
                  '2. Visual Inspection: Look for obvious signs of damage.\n'
                  '3. Check Fuel: Verify fuel level and quality.\n'
                  '4. Battery Test: Check battery charge and connections.\n'
                  '5. System Test: Test individual components.\n'
                  '6. Professional Help: Contact service if needed.',
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            const SizedBox(height: 16),
            Text(
              'Common Causes:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '• Low fuel level\n'
                  '• Dead battery\n'
                  '• Faulty starter\n'
                  '• Clogged fuel filter\n'
                  '• Overloaded circuit',
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.tertiary,
                    foregroundColor: Theme.of(context).colorScheme.onTertiary,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Issue resolved!')),
                    );
                  },
                  child: const Text('Issue Resolved'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Theme.of(context).colorScheme.tertiary),
                    foregroundColor: Theme.of(context).colorScheme.tertiary,
                  ),
                  onPressed: () {
                    Navigator.of(context).pushNamed('/contact');
                  },
                  child: const Text('Contact Support'),
                ),
              ],
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
