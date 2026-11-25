/// Unified model for telemetry received from ESP32
class Esp32DataModel {
  final double temperature;
  final double humidity;
  final int gasValue;
  final int ldrValue;
  final bool rainStatus;
  final bool visitorDetected;
  final double visitorDistance;
  final String vehicleStatus;
  final double vehicleDistance;
  final int servoAngle;
  final bool ledStatus;
  final bool buzzerStatus;
  final DateTime receivedAt;

  Esp32DataModel({
    required this.temperature,
    required this.humidity,
    required this.gasValue,
    required this.ldrValue,
    required this.rainStatus,
    required this.visitorDetected,
    required this.visitorDistance,
    required this.vehicleStatus,
    required this.vehicleDistance,
    required this.servoAngle,
    required this.ledStatus,
    required this.buzzerStatus,
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  /// Safe parser handling both boolean/numeric/string types in ESP32 JSON
  factory Esp32DataModel.fromJson(Map<String, dynamic> json) {
    return Esp32DataModel(
      temperature: _parseDouble(json['temperature'], 0.0),
      humidity: _parseDouble(json['humidity'], 0.0),
      gasValue: _parseInt(json['gas_value'], 0),
      ldrValue: _parseInt(json['ldr_value'], 0),
      rainStatus: _parseBool(json['rain_status']),
      visitorDetected: _parseBool(json['visitor_detected']),
      visitorDistance: _parseDouble(json['visitor_distance'], 0.0),
      vehicleStatus: json['vehicle_status']?.toString() ?? 'Tidak Ada',
      vehicleDistance: _parseDouble(json['vehicle_distance'], 0.0),
      servoAngle: _parseInt(json['servo_angle'], 0),
      ledStatus: _parseBool(json['led_status']),
      buzzerStatus: _parseBool(json['buzzer_status']),
      receivedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'gas_value': gasValue,
      'ldr_value': ldrValue,
      'rain_status': rainStatus,
      'visitor_detected': visitorDetected,
      'visitor_distance': visitorDistance,
      'vehicle_status': vehicleStatus,
      'vehicle_distance': vehicleDistance,
      'servo_angle': servoAngle,
      'led_status': ledStatus,
      'buzzer_status': buzzerStatus,
    };
  }

  static double _parseDouble(dynamic value, double fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic value, int fallback) {
    if (value == null) return fallback;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _parseBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase().trim();
      return lower == 'true' || lower == '1' || lower == 'yes' || lower == 'aktif' || lower == 'ada';
    }
    return false;
  }

  /// Create dummy data strictly for UI preview / testing
  factory Esp32DataModel.dummy() {
    return Esp32DataModel(
      temperature: 28.5,
      humidity: 68.0,
      gasValue: 450,
      ldrValue: 1200,
      rainStatus: false,
      visitorDetected: false,
      visitorDistance: 120.0,
      vehicleStatus: 'Ada',
      vehicleDistance: 65.0,
      servoAngle: 0,
      ledStatus: false,
      buzzerStatus: false,
      receivedAt: DateTime.now(),
    );
  }
}
