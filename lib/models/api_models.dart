class ApiUser {
  final String userId;
  final String email;
  final String fullName;
  final String farmId;
  final String role;
  final String createdAt;

  const ApiUser({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.farmId,
    required this.role,
    required this.createdAt,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      userId: (json['userId'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      fullName: (json['fullName'] ?? '').toString(),
      farmId: (json['farmId'] ?? '').toString(),
      role: (json['role'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'farmId': farmId,
      'role': role,
      'createdAt': createdAt,
    };
  }
}

class ApiCow {
  final String cowId;
  final String farmId;
  final String name;
  final String tagNumber;
  final String breed;
  final int ageMonths;
  final String deviceId;
  final String createdAt;

  const ApiCow({
    required this.cowId,
    required this.farmId,
    required this.name,
    required this.tagNumber,
    required this.breed,
    required this.ageMonths,
    required this.deviceId,
    required this.createdAt,
  });

  factory ApiCow.fromJson(Map<String, dynamic> json) {
    return ApiCow(
      cowId: (json['cowId'] ?? '').toString(),
      farmId: (json['farmId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      tagNumber: (json['tagNumber'] ?? '').toString(),
      breed: (json['breed'] ?? '').toString(),
      ageMonths: _toInt(json['ageMonths']),
      deviceId: (json['deviceId'] ?? '').toString(),
      createdAt: (json['createdAt'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cowId': cowId,
      'farmId': farmId,
      'name': name,
      'tagNumber': tagNumber,
      'breed': breed,
      'ageMonths': ageMonths,
      'deviceId': deviceId,
      'createdAt': createdAt,
    };
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ApiCowLatestState {
  final String cowId;
  final String farmId;
  final String timestamp;
  final String status;
  final String predictedLabel;
  final double confidence;

  final double? tempC;
  final double? hrBpm;
  final double? spO2;
  final double? activity;

  final String deviceId;
  final int? battery;
  final int? signal;
  final int? lastPacketSecAgo;

  const ApiCowLatestState({
    required this.cowId,
    required this.farmId,
    required this.timestamp,
    required this.status,
    required this.predictedLabel,
    required this.confidence,
    required this.tempC,
    required this.hrBpm,
    required this.spO2,
    required this.activity,
    required this.deviceId,
    required this.battery,
    required this.signal,
    required this.lastPacketSecAgo,
  });

  factory ApiCowLatestState.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    double? readDouble(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    int? readInt(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is int) return value;
        if (value is double) return value.toInt();
        final parsed = int.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    final predicted = readString(
      ['predictedLabel', 'prediction', 'label', 'healthStatus', 'status'],
      fallback: 'Healthy',
    );

    final status = readString(
      ['status', 'healthStatus', 'state'],
      fallback: predicted,
    );

    return ApiCowLatestState(
      cowId: readString(['cowId']),
      farmId: readString(['farmId']),
      timestamp: readString(
        ['timestamp', 'ts', 'updatedAt', 'createdAt', 'time'],
      ),
      status: status,
      predictedLabel: predicted,
      confidence: readDouble(['confidence', 'score', 'probability']) ?? 0,
      tempC: readDouble(['tempC', 'temp', 'temperature']),
      hrBpm: readDouble(['hrBpm', 'hr', 'heartRate', 'heart_rate']),
      spO2: readDouble(['spO2', 'spo2', 'oxygen', 'oxygenSaturation']),
      activity: readDouble(['activity', 'activityScore', 'motion']),
      deviceId: readString(['deviceId']),
      battery: readInt(['battery', 'batteryPct']),
      signal: readInt(['signal', 'rssi']),
      lastPacketSecAgo: readInt(['lastPacketSecAgo', 'secondsAgo']),
    );
  }
}

class ApiPredictionRecord {
  final String cowId;
  final String timestamp;
  final String predictedLabel;
  final double confidence;

  final double? tempC;
  final double? hrBpm;
  final double? spO2;
  final double? activity;

  const ApiPredictionRecord({
    required this.cowId,
    required this.timestamp,
    required this.predictedLabel,
    required this.confidence,
    required this.tempC,
    required this.hrBpm,
    required this.spO2,
    required this.activity,
  });

  factory ApiPredictionRecord.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys, {String fallback = ''}) {
      for (final key in keys) {
        final value = json[key];
        if (value != null && value.toString().trim().isNotEmpty) {
          return value.toString();
        }
      }
      return fallback;
    }

    double? readDouble(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value == null) continue;
        if (value is num) return value.toDouble();
        final parsed = double.tryParse(value.toString());
        if (parsed != null) return parsed;
      }
      return null;
    }

    return ApiPredictionRecord(
      cowId: readString(['cowId']),
      timestamp: readString(['timestamp', 'ts', 'createdAt', 'time']),
      predictedLabel: readString(
        ['predictedLabel', 'prediction', 'label', 'healthStatus', 'status'],
        fallback: 'Healthy',
      ),
      confidence: readDouble(['confidence', 'score', 'probability']) ?? 0,
      tempC: readDouble(['tempC', 'temp', 'temperature']),
      hrBpm: readDouble(['hrBpm', 'hr', 'heartRate', 'heart_rate']),
      spO2: readDouble(['spO2', 'spo2', 'oxygen', 'oxygenSaturation']),
      activity: readDouble(['activity', 'activityScore', 'motion']),
    );
  }
}

class LoginResponse {
  final String token;
  final ApiUser user;

  const LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: (json['token'] ?? '').toString(),
      user: ApiUser.fromJson(
        Map<String, dynamic>.from(json['user'] ?? const {}),
      ),
    );
  }
}

class SignupResponse {
  final String message;
  final String userId;

  const SignupResponse({
    required this.message,
    required this.userId,
  });

  factory SignupResponse.fromJson(Map<String, dynamic> json) {
    return SignupResponse(
      message: (json['message'] ?? '').toString(),
      userId: (json['userId'] ?? '').toString(),
    );
  }
}