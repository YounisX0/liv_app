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

  Future<ApiCow> getCowById({
    required String token,
    required String cowId,
  }) async {
    final data = await apiClient.get(
      '/cows/$cowId',
      token: token,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid cow details response.');
    }

    return ApiCow.fromJson(data);
  }

  Future<ApiCowLatestState?> getCowLatestState({
    required String token,
    required String cowId,
  }) async {
    try {
      final data = await apiClient.get(
        '/cows/$cowId/latest-state',
        token: token,
      );

      if (data is! Map<String, dynamic>) {
        throw const ApiException('Invalid latest state response.');
      }

      return ApiCowLatestState.fromJson(data);
    } on ApiException catch (e) {
      if (e.statusCode == 404) {
        return null;
      }
      rethrow;
    }
  }

  Future<List<ApiPredictionRecord>> getCowPredictions({
    required String token,
    required String cowId,
  }) async {
    final data = await apiClient.get(
      '/cows/$cowId/predictions',
      token: token,
    );

    if (data is! List) {
      throw const ApiException('Invalid predictions response.');
    }

    return data
        .map(
          (item) => ApiPredictionRecord.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }
}