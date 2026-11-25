import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/utils/sensor_evaluator.dart';
import '../database/app_database.dart';
import '../models/device_log_model.dart';
import '../models/esp32_data_model.dart';
import '../models/sensor_log_model.dart';
import '../models/vehicle_log_model.dart';
import '../models/visitor_log_model.dart';
import 'notification_service.dart';

enum EspConnectionStatus {
  disconnected,
  connecting,
  online,
  offline,
}

class Esp32Service extends ChangeNotifier {
  static final Esp32Service instance = Esp32Service._internal();

  EspConnectionStatus _status = EspConnectionStatus.disconnected;
  String _currentIp = '';
  Esp32DataModel? _lastData;
  DateTime? _lastUpdated;
  String? _errorMessage;

  Timer? _pollingTimer;
  bool _isFetching = false;
  bool _isSimulationMode = false;
  DateTime? _lastDbSaveTime;

  // Previous states to detect changes
  bool? _prevVisitorDetected;
  String? _prevVehicleStatus;
  bool? _prevRainStatus;
  bool? _prevLedStatus;
  bool? _prevBuzzerStatus;
  int? _prevServoAngle;

  Esp32Service._internal();

  // Getters
  EspConnectionStatus get status => _status;
  bool get isOnline => _status == EspConnectionStatus.online;
  bool get isConnecting => _status == EspConnectionStatus.connecting;
  bool get isOffline => _status == EspConnectionStatus.offline;
  bool get isDisconnected => _status == EspConnectionStatus.disconnected;
  bool get isSimulationMode => _isSimulationMode;

  String get currentIp => _currentIp;
  Esp32DataModel? get lastData => _lastData;
  DateTime? get lastUpdated => _lastUpdated;
  String? get errorMessage => _errorMessage;

  /// Initialize service and load saved IP from SQLite
  Future<void> init() async {
    final savedIp = await AppDatabase.instance.getLastSavedIp();
    if (savedIp != null && savedIp.isNotEmpty) {
      _currentIp = savedIp;
      notifyListeners();
    }
  }

  /// Connect to ESP32 by IP address
  Future<bool> connect(String ip) async {
    // Bersihkan format input: hilangkan whitespace, http://, https://, dan trailing slash
    String cleanIp = ip.trim();
    cleanIp = cleanIp.replaceAll(RegExp(r'^https?:\/\/'), '');
    cleanIp = cleanIp.replaceAll(RegExp(r'\/.*$'), '');

    if (cleanIp.isEmpty) {
      _errorMessage = 'Alamat IP tidak boleh kosong';
      _status = EspConnectionStatus.disconnected;
      notifyListeners();
      return false;
    }

    _currentIp = cleanIp;
    _status = EspConnectionStatus.connecting;
    _errorMessage = null;
    notifyListeners();

    // Persist IP to SQLite
    await AppDatabase.instance.saveEsp32Ip(_currentIp);

    // Initial check dengan timeout yang lebih toleran
    final success = await _fetchStatus();
    if (success) {
      _status = EspConnectionStatus.online;
      _errorMessage = null;
      _startPolling();
    } else {
      _status = EspConnectionStatus.offline;
      _stopPolling();
    }

    notifyListeners();
    return success;
  }

  /// Disconnect from ESP32
  void disconnect() {
    _stopPolling();
    _status = EspConnectionStatus.disconnected;
    _errorMessage = null;
    notifyListeners();
  }

  /// Toggle Simulation / Demo Mode for testing without physical ESP32
  void toggleSimulation(bool enable) {
    _isSimulationMode = enable;
    if (_isSimulationMode) {
      _status = EspConnectionStatus.online;
      _errorMessage = null;
      _startPolling();
    } else {
      disconnect();
    }
    notifyListeners();
  }

  /// Manual refresh request
  Future<void> refresh() async {
    if (_isSimulationMode) {
      _generateSimulationData();
      return;
    }
    await _fetchStatus();
  }

  void _startPolling() {
    _stopPolling();
    _pollingTimer = Timer.periodic(AppConstants.pollingInterval, (_) {
      if (_isSimulationMode) {
        _generateSimulationData();
      } else {
        _fetchStatus();
      }
    });
  }

  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isFetching = false;
  }

  /// Fetch telemetry from ESP32 HTTP API
  Future<bool> _fetchStatus() async {
    if (_isFetching) return false;
    _isFetching = true;

    try {
      // Build URI. Default endpoint: /api/status or fallback to /api/sensors
      final url = Uri.parse('http://$_currentIp/api/status');
      // Berikan timeout 5 detik untuk koneksi awal Wi-Fi lokal
      final response = await http.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        final data = Esp32DataModel.fromJson(json);

        _lastData = data;
        _lastUpdated = DateTime.now();
        _status = EspConnectionStatus.online;
        _errorMessage = null;

        // Process automations, logging, and notifications
        await _processIncomingData(data);

        notifyListeners();
        _isFetching = false;
        return true;
      } else {
        _handleFetchError('HTTP ${response.statusCode}: Gagal mengambil data');
        _isFetching = false;
        return false;
      }
    } on TimeoutException {
      _handleFetchError('Koneksi timeout (5 detik) ke $_currentIp. Cek apakah HP dan ESP32 di jaringan yang sama.');
      _isFetching = false;
      return false;
    } catch (e) {
      _handleFetchError('Gagal terhubung ke $_currentIp. Pastikan tidak ada AP Isolation di Wi-Fi.');
      _isFetching = false;
      return false;
    }
  }

  void _handleFetchError(String message) {
    _errorMessage = message;
    if (_status == EspConnectionStatus.online || _status == EspConnectionStatus.connecting) {
      _status = EspConnectionStatus.offline;
    }
    notifyListeners();
  }

  /// Process incoming telemetry: check alert conditions and persist logs to SQLite
  Future<void> _processIncomingData(Esp32DataModel data) async {
    final nowIso = DateTime.now().toIso8601String();

    // 1. Visitor Detection Alert & Log
    if (data.visitorDetected) {
      if (_prevVisitorDetected != true) {
        await NotificationService.instance.triggerAlert(
          title: 'Tamu Terdeteksi',
          message: 'Ada tamu di depan rumah (${data.visitorDistance.toStringAsFixed(0)} cm).',
          type: 'visitor',
        );

        await AppDatabase.instance.insertVisitorLog(
          VisitorLogModel(
            distance: data.visitorDistance,
            detected: 1,
            detectedAt: nowIso,
          ),
        );
      }
    } else {
      if (_prevVisitorDetected == true) {
        // Visitor left: reset cooldown
        NotificationService.instance.resetCooldown('visitor');
      }
    }
    _prevVisitorDetected = data.visitorDetected;

    // 2. Vehicle Status Change & Log
    if (_prevVehicleStatus != data.vehicleStatus) {
      await AppDatabase.instance.insertVehicleLog(
        VehicleLogModel(
          distance: data.vehicleDistance,
          vehicleStatus: data.vehicleStatus,
          detectedAt: nowIso,
        ),
      );
      _prevVehicleStatus = data.vehicleStatus;
    }

    // 3. High Temperature Alert
    if (SensorEvaluator.isTemperatureHigh(data.temperature)) {
      await NotificationService.instance.triggerAlert(
        title: 'Peringatan Suhu Tinggi',
        message: 'Suhu ruangan mencapai ${data.temperature.toStringAsFixed(1)} °C, melebihi batas aman.',
        type: 'temperature',
      );
    }

    // 4. High Gas/Smoke Alert
    if (SensorEvaluator.isGasHigh(data.gasValue)) {
      await NotificationService.instance.triggerAlert(
        title: 'Peringatan Gas / Asap',
        message: 'Sensor MQ-2 mendeteksi gas tinggi (${data.gasValue}), waspada bahaya kebakaran.',
        type: 'gas',
      );
    }

    // 5. Rain Sensor & Servo Status Change
    if (_prevRainStatus != null && _prevRainStatus != data.rainStatus) {
      if (data.rainStatus) {
        await NotificationService.instance.triggerAlert(
          title: 'Hujan Terdeteksi',
          message: 'Sensor hujan mendeteksi air. Kanopi bergerak ke 90° secara otomatis.',
          type: 'rain',
        );
      }
    }
    _prevRainStatus = data.rainStatus;

    // 6. Actuator Device State Log
    final bool deviceStateChanged = _prevServoAngle != data.servoAngle ||
        _prevLedStatus != data.ledStatus ||
        _prevBuzzerStatus != data.buzzerStatus;

    if (deviceStateChanged) {
      await AppDatabase.instance.insertDeviceLog(
        DeviceLogModel(
          servoAngle: data.servoAngle,
          ledStatus: data.ledStatus ? 1 : 0,
          buzzerStatus: data.buzzerStatus ? 1 : 0,
          createdAt: nowIso,
        ),
      );
      _prevServoAngle = data.servoAngle;
      _prevLedStatus = data.ledStatus;
      _prevBuzzerStatus = data.buzzerStatus;
    }

    // 7. Periodic Sensor Logging (Every 15 seconds or on significant state change)
    final now = DateTime.now();
    if (_lastDbSaveTime == null || now.difference(_lastDbSaveTime!).inSeconds >= 15) {
      _lastDbSaveTime = now;
      await AppDatabase.instance.insertSensorLog(
        SensorLogModel(
          temperature: data.temperature,
          humidity: data.humidity,
          gasValue: data.gasValue,
          ldrValue: data.ldrValue,
          rainStatus: data.rainStatus ? 1 : 0,
          createdAt: nowIso,
        ),
      );
    }
  }

  // ==================== SIMULATION GENERATOR ====================

  final Random _random = Random();

  void _generateSimulationData() {
    final baseTemp = 28.0 + (_random.nextDouble() * 3.5);
    final baseHumidity = 65.0 + (_random.nextDouble() * 10);
    final isRain = _random.nextDouble() > 0.8;
    final isDark = _random.nextBool();
    final visitorNear = _random.nextDouble() > 0.75;
    final carPresent = _random.nextBool();

    final simData = Esp32DataModel(
      temperature: double.parse(baseTemp.toStringAsFixed(1)),
      humidity: double.parse(baseHumidity.toStringAsFixed(1)),
      gasValue: 400 + _random.nextInt(300),
      ldrValue: isDark ? 2200 : 950,
      rainStatus: isRain,
      visitorDetected: visitorNear,
      visitorDistance: visitorNear ? (20.0 + _random.nextDouble() * 25) : 150.0,
      vehicleStatus: carPresent ? 'Ada' : 'Tidak Ada',
      vehicleDistance: carPresent ? (50.0 + _random.nextDouble() * 40) : 250.0,
      servoAngle: isRain ? 90 : 0,
      ledStatus: isDark,
      buzzerStatus: baseTemp > AppConstants.tempHighThreshold,
      receivedAt: DateTime.now(),
    );

    _lastData = simData;
    _lastUpdated = DateTime.now();
    _status = EspConnectionStatus.online;
    _errorMessage = null;

    _processIncomingData(simData);
    notifyListeners();
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
