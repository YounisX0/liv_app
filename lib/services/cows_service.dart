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

  Future<ApiCow> createCow({
    required String token,
    required String cowId,
    required String name,
    required String tagNumber,
    required String breed,
    required int ageMonths,
    required String deviceId,
  }) async {
    final data = await apiClient.post(
      '/cows',
      token: token,
      body: {
        'cowId': cowId,
        'name': name,
        'tagNumber': tagNumber,
        'breed': breed,
        'ageMonths': ageMonths,
        'deviceId': deviceId,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid create cow response.');
    }

    return ApiCow.fromJson(data);
  }

  Future<ApiCow> updateCow({
    required String token,
    required String cowId,
    required Map<String, dynamic> updates,
  }) async {
    final data = await apiClient.patch(
      '/cows/$cowId',
      token: token,
      body: updates,
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid update cow response.');
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

  Future<List<ApiVetAction>> getCowVetActions({
    required String token,
    required String cowId,
  }) async {
    final data = await apiClient.get(
      '/cows/$cowId/vet-actions',
      token: token,
    );

    if (data is! List) {
      throw const ApiException('Invalid vet actions response.');
    }

    return data
        .map(
          (item) => ApiVetAction.fromJson(
            Map<String, dynamic>.from(item),
          ),
        )
        .toList();
  }

  Future<ApiVetAction> createVetAction({
    required String token,
    required String cowId,
    required String message,
    required String recommendedAction,
    required String priority,
  }) async {
    final data = await apiClient.post(
      '/cows/$cowId/vet-actions',
      token: token,
      body: {
        'message': message,
        'recommendedAction': recommendedAction,
        'priority': priority,
      },
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid create vet action response.');
    }

    return ApiVetAction.fromJson(data);
  }

  Future<ApiVetAction> acknowledgeVetAction({
    required String token,
    required String actionId,
  }) async {
    final data = await apiClient.patch(
      '/vet-actions/$actionId/acknowledge',
      token: token,
      body: const {},
    );

    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid acknowledge vet action response.');
    }

    return ApiVetAction.fromJson(data);
  }
}