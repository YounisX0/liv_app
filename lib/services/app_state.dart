import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'cows_service.dart';

class AppState extends ChangeNotifier {
  // ── Storage keys ───────────────────────────────────────────────────────────
  static const String _serverUrlKey = 'server_url';
  static const String _localeKey = 'locale';
  static const String _authTokenKey = 'auth_token';

  // Default confirmed backend base URL.
  // You can still change it later from Settings.
  static const String defaultApiBaseUrl =
      'https://onw84kzqif.execute-api.eu-central-1.amazonaws.com';

  // ── Server connection ─────────────────────────────────────────────────────
  String _serverUrl = defaultApiBaseUrl;
  String get serverUrl => _serverUrl;

  bool _connected = false;
  bool get connected => _connected;

  bool get hasServerUrl => _serverUrl.trim().isNotEmpty;

  // ── Locale ────────────────────────────────────────────────────────────────
  AppLocale _locale = AppLocale.en;
  AppLocale get locale => _locale;

  // ── Auth / backend state ─────────────────────────────────────────────────
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  bool _isAuthenticating = false;
  bool get isAuthenticating => _isAuthenticating;

  bool _isFetchingData = false;
  bool get isFetchingData => _isFetchingData;

  bool get isBusy => _isInitializing || _isAuthenticating || _isFetchingData;

  String? _authToken;
  String? get authToken => _authToken;

  ApiUser? _currentUser;
  ApiUser? get currentUser => _currentUser;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated =>
      _authToken != null &&
      _authToken!.trim().isNotEmpty &&
      _currentUser != null;

  // ── Cloud dashboard state ─────────────────────────────────────────────────
  List<Cow> cows = [];
  List<Device> devices = [];
  List<Sire> sires = [];
  List<FarmAlert> alerts = [];

  // ── Gateway telemetry state ───────────────────────────────────────────────
  String udpStatus = 'Waiting...';
  String mqttStatus = 'Not connected';
  String lastPacketTime = '--';
  int totalReceived = 0;
  int totalPublished = 0;
  int badJson = 0;
  String gatewayId = '--';
  TelemetryPacket? latestPacket;
  final List<TelemetryPacket> packetFeed = [];

  // Chart histories (max 40 pts)
  final List<double> tempHistory = [];
  final List<double> hrHistory = [];
  final List<double> spo2History = [];
  final List<double> accelHistory = [];
  final List<double> gyroHistory = [];

  bool _useDemoData = true;
  bool get useDemoData => _useDemoData;

  AppState() {
    initialize();
  }

  // ── Services ──────────────────────────────────────────────────────────────
  ApiClient get _apiClient => ApiClient(baseUrl: _serverUrl);
  AuthService get _authService => AuthService(_apiClient);
  CowsService get _cowsService => CowsService(_apiClient);

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> initialize() async {
    _isInitializing = true;
    _loadDemo(notify: false);

    await _loadLocale();
    await _loadServerUrl();
    await _restoreSession();

    _isInitializing = false;
    notifyListeners();
  }

  // ── Locale ────────────────────────────────────────────────────────────────
  void setLocale(AppLocale loc) {
    _locale = loc;
    _saveLocale(loc);
    notifyListeners();
  }

  Future<void> _saveLocale(AppLocale loc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, loc.code);
    } catch (_) {}
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_localeKey);
      if (code == 'ar') {
        _locale = AppLocale.ar;
      } else {
        _locale = AppLocale.en;
      }
    } catch (_) {
      _locale = AppLocale.en;
    }
  }

  // ── Demo seed state ───────────────────────────────────────────────────────
  void _loadDemo({bool notify = true}) {
    cows = DemoData.cows();
    devices = DemoData.devices();
    sires = DemoData.sires();
    alerts = DemoData.alerts();

    _resetGatewayState();
    _useDemoData = true;
    _connected = false;

    if (notify) {
      notifyListeners();
    }
  }

  void _resetGatewayState() {
    udpStatus = 'Waiting...';
    mqttStatus = 'Not connected';
    lastPacketTime = '--';
    totalReceived = 0;
    totalPublished = 0;
    badJson = 0;
    gatewayId = '--';
    latestPacket = null;
    packetFeed.clear();
    tempHistory.clear();
    hrHistory.clear();
    spo2History.clear();
    accelHistory.clear();
    gyroHistory.clear();
  }

  // ── Server config ─────────────────────────────────────────────────────────
  Future<void> _loadServerUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_serverUrlKey);

      if (saved != null && saved.trim().isNotEmpty) {
        _serverUrl = _normalizeUrl(saved);
      } else {
        _serverUrl = defaultApiBaseUrl;
      }
    } catch (_) {
      _serverUrl = defaultApiBaseUrl;
    }
  }

  Future<void> _saveServerUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_serverUrlKey, url);
    } catch (_) {}
  }

  String _normalizeUrl(String url) {
    final trimmed = url.trim();
    return trimmed.endsWith('/')
        ? trimmed.substring(0, trimmed.length - 1)
        : trimmed;
  }

  void setServerUrl(String url) {
    final normalized = _normalizeUrl(url);
    _serverUrl = normalized.isEmpty ? defaultApiBaseUrl : normalized;
    _saveServerUrl(_serverUrl);

    // Force a reconnect state until next successful API call.
    _connected = false;
    _errorMessage = null;
    notifyListeners();
  }

  // ── Token/session persistence ─────────────────────────────────────────────
  Future<void> _saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
    } catch (_) {}
  }

  Future<void> _clearSavedToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
    } catch (_) {}
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);

      if (token == null || token.trim().isEmpty) {
        _authToken = null;
        _currentUser = null;
        _connected = false;
        return;
      }

      _authToken = token;

      try {
        await fetchMe(notify: false);
        await fetchCows(notify: false);

        _useDemoData = false;
        _connected = true;
        _errorMessage = null;
      } catch (_) {
        await _clearSessionInMemoryAndStorage();
        _loadDemo(notify: false);
      }
    } catch (_) {
      _authToken = null;
      _currentUser = null;
      _connected = false;
    }
  }

  Future<void> _clearSessionInMemoryAndStorage() async {
    _authToken = null;
    _currentUser = null;
    _connected = false;
    _errorMessage = null;
    await _clearSavedToken();
  }

  // ── Error helpers ─────────────────────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

  // ── Auth actions ──────────────────────────────────────────────────────────
  Future<bool> signup({
    required String email,
    required String password,
    required String fullName,
    String farmId = 'farm1',
    String role = 'farmer',
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _authService.signup(
        email: email,
        password: password,
        fullName: fullName,
        farmId: farmId,
        role: role,
      );

      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isAuthenticating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(
        email: email,
        password: password,
      );

      _authToken = result.token;
      _currentUser = result.user;
      await _saveToken(result.token);

      await fetchCows(notify: false);

      _useDemoData = false;
      _connected = true;
      _errorMessage = null;

      _isAuthenticating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      _isAuthenticating = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    await _clearSessionInMemoryAndStorage();
    _loadDemo(notify: false);
    notifyListeners();
  }

  // ── Backend data actions ──────────────────────────────────────────────────
  Future<bool> fetchMe({bool notify = true}) async {
    if (_authToken == null || _authToken!.trim().isEmpty) {
      _errorMessage = 'No auth token found.';
      if (notify) notifyListeners();
      return false;
    }

    try {
      final user = await _authService.getMe(token: _authToken!);
      _currentUser = user;
      _connected = true;
      _errorMessage = null;

      if (notify) {
        notifyListeners();
      }
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      _connected = false;

      if (notify) {
        notifyListeners();
      }
      return false;
    }
  }

  Future<bool> fetchCows({bool notify = true}) async {
    if (_authToken == null || _authToken!.trim().isEmpty) {
      _errorMessage = 'No auth token found.';
      if (notify) notifyListeners();
      return false;
    }

    _isFetchingData = true;
    if (notify) notifyListeners();

    try {
      final apiCows = await _cowsService.getCows(token: _authToken!);

      cows = apiCows.map(_mapApiCowToUiCow).toList();
      devices = _buildDevicesFromApiCows(apiCows);

      // Keep demo sires for now so the breeding tab does not break in Phase 1.
      sires = DemoData.sires();

      // No backend alerts endpoint yet in Phase 1.
      alerts = [];

      _useDemoData = false;
      _connected = true;
      _errorMessage = null;

      _isFetchingData = false;
      if (notify) notifyListeners();
      return true;
    } catch (error) {
      _errorMessage = _readableError(error);
      _connected = false;

      _isFetchingData = false;
      if (notify) notifyListeners();
      return false;
    }
  }

  Future<bool> refreshLiveData() async {
    if (!isAuthenticated) {
      return false;
    }

    final okMe = await fetchMe(notify: false);
    final okCows = await fetchCows(notify: false);

    notifyListeners();
    return okMe && okCows;
  }

  // ── Existing refresh hook used by current UI ──────────────────────────────
  Future<void> resetDemo() async {
    // Keep existing button behavior for demo mode,
    // but make pull-to-refresh useful after login.
    if (isAuthenticated && !_useDemoData) {
      await refreshLiveData();
      return;
    }

    _loadDemo();
  }

  // ── Mapping helpers: backend cow -> current UI cow ────────────────────────
  Cow _mapApiCowToUiCow(ApiCow apiCow) {
    final ageYears = apiCow.ageMonths / 12.0;

    return Cow(
      id: apiCow.cowId,
      name: apiCow.name.isEmpty ? apiCow.tagNumber : apiCow.name,
      breed: apiCow.breed,
      ageYears: ageYears,
      parity: 0,
      deviceId: apiCow.deviceId,
      healthStatus: 'Healthy',
      lastSeen: apiCow.createdAt,
      vitals: const Vitals(),
      vitalsHistory: const [],
      fertility: const Fertility(),
    );
  }

  List<Device> _buildDevicesFromApiCows(List<ApiCow> apiCows) {
    final seen = <String>{};
    final result = <Device>[];

    for (final cow in apiCows) {
      final id = cow.deviceId.trim();
      if (id.isEmpty || seen.contains(id)) continue;

      seen.add(id);
      result.add(
        Device(
          id: id,
          battery: 100,
          signal: -68,
          lastPacketSecAgo: 0,
          status: 'Online',
        ),
      );
    }

    return result;
  }
}