import '../models/api_models.dart';
import 'api_client.dart';

class AuthService {
  final ApiClient apiClient;

  const AuthService(this.apiClient);

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final data = await apiClient.post(
      '/auth/login',
      body: {
        'email': email.trim(),
        'password': password,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid login response.');
    }

    return LoginResponse.fromJson(data);
  }

  Future<SignupResponse> signup({
    required String email,
    required String password,
    required String fullName,
    String farmId = 'farm1',
    String role = 'farmer',
  }) async {
    final data = await apiClient.post(
      '/auth/signup',
      body: {
        'email': email.trim(),
        'password': password,
        'fullName': fullName.trim(),
        'farmId': farmId.trim(),
        'role': role.trim(),
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid signup response.');
    }

    return SignupResponse.fromJson(data);
  }

  Future<ApiUser> getMe({
    required String token,
  }) async {
    final data = await apiClient.get(
      '/me',
      token: token,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid user profile response.');
    }

    return ApiUser.fromJson(data);
  }
}