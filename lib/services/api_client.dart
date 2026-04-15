import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException(statusCode: $statusCode, message: $message)';
}

class ApiClient {
  final String baseUrl;
  final Duration timeout;

  const ApiClient({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 20),
  });

  String get normalizedBaseUrl {
    final trimmed = baseUrl.trim();
    if (trimmed.isEmpty) {
      throw const ApiException('API base URL is missing.');
    }
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  Uri _buildUri(String path) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$normalizedBaseUrl$cleanPath');
  }

  Map<String, String> _headers({String? token}) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.trim().isNotEmpty)
        'Authorization': 'Bearer $token',
    };
  }

  Future<dynamic> get(
    String path, {
    String? token,
  }) async {
    try {
      final response = await http
          .get(_buildUri(path), headers: _headers(token: token))
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response format.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not connect to the server.');
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .post(
            _buildUri(path),
            headers: _headers(token: token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response format.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not connect to the server.');
    }
  }

  Future<dynamic> patch(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .patch(
            _buildUri(path),
            headers: _headers(token: token),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response format.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not connect to the server.');
    }
  }

  Future<dynamic> delete(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    try {
      final response = await http
          .delete(
            _buildUri(path),
            headers: _headers(token: token),
            body: body == null ? null : jsonEncode(body),
          )
          .timeout(timeout);

      return _handleResponse(response);
    } on TimeoutException {
      throw const ApiException('Request timed out. Please try again.');
    } on FormatException {
      throw const ApiException('Invalid server response format.');
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException('Could not connect to the server.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    dynamic decoded;

    if (response.body.isNotEmpty) {
      decoded = jsonDecode(response.body);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    String message = 'Request failed with status ${response.statusCode}.';

    if (decoded is Map<String, dynamic>) {
      final serverMessage = decoded['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        message = serverMessage;
      }
    }

    throw ApiException(message, statusCode: response.statusCode);
  }
}