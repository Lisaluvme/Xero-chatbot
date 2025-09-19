import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/generator_model.dart';

class LiveStatusPage extends StatefulWidget {
  const LiveStatusPage({super.key});

  @override
  State<LiveStatusPage> createState() => _LiveStatusPageState();
}

class _LiveStatusPageState extends State<LiveStatusPage> {
  final ApiService _apiService = ApiService();
  GeneratorStatus? _generatorStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGeneratorStatus();
  }

  Future<void> _loadGeneratorStatus() async {
    try {
      final status = await _apiService.getGeneratorStatus();
      setState(() {
        _generatorStatus = status;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load generator status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadGeneratorStatus,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  const Text(
                    'Live Generator Status',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_generatorStatus != null) ...[
                    _buildStatusCard(
                      'Generator Status',
                      _generatorStatus!.isRunning ? 'Running' : 'Stopped',
                      _generatorStatus!.isRunning ? Colors.green : Colors.red,
                      Icons.power,
                    ),
                    _buildStatusCard(
                      'Location',
                      _generatorStatus!.location,
                      Colors.blue,
                      Icons.location_on,
                    ),
                    _buildStatusCard(
                      'Run Hours',
                      '${_generatorStatus!.runHours} hours',
                      Colors.purple,
                      Icons.timer,
                    ),
                    _buildStatusCard(
                      'Fuel Level',
                      '${_generatorStatus!.fuelLevel}%',
                      _getFuelColor(_generatorStatus!.fuelLevel),
                      Icons.local_gas_station,
                    ),
                    _buildStatusCard(
                      'Battery Voltage',
                      '${_generatorStatus!.batteryVoltage}V',
                      _getBatteryColor(_generatorStatus!.batteryVoltage),
                      Icons.battery_std,
                    ),
                    _buildStatusCard(
                      'Temperature',
                      '${_generatorStatus!.temperature}°C',
                      _getTemperatureColor(_generatorStatus!.temperature),
                      Icons.thermostat,
                    ),
                    _buildStatusCard(
                      'Oil Pressure',
                      '${_generatorStatus!.oilPressure} PSI',
                      _getPressureColor(_generatorStatus!.oilPressure),
                      Icons.oil_barrel,
                    ),
                    if (_generatorStatus!.faults.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Active Faults',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._generatorStatus!.faults.map(
                        (fault) => Card(
                          color: Colors.red.shade50,
                          child: ListTile(
                            leading: const Icon(Icons.error, color: Colors.red),
                            title: Text(fault),
                            subtitle: const Text('Requires immediate attention'),
                          ),
                        ),
                      ),
                    ],
                  ] else
                    const Center(
                      child: Text('Unable to load generator status'),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadGeneratorStatus,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Status'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon, size: 40, color: color),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value),
        trailing: Icon(
          Icons.circle,
          color: color,
          size: 16,
        ),
      ),
    );
  }

  Color _getFuelColor(int fuelLevel) {
    if (fuelLevel > 50) return Colors.green;
    if (fuelLevel > 25) return Colors.orange;
    return Colors.red;
  }

  Color _getBatteryColor(double voltage) {
    if (voltage >= 12.0) return Colors.green;
    if (voltage >= 11.5) return Colors.orange;
    return Colors.red;
  }

  Color _getTemperatureColor(int temperature) {
    if (temperature < 80) return Colors.green;
    if (temperature < 90) return Colors.orange;
    return Colors.red;
  }

  Color _getPressureColor(int pressure) {
    if (pressure >= 30) return Colors.green;
    if (pressure >= 20) return Colors.orange;
    return Colors.red;
  }
}
