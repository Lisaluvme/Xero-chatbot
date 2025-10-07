import 'package:flutter/material.dart';
import '../../services/mirror_api_service.dart';
import '../../models/mirror_genset_model.dart';
import '../../services/notification_service.dart';


class LiveStatusPage extends StatefulWidget {
  const LiveStatusPage({super.key});

  @override
  State<LiveStatusPage> createState() => _LiveStatusPageState();
}

class _LiveStatusPageState extends State<LiveStatusPage> {
  List<MirrorGenset> _gensets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGensets();
  }

  Future<void> _loadGensets() async {
    try {
      final gensets = await MirrorApiService.getGensets();
      setState(() {
        _gensets = gensets;
        _isLoading = false;
      });

      final notificationService = NotificationService();

      // Check for alarms in any genset
      for (var genset in gensets) {
        if (genset.alarmList.isNotEmpty) {
          await notificationService.showFaultAlert(
            id: 1,
            title: 'Generator Alarm',
            body: '${genset.gsname}: ${genset.alarmList.join(', ')}',
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load genset data: $e')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A3C6E), // Primary Blue
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF1A3C6E).withOpacity(0.3),
        title: const Text('Live Generator Status'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading
          ? Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary))
          : RefreshIndicator(
              onRefresh: _loadGensets,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding to avoid navigation bar overlap
                children: [
                  if (_gensets.isNotEmpty) ...[
                    ..._gensets.map((genset) => _buildGensetCard(genset)),
                  ] else
                    Center(
                      child: Text('No genset data available', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.tertiary,
                      foregroundColor: Theme.of(context).colorScheme.onTertiary,
                    ),
                    onPressed: _loadGensets,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildGensetCard(MirrorGenset genset) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              genset.gsname,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildStatusRow('Module Name', genset.modulename, Icons.settings),
            _buildStatusRow('Status', genset.statusName, Icons.power, color: _getStatusColor(genset.statusName)),
            _buildStatusRow('Total Time', genset.totaltime, Icons.timer),
            _buildStatusRow('Day Time', genset.daytime, Icons.access_time),
            if (genset.alarmList.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Alarms',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
              const SizedBox(height: 4),
              ...genset.alarmList.map(
                (alarm) => Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).colorScheme.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Theme.of(context).colorScheme.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          alarm,
                          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 24, color: color ?? Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: Theme.of(context).colorScheme.onSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'running':
      case 'online':
        return Colors.green;
      case 'stopped':
      case 'offline':
        return Colors.red;
      case 'standby':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
