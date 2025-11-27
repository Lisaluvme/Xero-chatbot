import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/genset_provider.dart';
import '../../models/genset_model.dart';
import '../../services/backend_service.dart';
import '../../widgets/genset_map_widget.dart';
import 'dart:async';

class LiveStatusPage extends StatefulWidget {
  const LiveStatusPage({super.key});

  @override
  State<LiveStatusPage> createState() => _LiveStatusPageState();
}

class _LiveStatusPageState extends State<LiveStatusPage>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  Timer? _autoRefreshTimer;
  static const Duration _refreshInterval = Duration(seconds: 30); // Auto-refresh every 30 seconds

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController.forward();

    // Initial data fetch when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchGensetsData();
      _startAutoRefresh();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fadeController.dispose();
    _scaleController.dispose();
    _stopAutoRefresh();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for auto-refresh
    switch (state) {
      case AppLifecycleState.resumed:
        // App is in foreground, start or resume auto-refresh
        print('🔄 App resumed - starting auto-refresh');
        _startAutoRefresh();
        // Also fetch fresh data when app resumes
        _fetchGensetsData();
        break;
      case AppLifecycleState.paused:
        // App is in background, pause auto-refresh to save resources
        print('⏸️ App paused - stopping auto-refresh');
        _stopAutoRefresh();
        break;
      case AppLifecycleState.detached:
        // App is being destroyed
        _stopAutoRefresh();
        break;
      case AppLifecycleState.inactive:
        // App is inactive but still visible
        break;
      case AppLifecycleState.hidden:
        // App is hidden (new in Flutter 3.13+)
        _stopAutoRefresh();
        break;
    }
  }

  void _startAutoRefresh() {
    _stopAutoRefresh(); // Clear any existing timer

    // Check if user is authenticated before starting auto-refresh
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('🔐 No authenticated user - skipping auto-refresh');
      return;
    }

    _autoRefreshTimer = Timer.periodic(_refreshInterval, (timer) {
      print('🔄 Auto-refreshing genset data...');
      _fetchGensetsData();
    });

    print('⏰ Auto-refresh started - refreshing every ${_refreshInterval.inSeconds} seconds');
  }

  void _stopAutoRefresh() {
    if (_autoRefreshTimer != null) {
      _autoRefreshTimer!.cancel();
      _autoRefreshTimer = null;
      print('⏹️ Auto-refresh stopped');
    }
  }

  void _fetchGensetsData() {
    // Check if user is still authenticated
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('🔐 User not authenticated - skipping data fetch');
      return;
    }

    // Only fetch if user is authenticated
    Provider.of<GensetProvider>(context, listen: false).fetchGensets();
  }

  void showGensetDetails(Genset genset) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              _getStatusIcon(genset.status),
              color: _getStatusColor(genset.status),
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                genset.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(genset.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getStatusColor(genset.status).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getStatusVisualData(genset.status).label,
                  style: TextStyle(
                    color: _getStatusColor(genset.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information Section
              _buildSectionHeader('Basic Information'),
              _buildQuickInfoRow('Generator Name', genset.gsname, Icons.electrical_services),
              _buildQuickInfoRow('Genset ID', genset.gensetId, Icons.tag),
              _buildQuickInfoRow('Power Rating', genset.powerRating, Icons.flash_on),
              _buildQuickInfoRow('Brand', genset.brand, Icons.business),
              if (genset.gsaddress != null && genset.gsaddress!.isNotEmpty)
                _buildQuickInfoRow('Address', genset.gsaddress!, Icons.location_on),
              _buildQuickInfoRow('Category', genset.category, Icons.category),
              _buildQuickInfoRow('Fuel Type', genset.fuel, Icons.local_gas_station),

              const SizedBox(height: 16),

              // Time Information Section
              _buildSectionHeader('Running Time'),
              _buildQuickInfoRow('Total Time', genset.totaltime ?? 'Not available', Icons.schedule),
              _buildQuickInfoRow('Day Time', genset.daytime ?? 'Not available', Icons.light_mode),

              const SizedBox(height: 16),

              // Location Information Section
              if (genset.latitude != null && genset.longitude != null) ...[
                _buildSectionHeader('Location'),
                _buildQuickInfoRow(
                  'Coordinates',
                  'Lat: ${genset.latitude!.toStringAsFixed(6)}\nLng: ${genset.longitude!.toStringAsFixed(6)}',
                  Icons.location_on
                ),
              ],

              // Data Source Section
              if (genset.source != null && genset.source!.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildSectionHeader('Data Source'),
                _buildQuickInfoRow('Source', genset.source!, Icons.data_usage),
              ],

              const SizedBox(height: 16),

              // Alarm section - always shows
              _buildAlarmSection(genset.alarmNum),

              const SizedBox(height: 16),

              // Action buttons
              Column(
                children: [
                  if (genset.latitude != null && genset.longitude != null)
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close dialog
                        _showFullMap(genset); // Open optimized full map
                      },
                      icon: const Icon(Icons.map, size: 18),
                      label: const Text('View Full Map'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),

                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _followGensetLocation(Genset genset) {
    // Navigate to the dedicated map page and center on the genset location
    if (genset.latitude != null && genset.longitude != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: Text('${genset.name} Location'),
              backgroundColor: const Color(0xFF1E3A8A),
              foregroundColor: Colors.white,
            ),
            body: CenterOnGensetMapWidget(genset: genset),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this generator'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildQuickInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleDetailHeader(Genset genset) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(genset.status).withOpacity(0.8),
            _getStatusColor(genset.status),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getStatusIcon(genset.status),
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  genset.name.isNotEmpty ? genset.name : "Unknown Genset",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  genset.model ?? 'Model not specified',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, color: Colors.white, size: 24),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullMapSection(Genset genset) {
    if (genset.latitude == null || genset.longitude == null) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.map_outlined,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Location Not Available',
              style: TextStyle(
                color: Colors.grey.shade700,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This generator does not have location coordinates configured.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GensetMapWidget(
              genset: genset,
              height: 300,
              showFullscreenButton: false,
              showFollowButton: true,
            ),
            Positioned(
              top: 12,
              right: 12,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Scene the map to the genset's location
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Map centered on Genset location'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.my_location, size: 16),
                label: const Text('Center'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lat: ${genset.latitude?.toStringAsFixed(6)}, Lng: ${genset.longitude?.toStringAsFixed(6)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleInfoGrid(Genset genset) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Genset Information",
          style: TextStyle(
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.flash_on, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Power",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${genset.power}",
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.business, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          "Customer",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      genset.customer ?? 'N/A',
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailHeader(Genset genset) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(genset.status).withOpacity(0.8),
            _getStatusColor(genset.status),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getStatusIcon(genset.status),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      genset.name.isNotEmpty ? genset.name : "Unknown Genset",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      genset.model ?? 'Model not specified',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final statusData = _getStatusVisualData(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusData.color.withOpacity(0.15),
            statusData.color.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: statusData.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusData.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              statusData.icon,
              color: statusData.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            statusData.label,
            style: TextStyle(
              color: statusData.color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 0.5,
            ),
          ),
          if (statusData.showPulse) ...[
            const SizedBox(width: 8),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusData.color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: statusData.color.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMapSection(Genset genset) {
    if (genset.latitude == null || genset.longitude == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map_outlined, color: Colors.grey.shade700, size: 18),
                const SizedBox(width: 8),
                Text(
                  "Location",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.location_off,
                    size: 32,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Location Not Available',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'This generator does not have location coordinates configured.',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map, color: Colors.blue.shade700, size: 18),
              const SizedBox(width: 8),
              Text(
                "Location",
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),

              const SizedBox(width: 8),
              // Button to view map in full size
              ElevatedButton.icon(
                onPressed: () => _showFullMap(genset),
                icon: const Icon(Icons.fullscreen, size: 16),
                label: const Text('View Map'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Small map preview
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade300),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: GensetMapWidget(
                genset: genset,
                height: 120,
                showFullscreenButton: false,
                showFollowButton: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Location coordinates
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Coordinates: ${genset.latitude?.toStringAsFixed(6)}, ${genset.longitude?.toStringAsFixed(6)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullMap(Genset genset) {
    if (genset.latitude == null || genset.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location not available for this generator'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Navigate to a dedicated map page instead of using Dialog.fullscreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('${genset.name} Location'),
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
          ),
          body: GensetMapWidget(
            genset: genset,
            height: MediaQuery.of(context).size.height,
            showFullscreenButton: false,
            showFollowButton: false,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(Genset genset) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                "Basic Information",
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...[
            {"Power": genset.power},
            {"Brand": genset.brand},
            {"Model": genset.model},
            {"Customer": genset.customer ?? 'N/A'},
          ].map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "${entry.keys.first}:",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.values.first,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecificationsSection(Map<String, dynamic> specifications) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1E3A8A).withOpacity(0.05), const Color(0xFF14B8A6).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E3A8A).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings, color: const Color(0xFF1E3A8A), size: 20),
              const SizedBox(width: 8),
              Text(
                "Technical Specifications",
                style: TextStyle(
                  color: const Color(0xFF1E3A8A),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...specifications.entries.take(6).map((entry) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    "${entry.key}:",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    entry.value.toString(),
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection(String? maintenanceStatus) {
    final bool needsAttention = maintenanceStatus?.toLowerCase().contains('due') == true ||
                               maintenanceStatus?.toLowerCase().contains('overdue') == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: needsAttention ? Colors.blue.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: needsAttention ? Colors.blue.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: needsAttention ? Colors.blue.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              needsAttention ? Icons.warning : Icons.check_circle,
              color: needsAttention ? Colors.blue.shade600 : Colors.green.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Maintenance Status",
                  style: TextStyle(
                    color: needsAttention ? Colors.blue.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  maintenanceStatus?.isNotEmpty == true
                      ? maintenanceStatus!
                      : "All systems operational",
                  style: TextStyle(
                    color: needsAttention ? Colors.blue.shade600 : Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlarmSection(dynamic alarmNum) {
    final int alarmCount = alarmNum is int ? alarmNum : int.tryParse(alarmNum.toString()) ?? 0;
    final bool hasAlarms = alarmCount > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasAlarms ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasAlarms ? Colors.red.shade200 : Colors.green.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasAlarms ? Colors.red.shade100 : Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              hasAlarms ? Icons.error : Icons.check_circle,
              color: hasAlarms ? Colors.red.shade600 : Colors.green.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Active Alarms",
                  style: TextStyle(
                    color: hasAlarms ? Colors.red.shade700 : Colors.green.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasAlarms
                      ? "$alarmCount alarm${alarmCount != 1 ? 's' : ''} detected - requires immediate attention"
                      : "No alarms",
                  style: TextStyle(
                    color: hasAlarms ? Colors.red.shade600 : Colors.green.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGensetCard(Genset genset) {
    final statusData = _getStatusVisualData(genset.status);

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: 280, // Strict height limit to prevent overflow with all original data
        minHeight: 180, // Minimum height for proper display
      ),
      child: GestureDetector(
        onTap: () => showGensetDetails(genset),
        child: AnimatedBuilder(
          animation: _fadeController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeController,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _fadeController,
                  curve: Curves.easeOutCubic,
                )),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: statusData.color.withOpacity(0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Compact header row
                        SizedBox(
                          height: 40,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      statusData.color.withOpacity(0.8),
                                      statusData.color,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  statusData.icon,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Text(
                                      genset.name.isNotEmpty ? genset.name : "Unknown Genset",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                        height: 1.1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Container(
                                      width: 60,
                                      height: 16,
                                      decoration: BoxDecoration(
                                        color: statusData.color.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: statusData.color.withOpacity(0.2),
                                        ),
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        statusData.label,
                                        style: TextStyle(
                                          color: statusData.color,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey.shade400,
                                size: 12,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Info row with all original data
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 140),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Location coordinates - separate lines like original
                              if (genset.latitude != null && genset.longitude != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 14, color: Colors.blue.shade600),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Latitude: ${genset.latitude!.toStringAsFixed(6)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const SizedBox(width: 22),
                                          Expanded(
                                            child: Text(
                                              'Longitude: ${genset.longitude!.toStringAsFixed(6)}',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.grey.shade700,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // Power and Customer
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.flash_on, size: 12, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Power",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            "${genset.power}",
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(Icons.business, size: 12, color: Colors.grey.shade600),
                                              const SizedBox(width: 4),
                                              Text(
                                                "Customer",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _getCustomerName(genset),
                                            style: const TextStyle(
                                              color: Color(0xFF0F172A),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Maintenance status - show original text like before
                              if (genset.maintenanceStatus != null && genset.maintenanceStatus!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                           genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                        ? Colors.amber.shade50
                                        : Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                             genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                          ? Colors.amber.shade200
                                          : Colors.green.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                        genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                            ? Icons.warning
                                            : Icons.check_circle,
                                        color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                               genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                            ? Colors.amber.shade600
                                            : Colors.green.shade600,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          genset.maintenanceStatus!,
                                          style: TextStyle(
                                            color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                                   genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                                ? Colors.amber.shade700
                                                : Colors.green.shade700,
                                            fontWeight: FontWeight.w500,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCompactInfo(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getLocationDisplay(Genset genset) {
    if (genset.latitude != null && genset.longitude != null) {
      return '${genset.latitude?.toStringAsFixed(4)}, ${genset.longitude?.toStringAsFixed(4)}';
    }
    return 'N/A';
  }

  _StatusVisualData _getStatusVisualData(String status) {
    final translatedStatus = _translateStatus(status);
    final statusLower = translatedStatus.toLowerCase();

    if (statusLower.contains('running') || statusLower.contains('online')) {
      return _StatusVisualData(
        label: 'Active',
        icon: Icons.play_circle_filled,
        color: Colors.green.shade600,
        showPulse: true,
      );
    } else if (statusLower.contains('alarm') || statusLower.contains('error')) {
      return _StatusVisualData(
        label: 'Alert',
        icon: Icons.error,
        color: Colors.red.shade600,
        showPulse: true,
      );
    } else if (statusLower.contains('standby') || statusLower.contains('idle')) {
      return _StatusVisualData(
        label: 'Standby',
        icon: Icons.pause_circle_filled,
        color: Colors.blue.shade600,
        showPulse: false,
      );
    } else if (statusLower.contains('offline')) {
      return _StatusVisualData(
        label: 'Offline',
        icon: Icons.power_off,
        color: Colors.grey.shade600,
        showPulse: false,
      );
    }
    return _StatusVisualData(
      label: 'Unknown',
      icon: Icons.help,
      color: Colors.grey.shade600,
      showPulse: false,
    );
  }

  String _translateStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('offline') || lowerStatus.contains('离线')) {
      return 'Offline';
    } else if (lowerStatus.contains('online') || lowerStatus.contains('在线')) {
      return 'Online';
    } else if (lowerStatus.contains('idle') || lowerStatus.contains('空闲')) {
      return 'Idle';
    } else if (lowerStatus.contains('running') || lowerStatus.contains('运行')) {
      return 'Running';
    } else if (lowerStatus.contains('alarm') || lowerStatus.contains('报警')) {
      return 'Alarm';
    } else if (lowerStatus.contains('error') || lowerStatus.contains('故障')) {
      return 'Error';
    } else if (lowerStatus.contains('standby') || lowerStatus.contains('待机')) {
      return 'Standby';
    } else {
      return status;
    }
  }

  Color _getStatusColor(String status) {
    final translatedStatus = _translateStatus(status);
    final statusLower = translatedStatus.toLowerCase();
    if (statusLower.contains('running') || statusLower.contains('online')) {
      return Colors.green;
    } else if (statusLower.contains('alarm') || statusLower.contains('error')) {
      return Colors.red;
    } else if (statusLower.contains('standby') || statusLower.contains('off') || statusLower.contains('idle')) {
      return Colors.blue.shade600;
    }
    return Colors.blue;
  }

  IconData _getStatusIcon(String status) {
    final translatedStatus = _translateStatus(status);
    final statusLower = translatedStatus.toLowerCase();
    if (statusLower.contains('running') || statusLower.contains('online')) {
      return Icons.play_circle_filled;
    } else if (statusLower.contains('alarm') || statusLower.contains('error')) {
      return Icons.error;
    } else if (statusLower.contains('standby') || statusLower.contains('off') || statusLower.contains('idle')) {
      return Icons.pause_circle_filled;
    }
    return Icons.help;
  }

  String _getCustomerName(Genset genset) {
    // Try to get customer name from the database mapping
    // For now, return the customer field or a default value
    return genset.customer ?? 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF14B8A6),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Enhanced Header
              _buildHeader(),
              // Content
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Consumer<GensetProvider>(
                    builder: (context, gensetProvider, child) {
                      if (gensetProvider.isLoading) {
                        return _buildLoadingState();
                      }

                      if (gensetProvider.hasError) {
                        return _buildErrorState(gensetProvider);
                      }

                      if (gensetProvider.gensets.isEmpty) {
                        return _buildEmptyState();
                      }

                      return RefreshIndicator(
                        onRefresh: () async {
                          // Manually refresh when user pulls down
                          _fetchGensetsData();
                          // Also restart auto-refresh timer
                          _startAutoRefresh();
                        },
                        color: const Color(0xFF1E3A8A),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: gensetProvider.gensets.length,
                          itemBuilder: (context, index) {
                            final genset = gensetProvider.gensets[index];
                            print('🔍 [UI] Rendering genset ${index + 1}/${gensetProvider.gensets.length}: ${genset.gsname} (${genset.powerRating}) - ${genset.statusName}');
                            return _buildGensetCard(genset);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.electrical_services,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Live Status",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Small Refresh button
          Consumer<GensetProvider>(
            builder: (context, gensetProvider, child) {
              return Container(
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.white.withOpacity(0.2),
                ),
                child: TextButton.icon(
                  onPressed: gensetProvider.isLoading
                      ? null
                      : () async {
                          try {
                            await gensetProvider.fetchGensets();
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Data refreshed successfully'),
                                  backgroundColor: Colors.green,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Failed to refresh: ${e.toString().split(':').first}'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            }
                          }
                        },
                  icon: gensetProvider.isLoading
                      ? Container(
                          width: 14,
                          height: 14,
                          child: const CircularProgressIndicator(
                            strokeWidth: 1.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.refresh, size: 16, color: Colors.white),
                  label: const Text(
                    'Refresh',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFF1E3A8A),
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  "Loading generator data...",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Auto-refresh enabled",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(GensetProvider gensetProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Colors.red.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "Unable to load generator data",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  gensetProvider.error,
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _fetchGensetsData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Retry"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(
                  Icons.electrical_services,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No generators assigned",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Contact support to get access to your generators",
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _fetchGensetsData(),
                  icon: const Icon(Icons.refresh),
                  label: const Text("Check Again"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusVisualData {
  final String label;
  final IconData icon;
  final Color color;
  final bool showPulse;

  const _StatusVisualData({
    required this.label,
    required this.icon,
    required this.color,
    required this.showPulse,
  });
}

// Simple wrapper widget that auto-centers on the genset location
class CenterOnGensetMapWidget extends StatelessWidget {
  final Genset genset;

  const CenterOnGensetMapWidget({super.key, required this.genset});

  @override
  Widget build(BuildContext context) {
    return GensetMapWidget(
      genset: genset,
      height: MediaQuery.of(context).size.height,
      showFullscreenButton: false,
      showFollowButton: false,
    );
  }
}
