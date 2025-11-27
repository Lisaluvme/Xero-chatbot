import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/genset_model.dart';

class GensetMapWidget extends StatefulWidget {
  final Genset genset;
  final bool showFullscreenButton;
  final double height;
  final double width;
  final bool showFollowButton;

  const GensetMapWidget({
    super.key,
    required this.genset,
    this.showFullscreenButton = true,
    this.height = 200,
    this.width = double.infinity,
    this.showFollowButton = false,
  });

  @override
  State<GensetMapWidget> createState() => _GensetMapWidgetState();
}

class _GensetMapWidgetState extends State<GensetMapWidget> {
  late MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Schedule center operation after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _isMapReady = true;
      });
      _centerOnGenset();
    });
  }

  void _centerOnGenset() {
    if (_isMapReady && widget.genset.latitude != null && widget.genset.longitude != null) {
      _mapController.move(LatLng(widget.genset.latitude!, widget.genset.longitude!), 16.0);
    }
  }

  Color _getMarkerColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('running') || lowerStatus.contains('online')) {
      return Colors.greenAccent;
    } else if (lowerStatus.contains('alarm') || lowerStatus.contains('error')) {
      return Colors.redAccent;
    } else if (lowerStatus.contains('standby') || lowerStatus.contains('idle')) {
      return Colors.blueAccent;
    }
    return Colors.orangeAccent;
  }

  void _showFullscreenMap() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => FullscreenMapWidget(
          genset: widget.genset,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            )),
            child: child,
          );
        },
      ),
    );
  }

  void _followGensetLocation() {
    if (_isMapReady) {
      _centerOnGenset();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.genset.latitude == null || widget.genset.longitude == null) {
      return Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 8),
              Text(
                'Location not available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final center = LatLng(widget.genset.latitude!, widget.genset.longitude!);

    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 16.0,
                minZoom: 3.0,
                maxZoom: 18.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.genset_assistant',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      width: 40.0,
                      height: 40.0,
                      point: center,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _getMarkerColor(widget.genset.status),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.power,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      rotate: false,
                    ),
                  ],
                ),
              ],
            ),

            // Follow button overlay
            if (widget.showFollowButton)
              Positioned(
                top: 12,
                right: widget.showFullscreenButton ? 60 : 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _followGensetLocation,
                    icon: const Icon(Icons.center_focus_strong, size: 20),
                    tooltip: 'Follow Genset Location',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),

            // Fullscreen button overlay
            if (widget.showFullscreenButton)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _showFullscreenMap,
                    icon: const Icon(Icons.fullscreen, size: 20),
                    tooltip: 'View Fullscreen Map',
                    constraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                ),
              ),

            // Status indicator overlay
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.circle,
                      size: 12,
                      color: _getMarkerColor(widget.genset.status),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.genset.status,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Location coordinates overlay
            Positioned(
              bottom: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.red.shade600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${widget.genset.latitude?.toStringAsFixed(6)}, ${widget.genset.longitude?.toStringAsFixed(6)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Genset name overlay
            Positioned(
              bottom: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.genset.name,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FullscreenMapWidget extends StatefulWidget {
  final Genset genset;

  const FullscreenMapWidget({super.key, required this.genset});

  @override
  State<FullscreenMapWidget> createState() => _FullscreenMapWidgetState();
}

class _FullscreenMapWidgetState extends State<FullscreenMapWidget> {
  late MapController _mapController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    // Allow time for map to initialize
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _isMapReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Color _getMarkerColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('running') || lowerStatus.contains('online')) {
      return Colors.greenAccent;
    } else if (lowerStatus.contains('alarm') || lowerStatus.contains('error')) {
      return Colors.redAccent;
    } else if (lowerStatus.contains('standby') || lowerStatus.contains('idle')) {
      return Colors.blueAccent;
    }
    return Colors.orangeAccent;
  }

  void _focusOnGenset() {
    if (_isMapReady && widget.genset.latitude != null && widget.genset.longitude != null) {
      final center = LatLng(widget.genset.latitude!, widget.genset.longitude!);
      _mapController.move(center, 18.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.genset.latitude == null || widget.genset.longitude == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Genset Location'),
          backgroundColor: const Color(0xFF1E3A8A),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Location not available',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final center = LatLng(widget.genset.latitude!, widget.genset.longitude!);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.genset.name} Location'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _focusOnGenset,
            icon: const Icon(Icons.center_focus_strong),
            tooltip: 'Focus on Genset',
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: center,
          initialZoom: 16.0,
          minZoom: 3.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.genset_assistant',
          ),
          MarkerLayer(
            markers: [
              Marker(
                width: 50.0,
                height: 50.0,
                point: center,
                child: Container(
                  decoration: BoxDecoration(
                    color: _getMarkerColor(widget.genset.status),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.power,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                rotate: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
