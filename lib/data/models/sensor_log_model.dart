class SensorLogModel {
  final int? id;
  final double temperature;
  final double humidity;
  final int gasValue;
  final int ldrValue;
  final int rainStatus; // 0: no rain, 1: rain
  final String createdAt;

  SensorLogModel({
    this.id,
    required this.temperature,
    required this.humidity,
    required this.gasValue,
    required this.ldrValue,
    required this.rainStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'temperature': temperature,
      'humidity': humidity,
      'gas_value': gasValue,
      'ldr_value': ldrValue,
      'rain_status': rainStatus,
      'created_at': createdAt,
    };
  }

  factory SensorLogModel.fromMap(Map<String, dynamic> map) {
    return SensorLogModel(
      id: map['id'] as int?,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 0.0,
      humidity: (map['humidity'] as num?)?.toDouble() ?? 0.0,
      gasValue: (map['gas_value'] as num?)?.toInt() ?? 0,
      ldrValue: (map['ldr_value'] as num?)?.toInt() ?? 0,
      rainStatus: (map['rain_status'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}
