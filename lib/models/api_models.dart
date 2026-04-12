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