import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_env.dart';
import '../l10n/app_localizations.dart';
import '../models/admin_models.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import 'admin_service.dart';
import 'api_client.dart';
import 'auth_service.dart';
import 'cows_service.dart';

class AppState extends ChangeNotifier {
  static const String _localeKey = 'locale';
  static const String _authTokenKey = 'auth_token';

  // ── Server connection ─────────────────────────────────────────────────────
  String get serverUrl => AppEnv.apiBaseUrl;

  bool _connected = false;
  bool get connected => _connected;

  bool get hasServerUrl => AppEnv.hasApiBaseUrl;

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

  bool get isAdmin => (_currentUser?.role.toLowerCase() == 'admin');

  // ── Admin state ──────────────────────────────────────────────────────────
  AdminOverview? _adminOverview;
  AdminOverview? get adminOverview => _adminOverview;

  List<ApiUser> _adminUsers = [];
  List<ApiUser> get adminUsers => List.unmodifiable(_adminUsers);

  List<ApiCow> _adminCows = [];
  List<ApiCow> get adminCows => List.unmodifiable(_adminCows);

  bool _isAdminLoading = false;
  bool get isAdminLoading => _isAdminLoading;

  bool _isAdminMutating = false;
  bool get isAdminMutating => _isAdminMutating;

  String? _adminErrorMessage;
  String? get adminErrorMessage => _adminErrorMessage;

  // ── Live backend caches ──────────────────────────────────────────────────
  final List<String> _cowOrder = [];
  final Map<String, ApiCow> _cowDetailsById = {};
  final Map<String, ApiCowLatestState?> _latestStateByCowId = {};
  final Map<String, List<ApiPredictionRecord>> _predictionsByCowId = {};
  final Set<String> _loadingCowIds = {};
  final Map<String, String> _cowErrors = {};

  ApiCow? cowDetailsCache(String cowId) => _cowDetailsById[cowId];

  ApiCowLatestState? cowLatestStateCache(String cowId) =>
      _latestStateByCowId[cowId];

  List<ApiPredictionRecord> cowPredictionsCache(String cowId) =>
      List.unmodifiable(_predictionsByCowId[cowId] ?? const []);

  bool isCowDataLoading(String cowId) => _loadingCowIds.contains(cowId);

  String? cowDataError(String cowId) => _cowErrors[cowId];

  // ── UI-facing state used by the current screens ──────────────────────────
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

  ApiClient get _apiClient => ApiClient(baseUrl: serverUrl);
  AuthService get _authService => AuthService(_apiClient);
  CowsService get _cowsService => CowsService(_apiClient);
  AdminService get _adminService => AdminService(_apiClient);

  Future<void> initialize() async {
    _isInitializing = true;
    _loadDemo(notify: false);

    await _loadLocale();
    await _restoreSession();

    _isInitializing = false;
    notifyListeners();
  }

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
      _locale = code == 'ar' ? AppLocale.ar : AppLocale.en;
    } catch (_) {
      _locale = AppLocale.en;
    }
  }

  void _loadDemo({bool notify = true}) {
    _clearCowCaches();
    _clearAdminState(notify: false);

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

  void _clearCowCaches() {
    _cowOrder.clear();
    _cowDetailsById.clear();
    _latestStateByCowId.clear();
    _predictionsByCowId.clear();
    _loadingCowIds.clear();
    _cowErrors.clear();
  }

  void _clearAdminState({bool notify = true}) {
    _adminOverview = null;
    _adminUsers = [];
    _adminCows = [];
    _adminErrorMessage = null;
    _isAdminLoading = false;
    _isAdminMutating = false;

    if (notify) {
      notifyListeners();
    }
  }

  void _clearNormalUiState() {
    _clearCowCaches();
    cows = [];
    devices = [];
    alerts = [];
    sires = [];
    _resetGatewayState();
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

      final okMe = await fetchMe(notify: false);
      if (!okMe) {
        await _clearSessionInMemoryAndStorage();
        _loadDemo(notify: false);
        return;
      }

      if (isAdmin) {
        _clearNormalUiState();
        await fetchAdminData(notify: false);
        await fetchCows(notify: false);
      } else {
        _clearAdminState(notify: false);
        await fetchCows(notify: false);
      }

      _useDemoData = false;
      _connected = true;
      _errorMessage = null;
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearAdminError() {
    _adminErrorMessage = null;
    notifyListeners();
  }

  String _readableError(Object error) {
    if (error is ApiException) {
      return error.message;
    }
    return 'Something went wrong. Please try again.';
  }

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

      if (isAdmin) {
        _clearNormalUiState();
        await fetchAdminData(notify: false);
        await fetchCows(notify: false);
      } else {
        _clearAdminState(notify: false);
        await fetchCows(notify: false);
      }

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

  Future<bool> fetchAdminData({bool notify = true}) async {
    if (!isAdmin) return false;
    if (_authToken == null || _authToken!.trim().isEmpty) return false;

    _isAdminLoading = true;
    _adminErrorMessage = null;
    if (notify) notifyListeners();

    try {
      final results = await Future.wait([
        _adminService.getOverview(token: _authToken!),
        _adminService.listUsers(token: _authToken!),
        _adminService.listCows(token: _authToken!),
      ]);

      _adminOverview = results[0] as AdminOverview;
      _adminUsers = results[1] as List<ApiUser>;
      _adminCows = results[2] as List<ApiCow>;

      _useDemoData = false;
      _connected = true;
      _adminErrorMessage = null;
      _isAdminLoading = false;

      if (notify) notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _connected = false;
      _isAdminLoading = false;

      if (notify) notifyListeners();
      return false;
    }
  }

  Future<bool> adminCreateUser({
    required String email,
    required String password,
    required String fullName,
    required String farmId,
    required String role,
    String? userId,
  }) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.createUser(
        token: _authToken!,
        email: email,
        password: password,
        fullName: fullName,
        farmId: farmId,
        role: role,
        userId: userId,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminUpdateUser({
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateUser(
        token: _authToken!,
        userId: userId,
        updates: updates,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminDeleteUser(String userId) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.deleteUser(
        token: _authToken!,
        userId: userId,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminCreateCow({
    required String cowId,
    required String farmId,
    required String name,
    required String tagNumber,
    required String breed,
    required int ageMonths,
    required String deviceId,
  }) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.createCow(
        token: _authToken!,
        cowId: cowId,
        farmId: farmId,
        name: name,
        tagNumber: tagNumber,
        breed: breed,
        ageMonths: ageMonths,
        deviceId: deviceId,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminUpdateCow({
    required String cowId,
    required Map<String, dynamic> updates,
  }) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.updateCow(
        token: _authToken!,
        cowId: cowId,
        updates: updates,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> adminDeleteCow(String cowId) async {
    if (!isAdmin || _authToken == null) return false;

    _isAdminMutating = true;
    _adminErrorMessage = null;
    notifyListeners();

    try {
      await _adminService.deleteCow(
        token: _authToken!,
        cowId: cowId,
      );

      await fetchAdminData(notify: false);

      _isAdminMutating = false;
      notifyListeners();
      return true;
    } catch (error) {
      _adminErrorMessage = _readableError(error);
      _isAdminMutating = false;
      notifyListeners();
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

      _cowOrder
        ..clear()
        ..addAll(apiCows.map((e) => e.cowId));

      _cowDetailsById
        ..clear()
        ..addEntries(apiCows.map((e) => MapEntry(e.cowId, e)));

      _latestStateByCowId.removeWhere(
        (cowId, _) => !_cowDetailsById.containsKey(cowId),
      );
      _predictionsByCowId.removeWhere(
        (cowId, _) => !_cowDetailsById.containsKey(cowId),
      );
      _cowErrors.removeWhere(
        (cowId, _) => !_cowDetailsById.containsKey(cowId),
      );
      _loadingCowIds.removeWhere(
        (cowId) => !_cowDetailsById.containsKey(cowId),
      );

      await _prefetchLatestStates(apiCows);
      _rebuildUiStateFromCaches();

      sires = DemoData.sires();

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

  Future<void> _prefetchLatestStates(List<ApiCow> apiCows) async {
    if (_authToken == null || _authToken!.trim().isEmpty) return;

    await Future.wait(
      apiCows.map((cow) async {
        try {
          final latest = await _cowsService.getCowLatestState(
            token: _authToken!,
            cowId: cow.cowId,
          );
          _latestStateByCowId[cow.cowId] = latest;
        } catch (_) {
          _latestStateByCowId[cow.cowId] = null;
        }
      }),
    );
  }

  Future<bool> loadCowProfileData(
    String cowId, {
    bool force = false,
  }) async {
    if (_authToken == null || _authToken!.trim().isEmpty) {
      return false;
    }

    final alreadyReady = _cowDetailsById.containsKey(cowId) &&
        _latestStateByCowId.containsKey(cowId) &&
        _predictionsByCowId.containsKey(cowId);

    if (!force && alreadyReady) {
      return true;
    }

    if (_loadingCowIds.contains(cowId)) {
      return false;
    }

    _loadingCowIds.add(cowId);
    _cowErrors.remove(cowId);
    notifyListeners();

    try {
      final detailFuture = _cowsService.getCowById(
        token: _authToken!,
        cowId: cowId,
      );
      final latestFuture = _cowsService.getCowLatestState(
        token: _authToken!,
        cowId: cowId,
      );
      final predictionsFuture = _cowsService.getCowPredictions(
        token: _authToken!,
        cowId: cowId,
      );

      final detail = await detailFuture;
      final latest = await latestFuture;
      final predictions = await predictionsFuture;

      _cowDetailsById[cowId] = detail;
      _latestStateByCowId[cowId] = latest;
      _predictionsByCowId[cowId] = predictions;

      if (!_cowOrder.contains(cowId)) {
        _cowOrder.add(cowId);
      }

      _rebuildUiStateFromCaches();

      _loadingCowIds.remove(cowId);
      _cowErrors.remove(cowId);
      _connected = true;
      notifyListeners();
      return true;
    } catch (error) {
      _loadingCowIds.remove(cowId);
      _cowErrors[cowId] = _readableError(error);
      notifyListeners();
      return false;
    }
  }

  Future<bool> refreshCowData(String cowId) {
    return loadCowProfileData(cowId, force: true);
  }

  Future<bool> refreshLiveData() async {
    if (!isAuthenticated) {
      return false;
    }

    final okMe = await fetchMe(notify: false);
    if (!okMe) {
      notifyListeners();
      return false;
    }

    bool ok;
    if (isAdmin) {
      final okAdmin = await fetchAdminData(notify: false);
      final okCows = await fetchCows(notify: false);
      ok = okAdmin && okCows;
    } else {
      ok = await fetchCows(notify: false);
    }

    notifyListeners();
    return okMe && ok;
  }

  Future<void> resetDemo() async {
    if (isAuthenticated && !_useDemoData) {
      await refreshLiveData();
      return;
    }

    _loadDemo();
  }

  void _rebuildUiStateFromCaches() {
    final previousCowById = <String, Cow>{
      for (final cow in cows) cow.id: cow,
    };
    final previousDeviceById = <String, Device>{
      for (final device in devices) device.id: device,
    };

    final rebuiltCows = <Cow>[];
    final rebuiltDevices = <Device>[];

    for (final cowId in _cowOrder) {
      final detail = _cowDetailsById[cowId];
      if (detail == null) continue;

      final latest = _latestStateByCowId[cowId];
      final predictions =
          _predictionsByCowId[cowId] ?? const <ApiPredictionRecord>[];
      final previousCow = previousCowById[cowId];

      final uiCow = _mapApiCowToUiCow(
        detail,
        latest: latest,
        predictions: predictions,
        previous: previousCow,
      );
      rebuiltCows.add(uiCow);

      if (detail.deviceId.trim().isNotEmpty) {
        rebuiltDevices.add(
          _mapApiDevice(
            detail,
            latest: latest,
            previous: previousDeviceById[detail.deviceId],
          ),
        );
      }
    }

    cows = rebuiltCows;
    devices = _dedupeDevices(rebuiltDevices);
    alerts = _buildDerivedAlerts(cows);
  }

  List<Device> _dedupeDevices(List<Device> items) {
    final map = <String, Device>{};
    for (final item in items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }

  Cow _mapApiCowToUiCow(
    ApiCow apiCow, {
    ApiCowLatestState? latest,
    List<ApiPredictionRecord> predictions = const [],
    Cow? previous,
  }) {
    final healthStatus = _normalizeHealthStatus(
      latest?.predictedLabel.isNotEmpty == true
          ? latest!.predictedLabel
          : latest?.status ?? previous?.healthStatus ?? 'Healthy',
    );

    final lastPrediction = predictions.isNotEmpty ? predictions.first : null;

    final tempC =
        latest?.tempC ?? lastPrediction?.tempC ?? previous?.vitals.tempC;
    final hrBpm =
        latest?.hrBpm ?? lastPrediction?.hrBpm ?? previous?.vitals.hrBpm;
    final spO2 =
        latest?.spO2 ?? lastPrediction?.spO2 ?? previous?.vitals.spO2;
    final activity =
        latest?.activity ?? lastPrediction?.activity ?? previous?.vitals.activity;

    final vitalsHistory = _buildTempHistory(
      predictions,
      fallbackTemp: tempC,
      previous: previous,
    );

    return Cow(
      id: apiCow.cowId,
      name: apiCow.name.trim().isEmpty ? apiCow.tagNumber : apiCow.name,
      breed: apiCow.breed,
      ageYears: apiCow.ageMonths / 12.0,
      parity: previous?.parity ?? 0,
      deviceId: apiCow.deviceId,
      healthStatus: healthStatus,
      lastSeen: _pickTimestamp(
        latest?.timestamp,
        previous?.lastSeen,
        apiCow.createdAt,
      ),
      vitals: Vitals(
        tempC: tempC,
        hrBpm: hrBpm,
        spO2: spO2,
        activity: activity,
      ),
      vitalsHistory: vitalsHistory,
      fertility: previous?.fertility ?? const Fertility(),
    );
  }

  Device _mapApiDevice(
    ApiCow apiCow, {
    ApiCowLatestState? latest,
    Device? previous,
  }) {
    final ageSec = latest?.lastPacketSecAgo ??
        _estimateSecondsSince(latest?.timestamp) ??
        previous?.lastPacketSecAgo ??
        0;

    final status = ageSec > 300 ? 'Offline' : 'Online';

    return Device(
      id: apiCow.deviceId,
      battery: latest?.battery ?? previous?.battery ?? 100,
      signal: latest?.signal ?? previous?.signal ?? -68,
      lastPacketSecAgo: ageSec,
      status: status,
    );
  }

  List<double> _buildTempHistory(
    List<ApiPredictionRecord> predictions, {
    required double? fallbackTemp,
    Cow? previous,
  }) {
    final temps = predictions
        .map((p) => p.tempC)
        .whereType<double>()
        .toList()
        .reversed
        .toList();

    if (temps.isNotEmpty) {
      return temps;
    }

    if (previous != null && previous.vitalsHistory.isNotEmpty) {
      return previous.vitalsHistory;
    }

    if (fallbackTemp != null) {
      return [fallbackTemp];
    }

    return const [];
  }

  List<FarmAlert> _buildDerivedAlerts(List<Cow> cows) {
    final out = <FarmAlert>[];

    for (final cow in cows) {
      if (cow.healthStatus == 'Healthy') continue;

      out.add(
        FarmAlert(
          id: 'alert_${cow.id}_${cow.healthStatus}',
          severity: _alertSeverityForHealth(cow.healthStatus),
          title: '${cow.healthStatus} detected',
          cowId: cow.id,
          createdAt: cow.lastSeen.isNotEmpty
              ? cow.lastSeen
              : DateTime.now().toIso8601String(),
          details:
              'Latest readings indicate ${cow.healthStatus.toLowerCase()} for ${cow.name}.',
        ),
      );
    }

    out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return out;
  }

  String _alertSeverityForHealth(String healthStatus) {
    switch (healthStatus) {
      case 'Fever':
      case 'Low SpO2':
        return 'danger';
      case 'Heat Stress':
        return 'warning';
      default:
        return 'info';
    }
  }

  String _normalizeHealthStatus(String raw) {
    final v = raw.trim().toLowerCase();

    if (v.isEmpty) return 'Healthy';
    if (v.contains('healthy') || v == 'normal' || v == 'ok') {
      return 'Healthy';
    }
    if (v.contains('heat')) {
      return 'Heat Stress';
    }
    if (v.contains('spo2') || v.contains('spo₂') || v.contains('oxygen')) {
      return 'Low SpO2';
    }
    if (v.contains('fever') ||
        v.contains('high temp') ||
        v.contains('temperature')) {
      return 'Fever';
    }

    return _titleCase(raw);
  }

  String _titleCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return 'Healthy';

    return trimmed
        .split(RegExp(r'\s+'))
        .map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }

  String _pickTimestamp(String? a, String? b, String c) {
    if (a != null && a.trim().isNotEmpty) return a;
    if (b != null && b.trim().isNotEmpty) return b;
    return c;
  }

  int? _estimateSecondsSince(String? iso) {
    if (iso == null || iso.trim().isEmpty) return null;
    try {
      final dt = DateTime.parse(iso).toUtc();
      final now = DateTime.now().toUtc();
      final sec = now.difference(dt).inSeconds;
      return sec < 0 ? 0 : sec;
    } catch (_) {
      return null;
    }
  }
}