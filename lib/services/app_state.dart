import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

/// AppState drives both the Cloud dashboard (cows/alerts/sires) and
/// the Gateway telemetry screen. It uses polling against the Node.js
/// REST API (/api/cloud-state, /api/status).
class AppState extends ChangeNotifier {
  // ── Server connection ─────────────────────────────────────────────────────
  String _serverUrl = 'http://localhost:3000';
  String get serverUrl => _serverUrl;
  bool _connected = false;
  bool get connected => _connected;

  // ── Locale ────────────────────────────────────────────────────────────────
  AppLocale _locale = AppLocale.en;
  AppLocale get locale => _locale;

  void setLocale(AppLocale loc) {
    _locale = loc;
    _saveLocale(loc);
    notifyListeners();
  }

  Future<void> _saveLocale(AppLocale loc) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', loc.code);
  }

  Future<void> _loadLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString('locale');
      if (code == 'ar') {
        _locale = AppLocale.ar;
        notifyListeners();
      }
    } catch (_) {}
  }

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

  Timer? _pollTimer;
  bool _useDemoData = true;
  bool get useDemoData => _useDemoData;

  AppState() {
    _loadDemo();
    _loadLocale();
    _startPolling();
  }

  // ── Demo ──────────────────────────────────────────────────────────────────
  void _loadDemo() {
    cows = DemoData.cows();
    devices = DemoData.devices();
    sires = DemoData.sires();
    alerts = DemoData.alerts();
    notifyListeners();
  }

  // ── Server config ─────────────────────────────────────────────────────────
  void setServerUrl(String url) {
    _serverUrl = url.trimRight().replaceAll(RegExp(r'/$'), '');
    _fetchAll();
  }

  // ── Polling ───────────────────────────────────────────────────────────────
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) => _fetchAll());
  }

  Future<void> _fetchAll() async {
    await Future.wait([_fetchCloudState(), _fetchStatus()]);
  }

  Future<void> _fetchCloudState() async {
    try {
      final res = await http
          .get(Uri.parse('$_serverUrl/api/cloud-state'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _useDemoData = false;
        _connected = true;
        cows = (data['cows'] as List? ?? []).map((e) => Cow.fromJson(e)).toList();
        devices = (data['devices'] as List? ?? []).map((e) => Device.fromJson(e)).toList();
        sires = (data['sires'] as List? ?? []).map((e) => Sire.fromJson(e)).toList();
        alerts = (data['alerts'] as List? ?? []).map((e) => FarmAlert.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (_) {
      _connected = false;
      if (!_useDemoData) {
        _useDemoData = true;
        _loadDemo();
      }
      notifyListeners();
    }
  }

  Future<void> _fetchStatus() async {
    try {
      final res = await http
          .get(Uri.parse('$_serverUrl/api/status'))
          .timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        udpStatus = data['udpStatus'] ?? udpStatus;
        mqttStatus = data['mqttStatus'] ?? mqttStatus;
        totalReceived = data['totalReceived'] ?? totalReceived;
        totalPublished = data['totalPublished'] ?? totalPublished;
        badJson = data['badJson'] ?? badJson;
        gatewayId = data['gatewayId'] ?? gatewayId;
        if (data['latest'] != null) {
          _pushPacket(TelemetryPacket.fromJson(data['latest']));
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  void _pushPacket(TelemetryPacket p) {
    latestPacket = p;
    lastPacketTime = _timeAgo(p.receivedAt);
    packetFeed.insert(0, p);
    if (packetFeed.length > 40) packetFeed.removeLast();

    void push(List<double> list, double? v) {
      if (v == null) return;
      list.add(v);
      if (list.length > 40) list.removeAt(0);
    }

    push(tempHistory, p.tempC);
    push(hrHistory, p.hrI2c);
    push(spo2History, p.spo2I2c);
    push(accelHistory, p.accelMag);
    push(gyroHistory, p.gyroMag);
  }

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    return '${diff.inMinutes}m ago';
  }

  Future<void> resetDemo() async {
    try {
      await http.post(Uri.parse('$_serverUrl/api/demo/reset'));
      await _fetchCloudState();
    } catch (_) {
      _loadDemo();
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
