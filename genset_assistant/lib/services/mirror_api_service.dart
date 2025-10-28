import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/mirror_genset_model.dart';

class SmartGenApiResponse {
  final int code;
  final String msg;
  final SmartGenData data;

  SmartGenApiResponse({
    required this.code,
    required this.msg,
    required this.data,
  });

  factory SmartGenApiResponse.fromJson(Map<String, dynamic> json) {
    return SmartGenApiResponse(
      code: json['code'] ?? 0,
      msg: json['msg'] ?? '',
      data: SmartGenData.fromJson(json['data']),
    );
  }
}

class SmartGenData {
  final int total;
  final List<SmartGenGenset> list;

  SmartGenData({
    required this.total,
    required this.list,
  });

  factory SmartGenData.fromJson(Map<String, dynamic> json) {
    return SmartGenData(
      total: json['total'] ?? 0,
      list: (json['list'] as List<dynamic>?)
          ?.map((item) => SmartGenGenset.fromJson(item))
          .toList() ?? [],
    );
  }
}

class SmartGenGenset {
  final int id;
  final String token;
  final String gsname;
  final int moduleid;
  final String gsaddress;
  final String modulename;
  final String hostid;
  final int status;
  final int alarmnum;
  final int gpsen;
  final String longitude;
  final String latitude;
  final String gsimg;
  final int totalhour;
  final int totalminute;
  final int dayhour;
  final int dayminute;
  final int roleid;
  final String statusName;
  final String totaltime;
  final String daytime;
  final List<dynamic> alarmList;

  SmartGenGenset({
    required this.id,
    required this.token,
    required this.gsname,
    required this.moduleid,
    required this.gsaddress,
    required this.modulename,
    required this.hostid,
    required this.status,
    required this.alarmnum,
    required this.gpsen,
    required this.longitude,
    required this.latitude,
    required this.gsimg,
    required this.totalhour,
    required this.totalminute,
    required this.dayhour,
    required this.dayminute,
    required this.roleid,
    required this.statusName,
    required this.totaltime,
    required this.daytime,
    required this.alarmList,
  });

  factory SmartGenGenset.fromJson(Map<String, dynamic> json) {
    return SmartGenGenset(
      id: json['id'] ?? 0,
      token: json['token'] ?? '',
      gsname: json['gsname'] ?? '',
      moduleid: json['moduleid'] ?? 0,
      gsaddress: json['gsaddress'] ?? '',
      modulename: json['modulename'] ?? '',
      hostid: json['hostid'] ?? '',
      status: json['status'] ?? 0,
      alarmnum: json['alarmnum'] ?? 0,
      gpsen: json['gpsen'] ?? 0,
      longitude: json['longitude'] ?? '',
      latitude: json['latitude'] ?? '',
      gsimg: json['gsimg'] ?? '',
      totalhour: json['totalhour'] ?? 0,
      totalminute: json['totalminute'] ?? 0,
      dayhour: json['dayhour'] ?? 0,
      dayminute: json['dayminute'] ?? 0,
      roleid: json['roleid'] ?? 0,
      statusName: json['status_name'] ?? '',
      totaltime: json['totaltime'] ?? '',
      daytime: json['daytime'] ?? '',
      alarmList: json['alarm_list'] ?? [],
    );
  }

  // Convert to MirrorGenset format
  MirrorGenset toMirrorGenset() {
    return MirrorGenset(
      smartGenId: id,
      token: token,
      gensetName: gsname,
      moduleId: moduleid,
      address: gsaddress,
      moduleName: modulename,
      hostId: hostid,
      status: status,
      statusName: statusName,
      alarmNum: alarmnum,
      gpsEnabled: gpsen,
      longitude: double.tryParse(longitude) ?? 0.0,
      latitude: double.tryParse(latitude) ?? 0.0,
      image: gsimg,
      totalHour: totalhour,
      totalMinute: totalminute,
      dayHour: dayhour,
      dayMinute: dayminute,
      roleId: roleid,
      totalTime: totaltime,
      dayTime: daytime,
      alarmList: alarmList,
      customerName: '', // Not provided in SmartGen API
      email: '', // Not provided in SmartGen API
    );
  }
}

class MirrorApiService {
  static const String _smartGenBaseUrl = 'https://www.smartgencloudplus.com';
  static final String _utoken = dotenv.env['SMARTGEN_UTOKEN'] ?? 'bebf6914640ec3ed6bf00398fb7969da';

  // Mirror API service - Firebase integration removed, now using Airtable for data management
  // This service is kept for potential future SmartGen API integration
}
