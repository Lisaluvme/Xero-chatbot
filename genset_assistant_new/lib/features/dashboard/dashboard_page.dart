import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/genset_provider.dart';
import '../../models/genset_model.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Fetch gensets when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GensetProvider>().fetchGensets();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Genset Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Consumer<GensetProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: provider.isLoading ? null : () => provider.refreshGensets(),
                tooltip: 'Refresh',
              );
            },
          ),
        ],
      ),
      body: Consumer<GensetProvider>(
        builder: (context, provider, child) {
          // Loading state
          if (provider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading genset data...'),
                ],
              ),
            );
          }

          // Error state
          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Data',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      provider.error,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.refreshGensets(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Empty state
          if (provider.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.electrical_services_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Gensets Found',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No genset data is available for your account.\nPlease contact your administrator if you believe this is an error.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => provider.refreshGensets(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Data loaded successfully
          return RefreshIndicator(
            onRefresh: () => provider.refreshGensets(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.gensets.length,
              itemBuilder: (context, index) {
                final genset = provider.gensets[index];
                return _buildGensetCard(genset, index);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildGensetCard(Genset genset, int index) {
    // Determine status color
    Color statusColor;
    IconData statusIcon;

    final status = genset.status.toLowerCase();
    if (status.contains('running') || status.contains('online') || status.contains('active')) {
      statusColor = Colors.green;
      statusIcon = Icons.play_circle_filled;
    } else if (status.contains('alarm') || status.contains('error') || status.contains('maintenance')) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
    } else if (status.contains('standby') || status.contains('off')) {
      statusColor = Colors.orange;
      statusIcon = Icons.pause_circle_filled;
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.help;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    statusIcon,
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        genset.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Details grid
            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'ID',
                    genset.id,
                    Icons.perm_identity,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Model',
                    genset.model,
                    Icons.build,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Brand',
                    genset.brand,
                    Icons.business,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Power',
                    genset.power,
                    Icons.flash_on,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Location',
                    genset.location,
                    Icons.location_on,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Fuel',
                    genset.fuel,
                    Icons.local_gas_station,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildDetailItem(
                    'Customer',
                    genset.customer ?? 'N/A',
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildDetailItem(
                    'Category',
                    genset.category,
                    Icons.category,
                  ),
                ),
              ],
            ),

            // Maintenance status section (if any)
            if (genset.maintenanceStatus != null && genset.maintenanceStatus!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                        'Maintenance: ${genset.maintenanceStatus}',
                        style: TextStyle(
                          color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                 genset.maintenanceStatus!.toLowerCase().contains('overdue')
                              ? Colors.orange.shade700
                              : Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
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
}
