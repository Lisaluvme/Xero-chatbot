import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      if (!MirrorApiService.hasLinkedCredentials()) {
        setState(() {
          _gensets = [];
          _isLoading = false;
        });
        return;
      }

      final gensets = await MirrorApiService.getGensets();
      setState(() {
        _gensets = gensets;
        _isLoading = false;
      });

      final notificationService = NotificationService();
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 3,
        centerTitle: true,
        title: const Text('Live Generator Status'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF1E3A8A)))
          : RefreshIndicator(
        onRefresh: _loadGensets,
        child: _gensets.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _gensets.length,
          itemBuilder: (context, index) {
            final genset = _gensets[index];
            return _buildGensetCard(genset, theme);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.power_settings_new, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              MirrorApiService.hasLinkedCredentials()
                  ? 'No genset data available'
                  : 'Please connect your Mirror API credentials first.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGensetCard(MirrorGenset genset, ThemeData theme) {
    final statusColor = _getStatusColor(genset.statusName);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, Colors.blue.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(2, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧠 Title Row
            Row(
              children: [
                Icon(Icons.power, color: statusColor, size: 26),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    genset.gsname,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (genset.sourceUtoken != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      genset.sourceUtoken!,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // 🧩 Info rows
            _buildInfoRow('Module', genset.modulename, Icons.settings, Colors.blueGrey),
            _buildInfoRow('Status', genset.statusName, Icons.bolt, statusColor),
            _buildInfoRow('Total Time', genset.totaltime, Icons.timelapse, Colors.indigo),
            _buildInfoRow('Day Time', genset.daytime, Icons.access_time, Colors.teal),

            // 🚨 Alarm list
            if (genset.alarmList.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Active Alarms',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 6),
              ...genset.alarmList.map((alarm) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        color: theme.colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        alarm,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
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
        return Colors.green.shade600;
      case 'stopped':
      case 'offline':
        return Colors.red.shade600;
      case 'standby':
      case 'idle':
        return Colors.orange.shade600;
      default:
        return Colors.blue.shade600;
    }
  }
}
