import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class ServiceRecordsPage extends StatefulWidget {
  const ServiceRecordsPage({super.key});

  @override
  State<ServiceRecordsPage> createState() => _ServiceRecordsPageState();
}

class _ServiceRecordsPageState extends State<ServiceRecordsPage> {
  final List<ServiceRecord> _serviceRecords = [
    ServiceRecord(
      id: 1,
      date: DateTime.now().subtract(const Duration(days: 30)),
      type: 'Oil Change',
      description: 'Regular oil change and filter replacement',
      nextService: DateTime.now().add(const Duration(days: 60)),
    ),
    ServiceRecord(
      id: 2,
      date: DateTime.now().subtract(const Duration(days: 90)),
      type: 'Air Filter',
      description: 'Air filter cleaning and replacement',
      nextService: DateTime.now().add(const Duration(days: 30)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding to avoid navigation bar overlap
        children: [
          const Text(
            'Service Records',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addNewServiceRecord,
            icon: const Icon(Icons.add),
            label: const Text('Add Service Record'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Upcoming Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._serviceRecords.where((record) => record.nextService.isAfter(DateTime.now()))
              .map((record) => _buildServiceCard(record, true)),
          const SizedBox(height: 16),
          const Text(
            'Recent Services',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ..._serviceRecords.where((record) => record.nextService.isBefore(DateTime.now()) ||
                                              record.nextService.isAtSameMomentAs(DateTime.now()))
              .map((record) => _buildServiceCard(record, false)),
        ],
      ),
    );
  }

  Widget _buildServiceCard(ServiceRecord record, bool isUpcoming) {
    final daysUntil = record.nextService.difference(DateTime.now()).inDays;
    final color = isUpcoming
        ? (daysUntil <= 7 ? Colors.red : Colors.orange)
        : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  record.type,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Icon(
                  isUpcoming ? Icons.schedule : Icons.check_circle,
                  color: color,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Last Service: ${_formatDate(record.date)}'),
            Text('Next Service: ${_formatDate(record.nextService)}'),
            if (isUpcoming) Text('Due in: $daysUntil days'),
            const SizedBox(height: 8),
            Text(record.description),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _markAsCompleted(record),
                  child: const Text('Mark Completed'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _setReminder(record),
                  child: const Text('Set Reminder'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addNewServiceRecord() {
    // Navigate to add service record page
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddServiceRecordPage(),
      ),
    ).then((_) => setState(() {}));
  }

  void _markAsCompleted(ServiceRecord record) {
    setState(() {
      record.date = DateTime.now();
      record.nextService = DateTime.now().add(const Duration(days: 90)); // Default 3 months
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${record.type} marked as completed!')),
    );
  }

  void _setReminder(ServiceRecord record) {
    // Set notification reminder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reminder set for service due date!')),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class ServiceRecord {
  int id;
  DateTime date;
  String type;
  String description;
  DateTime nextService;

  ServiceRecord({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.nextService,
  });
}

class AddServiceRecordPage extends StatefulWidget {
  const AddServiceRecordPage({super.key});

  @override
  State<AddServiceRecordPage> createState() => _AddServiceRecordPageState();
}

class _AddServiceRecordPageState extends State<AddServiceRecordPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  DateTime _nextServiceDate = DateTime.now().add(const Duration(days: 90));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Service Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Service Type',
                  hintText: 'e.g., Oil Change, Air Filter',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter service type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Service details',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    // Save the service record
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Service record added!')),
                    );
                  }
                },
                child: const Text('Save Service Record'),
              ),
              const SizedBox(height: 80), // Added bottom padding to avoid navigation bar overlap
            ],
          ),
        ),
      ),
    );
  }
}
