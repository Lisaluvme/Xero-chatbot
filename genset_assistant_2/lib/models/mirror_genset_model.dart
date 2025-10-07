class MirrorGenset {
  final String gsname;
  final String modulename;
  final String statusName;
  final String totaltime;
  final String daytime;
  final List<String> alarmList;

  MirrorGenset({
    required this.gsname,
    required this.modulename,
    required this.statusName,
    required this.totaltime,
    required this.daytime,
    required this.alarmList,
  });

  factory MirrorGenset.fromJson(Map<String, dynamic> json) {
    return MirrorGenset(
      gsname: json['gsname'] ?? '',
      modulename: json['modulename'] ?? '',
      statusName: json['status_name'] ?? '',
      totaltime: json['totaltime'] ?? '',
      daytime: json['daytime'] ?? '',
      alarmList: json['alarm_list'] != null ? List<String>.from(json['alarm_list']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'gsname': gsname,
      'modulename': modulename,
      'status_name': statusName,
      'totaltime': totaltime,
      'daytime': daytime,
      'alarm_list': alarmList,
    };
  }
}
