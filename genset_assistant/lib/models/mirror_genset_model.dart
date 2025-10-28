import 'dart:convert';

class MirrorGenset {
  final int smartGenId;
  final String token;
  final String gensetName;
  final int moduleId;
  final String address;
  final String moduleName;
  final String hostId;
  final int status;
  final String statusName;
  final int alarmNum;
  final int gpsEnabled;
  final double longitude;
  final double latitude;
  final String image;
  final int totalHour;
  final int totalMinute;
  final int dayHour;
  final int dayMinute;
  final int roleId;
  final String totalTime;
  final String dayTime;
  final List<dynamic> alarmList;
  final String customerName;
  final String email;

  MirrorGenset({
    required this.smartGenId,
    required this.token,
    required this.gensetName,
    required this.moduleId,
    required this.address,
    required this.moduleName,
    required this.hostId,
    required this.status,
    required this.statusName,
    required this.alarmNum,
    required this.gpsEnabled,
    required this.longitude,
    required this.latitude,
    required this.image,
    required this.totalHour,
    required this.totalMinute,
    required this.dayHour,
    required this.dayMinute,
    required this.roleId,
    required this.totalTime,
    required this.dayTime,
    required this.alarmList,
    required this.customerName,
    required this.email,
  });

  factory MirrorGenset.fromJson(Map<String, dynamic> json) {
    // Handle both Airtable format and SmartGen API format
    return MirrorGenset(
      smartGenId: json['id'] ?? int.tryParse(json['SmartGen ID']?.toString() ?? '') ?? 0,
      token: json['token'] ?? json['Token'] ?? '',
      gensetName: json['gsname'] ?? json['Genset Name'] ?? '',
      moduleId: json['moduleid'] ?? int.tryParse(json['Module ID']?.toString() ?? '') ?? 0,
      address: json['gsaddress'] ?? json['Address'] ?? '',
      moduleName: json['modulename'] ?? json['Module Name'] ?? '',
      hostId: json['hostid'] ?? json['Host ID'] ?? '',
      status: json['status'] ?? int.tryParse(json['Status']?.toString() ?? '') ?? 0,
      statusName: json['status_name'] ?? json['Status Name'] ?? '',
      alarmNum: json['alarmnum'] ?? int.tryParse(json['Alarm Num']?.toString() ?? '') ?? 0,
      gpsEnabled: json['gpsen'] ?? int.tryParse(json['GPS Enabled']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0.0,
      image: json['gsimg'] ?? json['Image'] ?? '',
      totalHour: json['totalhour'] ?? int.tryParse(json['Total Hour']?.toString() ?? '') ?? 0,
      totalMinute: json['totalminute'] ?? int.tryParse(json['Total Minute']?.toString() ?? '') ?? 0,
      dayHour: json['dayhour'] ?? int.tryParse(json['Day Hour']?.toString() ?? '') ?? 0,
      dayMinute: json['dayminute'] ?? int.tryParse(json['Day Minute']?.toString() ?? '') ?? 0,
      roleId: json['roleid'] ?? int.tryParse(json['Role ID']?.toString() ?? '') ?? 0,
      totalTime: json['totaltime'] ?? json['Total Time'] ?? '',
      dayTime: json['daytime'] ?? json['Day Time'] ?? '',
      alarmList: json['alarm_list'] ?? (json['Alarm List'] != null
          ? (json['Alarm List'] is String
              ? List<dynamic>.from(jsonDecode(json['Alarm List']) as List)
              : List<dynamic>.from(json['Alarm List']))
          : []),
      customerName: json['Customer Name'] ?? '',
      email: json['Email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // Return in SmartGen API format
    return {
      'id': smartGenId,
      'token': token,
      'gsname': gensetName,
      'moduleid': moduleId,
      'gsaddress': address,
      'modulename': moduleName,
      'hostid': hostId,
      'status': status,
      'status_name': statusName,
      'alarmnum': alarmNum,
      'gpsen': gpsEnabled,
      'longitude': longitude.toString(),
      'latitude': latitude.toString(),
      'gsimg': image,
      'totalhour': totalHour,
      'totalminute': totalMinute,
      'dayhour': dayHour,
      'dayminute': dayMinute,
      'roleid': roleId,
      'totaltime': totalTime,
      'daytime': dayTime,
      'alarm_list': alarmList,
    };
  }
}
