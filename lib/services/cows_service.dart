import '../models/api_models.dart';
import 'api_client.dart';

class CowsService {
  final ApiClient apiClient;

  const CowsService(this.apiClient);

  Future<List<ApiCow>> getCows({
    required String token,
  }) async {
    final data = await apiClient.get(
      '/cows',
      token: token,
    );

    if (data is! List) {
      throw const ApiException('Invalid cows response.');
    }

    return data
        .map((item) => ApiCow.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}