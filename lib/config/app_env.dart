import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  AppEnv._();

  static String get apiBaseUrl {
    final raw = dotenv.env['API_BASE_URL']?.trim() ?? '';
    if (raw.isEmpty) return '';
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static bool get hasApiBaseUrl => apiBaseUrl.isNotEmpty;
}