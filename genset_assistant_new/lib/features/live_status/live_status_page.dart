import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/genset_provider.dart';
import '../../models/genset_model.dart';

class LiveStatusPage extends StatefulWidget {
  const LiveStatusPage({super.key});

  @override
  State<LiveStatusPage> createState() => _LiveStatusPageState();
}

class _LiveStatusPageState extends State<LiveStatusPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<GensetProvider>(context, listen: false).fetchGensets();
    });
  }

  void showGensetDetails(Genset genset) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.blue.shade800],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.electrical_services, color: Colors.white, size: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          genset.name.isNotEmpty ? genset.name : "Unknown Genset",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),

                // Content
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(genset.status).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(genset.status),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(genset.status),
                                color: _getStatusColor(genset.status),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                genset.status,
                                style: TextStyle(
                                  color: _getStatusColor(genset.status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Basic Info Cards
                        _buildInfoCard("ID", genset.id, Icons.perm_identity),
                        _buildInfoCard("Model", genset.model, Icons.build),
                        _buildInfoCard("Brand", genset.brand, Icons.business),
                        _buildInfoCard("Power", genset.power, Icons.flash_on),

                        const SizedBox(height: 16),

                        // Location and Fuel
                        _buildInfoCard("Location", genset.location, Icons.location_on),
                        _buildInfoCard("Fuel Type", genset.fuel, Icons.local_gas_station),

                        const SizedBox(height: 16),

                        // Specifications
                        if (genset.specifications != null && genset.specifications!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.settings, color: Colors.blue.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      "Specifications",
                                      style: TextStyle(
                                        color: Colors.blue.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...genset.specifications!.entries.take(5).map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          "${entry.key}:",
                                          style: TextStyle(
                                            color: Colors.blue.shade600,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          entry.value.toString(),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Customer Info
                        _buildInfoCard("Customer", genset.customer ?? 'N/A', Icons.person),
                        _buildInfoCard("Category", genset.category, Icons.category),

                        const SizedBox(height: 16),

                        // Maintenance Status
                        if (genset.maintenanceStatus != null && genset.maintenanceStatus!.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                     genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                  ? Colors.orange.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                       genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                    ? Colors.orange.shade200
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
                                      ? Colors.orange
                                      : Colors.green,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    "Maintenance: ${genset.maintenanceStatus}",
                                    style: TextStyle(
                                      color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                             genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                          ? Colors.orange.shade700
                                          : Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700),
                                const SizedBox(width: 8),
                                Text(
                                  "Maintenance Status: Good",
                                  style: TextStyle(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
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
    final statusColor = _getStatusColor(genset.status);
    final statusIcon = _getStatusIcon(genset.status);

    return GestureDetector(
      onTap: () => showGensetDetails(genset),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status and name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      statusIcon,
                      color: statusColor,
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            genset.status,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.grey.shade400,
                    size: 20,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Details row
              Row(
                children: [
                  Expanded(
                    child: _buildCardDetail("ID", genset.id, Icons.perm_identity),
                  ),
                  Expanded(
                    child: _buildCardDetail("Power", genset.power, Icons.flash_on),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildCardDetail("Customer", genset.customer ?? 'N/A', Icons.person),
                  ),
                  Expanded(
                    child: _buildCardDetail("Location", genset.location, Icons.location_on),
                  ),
                ],
              ),

              // Maintenance indicator
              if (genset.maintenanceStatus != null && genset.maintenanceStatus!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                           genset.maintenanceStatus!.toLowerCase().contains('overdue')
                        ? Colors.orange.shade50
                        : Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                             genset.maintenanceStatus!.toLowerCase().contains('overdue')
                          ? Colors.orange.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        genset.maintenanceStatus!.toLowerCase().contains('due') ||
                        genset.maintenanceStatus!.toLowerCase().contains('overdue')
                            ? Icons.warning
                            : Icons.check_circle,
                        color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                               genset.maintenanceStatus!.toLowerCase().contains('overdue')
                            ? Colors.orange.shade600
                            : Colors.green.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        genset.maintenanceStatus!,
                        style: TextStyle(
                          color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                 genset.maintenanceStatus!.toLowerCase().contains('overdue')
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetail(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('running') || statusLower.contains('online')) {
      return Colors.green;
    } else if (statusLower.contains('alarm') || statusLower.contains('error')) {
      return Colors.red;
    } else if (statusLower.contains('standby') || statusLower.contains('off')) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  IconData _getStatusIcon(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('running') || statusLower.contains('online')) {
      return Icons.play_circle_filled;
    } else if (statusLower.contains('alarm') || statusLower.contains('error')) {
      return Icons.error;
    } else if (statusLower.contains('standby') || statusLower.contains('off')) {
      return Icons.pause_circle_filled;
    }
    return Icons.help;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<GensetProvider>(
      builder: (context, gensetProvider, child) {
        if (gensetProvider.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (gensetProvider.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text("Failed to load genset data"),
                  Text(gensetProvider.error),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => gensetProvider.fetchGensets(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        if (gensetProvider.gensets.isEmpty) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.electrical_services, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    "No gensets assigned to your account",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Contact support to get access to your gensets",
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => gensetProvider.fetchGensets(),
                    child: const Text("Retry"),
                  ),
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text("Live Status"),
            backgroundColor: colorScheme.primaryContainer,
            foregroundColor: colorScheme.onPrimaryContainer,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primaryContainer.withOpacity(0.1),
                  colorScheme.background,
                ],
              ),
            ),
            child: RefreshIndicator(
              onRefresh: () => gensetProvider.refreshGensets(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: gensetProvider.gensets.length,
                itemBuilder: (context, index) {
                  final genset = gensetProvider.gensets[index];
                  return _buildGensetCard(genset);
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
