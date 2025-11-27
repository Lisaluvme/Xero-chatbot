class Genset {
  final String id; // Backend record ID
  final String gensetId; // Maps to "Genset ID"
  final String gsname; // Maps to "gsname"
  final String statusName; // Maps to "status_name"
  final double? longitude; // Maps to "longitude"
  final double? latitude; // Maps to "latitude"
  final String? totaltime; // Maps to "totaltime"
  final String? daytime; // Maps to "daytime"
  final String? token; // Maps to "Token"
  final String? source; // Maps to "_source"
  final String? gsaddress; // Maps to "gsaddress"
  final dynamic alarmNum; // Maps to "alarm_num" - dynamic to handle both int and string

  // Backward compatibility fields
  String get name => gsname;
  String get status => statusName;
  String get location => '${latitude ?? 0}, ${longitude ?? 0}';

  // Additional computed fields for UI compatibility
  String get model => ''; // Not in backend, default empty
  String get brand => 'MGM'; // Default brand
  String get power => powerRating; // Extract from gsname
  String get category => 'Diesel Generator'; // Default category
  String get fuel => 'Diesel'; // Default fuel
  String? get customer => null; // Not in backend
  String? get maintenanceStatus => null; // Not in backend
  String? get databaseLink => null; // Not in backend
  Map<String, dynamic>? get specifications => {
    'token': token,
    'longitude': longitude,
    'latitude': latitude,
    'totaltime': totaltime,
    'daytime': daytime,
    'source': source,
  }; // Computed from available fields
  List<String>? get features => null; // Not in backend
  List<String>? get applications => null; // Not in backend

  Genset({
    required this.id,
    required this.gensetId,
    required this.gsname,
    required this.statusName,
    this.longitude,
    this.latitude,
    this.totaltime,
    this.daytime,
    this.token,
    this.source,
    this.gsaddress,
    this.alarmNum,
  });

  factory Genset.fromJson(Map<String, dynamic> json) {
    // Handle backend response format (flattened, not nested in 'fields')
    return Genset(
      id: json['id']?.toString() ?? '',
      gensetId: json['Genset ID']?.toString() ?? '',
      gsname: json['gsname']?.toString() ?? '',
      statusName: json['status_name']?.toString() ?? '',
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      totaltime: json['totaltime']?.toString(),
      daytime: json['daytime']?.toString(),
      token: json['Token']?.toString(),
      source: json['_source']?.toString(),
      gsaddress: json['gsaddress']?.toString(),
      alarmNum: json['alarm_num'],
    );
  }

  // Factory method for SmartGen API response format
  factory Genset.fromSmartGenJson(Map<String, dynamic> json) {
    // SmartGen API response format mapping - matches actual API response
    return Genset(
      id: json['id']?.toString() ?? '',
      gensetId: json['id']?.toString() ?? '', // Use id as gensetId
      gsname: json['gsname']?.toString() ?? '', // Correct field name
      statusName: json['status_name']?.toString() ?? 'Unknown', // Correct field name
      longitude: json['longitude'] != null ? double.tryParse(json['longitude'].toString()) : null,
      latitude: json['latitude'] != null ? double.tryParse(json['latitude'].toString()) : null,
      totaltime: json['totaltime']?.toString() ?? '0h0min', // Correct field name
      daytime: json['daytime']?.toString() ?? '0h0min', // Correct field name
      token: json['token']?.toString() ?? '',
      source: 'SmartGen API',
      gsaddress: json['gsaddress']?.toString() ?? '',
      alarmNum: json['alarm_num'] ?? 0,
    );
  }

  // Helper method to extract power rating from genset name
  static String _extractPowerFromName(String name) {
    // Try to extract KVA rating from name like "250KVA 2421313 Chuang Seng"
    final kvaMatch = RegExp(r'(\d+)KVA').firstMatch(name);
    if (kvaMatch != null) {
      return '${kvaMatch.group(1)}KVA';
    }

    // Try other patterns
    final kwMatch = RegExp(r'(\d+)KW').firstMatch(name);
    if (kwMatch != null) {
      return '${kwMatch.group(1)}KW';
    }

    return '';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Genset ID': gensetId,
      'gsname': gsname,
      'status_name': statusName,
      'longitude': longitude,
      'latitude': latitude,
      'totaltime': totaltime,
      'daytime': daytime,
      'Database Link': databaseLink,
      'Token': token,
      'gsaddress': gsaddress,
    };
  }

  // Helper method to get formatted display name
  String get displayName => gsname;

  // Helper method to get power rating for easy access (extract from gsname)
  String get powerRating => _extractPowerFromName(gsname);

  // Helper method to check if this is a specific kVA rating
  bool hasKvaRating(String kva) {
    return powerRating.toLowerCase().contains(kva.toLowerCase());
  }

  // Override toString for better debugging
  @override
  String toString() {
    return '${gsname} (${powerRating}) - ${statusName}';
  }
}
