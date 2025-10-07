class MirrorApiResponse {
  final String status;
  final String message;
  final MirrorUserData? data;

  MirrorApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory MirrorApiResponse.fromJson(Map<String, dynamic> json) {
    return MirrorApiResponse(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      data: json['data'] != null ? MirrorUserData.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'data': data?.toJson(),
    };
  }
}

class MirrorUserData {
  final String uid;
  final String email;
  final String? mirrorId;
  final DateTime? createdAt;

  MirrorUserData({
    required this.uid,
    required this.email,
    this.mirrorId,
    this.createdAt,
  });

  factory MirrorUserData.fromJson(Map<String, dynamic> json) {
    return MirrorUserData(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      mirrorId: json['mirrorId'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'mirrorId': mirrorId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}
