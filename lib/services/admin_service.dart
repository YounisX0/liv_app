import '../models/admin_models.dart';
import '../models/api_models.dart';
import 'api_client.dart';

class AdminService {
  final ApiClient apiClient;

  const AdminService(this.apiClient);

  Future<AdminOverview> getOverview({
    required String token,
  }) async {
    final data = await apiClient.get(
      '/admin/overview',
      token: token,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid admin overview response.');
    }

    return AdminOverview.fromJson(data);
  }

  Future<List<ApiUser>> listUsers({
    required String token,
  }) async {
    final data = await apiClient.get(
      '/admin/users',
      token: token,
    );

    if (data is! List) {
      throw const ApiException('Invalid admin users response.');
    }

    return data
        .map((item) => ApiUser.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ApiUser> createUser({
    required String token,
    required String email,
    required String password,
    required String fullName,
    required String farmId,
    required String role,
    String? userId,
  }) async {
    final body = <String, dynamic>{
      'email': email.trim(),
      'password': password,
      'fullName': fullName.trim(),
      'farmId': farmId.trim(),
      'role': role.trim(),
      if (userId != null && userId.trim().isNotEmpty) 'userId': userId.trim(),
    };

    final data = await apiClient.post(
      '/admin/users',
      token: token,
      body: body,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid admin create user response.');
    }

    return ApiUser.fromJson(data);
  }

  Future<ApiUser> updateUser({
    required String token,
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    final data = await apiClient.patch(
      '/admin/users/$userId',
      token: token,
      body: updates,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid admin update user response.');
    }

    return ApiUser.fromJson(data);
  }

  Future<void> deleteUser({
    required String token,
    required String userId,
  }) async {
    await apiClient.delete(
      '/admin/users/$userId',
      token: token,
    );
  }

  Future<List<ApiCow>> listCows({
    required String token,
  }) async {
    final data = await apiClient.get(
      '/admin/cows',
      token: token,
    );

    if (data is! List) {
      throw const ApiException('Invalid admin cows response.');
    }

    return data
        .map((item) => ApiCow.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<ApiCow> createCow({
    required String token,
    required String cowId,
    required String farmId,
    required String name,
    required String tagNumber,
    required String breed,
    required int ageMonths,
    required String deviceId,
  }) async {
    final data = await apiClient.post(
      '/admin/cows',
      token: token,
      body: {
        'cowId': cowId.trim(),
        'farmId': farmId.trim(),
        'name': name.trim(),
        'tagNumber': tagNumber.trim(),
        'breed': breed.trim(),
        'ageMonths': ageMonths,
        'deviceId': deviceId.trim(),
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid admin create cow response.');
    }

    return ApiCow.fromJson(data);
  }

  Future<ApiCow> updateCow({
    required String token,
    required String cowId,
    required Map<String, dynamic> updates,
  }) async {
    final data = await apiClient.patch(
      '/admin/cows/$cowId',
      token: token,
      body: updates,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid admin update cow response.');
    }

    return ApiCow.fromJson(data);
  }

  Future<void> deleteCow({
    required String token,
    required String cowId,
  }) async {
    await apiClient.delete(
      '/admin/cows/$cowId',
      token: token,
    );
  }
}