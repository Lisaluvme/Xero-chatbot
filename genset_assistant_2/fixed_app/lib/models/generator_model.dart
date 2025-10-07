class GeneratorStatus {
  final bool isRunning;
  final String location;
  final int runHours;
  final int fuelLevel;
  final double batteryVoltage;
  final int temperature;
  final int oilPressure;
  final List<String> faults;

  GeneratorStatus({
    required this.isRunning,
    required this.location,
    required this.runHours,
    required this.fuelLevel,
    required this.batteryVoltage,
    required this.temperature,
    required this.oilPressure,
    required this.faults,
  });

  factory GeneratorStatus.fromJson(Map<String, dynamic> json) {
    return GeneratorStatus(
      isRunning: json['isRunning'] ?? false,
      location: json['location'] ?? 'Unknown',
      runHours: json['runHours'] ?? 0,
      fuelLevel: json['fuelLevel'] ?? 0,
      batteryVoltage: json['batteryVoltage'] ?? 0.0,
      temperature: json['temperature'] ?? 0,
      oilPressure: json['oilPressure'] ?? 0,
      faults: List<String>.from(json['faults'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isRunning': isRunning,
      'location': location,
      'runHours': runHours,
      'fuelLevel': fuelLevel,
      'batteryVoltage': batteryVoltage,
      'temperature': temperature,
      'oilPressure': oilPressure,
      'faults': faults,
    };
  }
}

class ServiceRecordModel {
  final int id;
  final DateTime date;
  final String type;
  final String description;
  final DateTime nextService;

  ServiceRecordModel({
    required this.id,
    required this.date,
    required this.type,
    required this.description,
    required this.nextService,
  });

  factory ServiceRecordModel.fromJson(Map<String, dynamic> json) {
    return ServiceRecordModel(
      id: json['id'],
      date: DateTime.parse(json['date']),
      type: json['type'],
      description: json['description'],
      nextService: DateTime.parse(json['nextService']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'nextService': nextService.toIso8601String(),
    };
  }
}
