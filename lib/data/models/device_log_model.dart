class DeviceLogModel {
  final int? id;
  final int servoAngle;
  final int ledStatus; // 0: off, 1: on
  final int buzzerStatus; // 0: off, 1: on
  final String createdAt;

  DeviceLogModel({
    this.id,
    required this.servoAngle,
    required this.ledStatus,
    required this.buzzerStatus,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'servo_angle': servoAngle,
      'led_status': ledStatus,
      'buzzer_status': buzzerStatus,
      'created_at': createdAt,
    };
  }

  factory DeviceLogModel.fromMap(Map<String, dynamic> map) {
    return DeviceLogModel(
      id: map['id'] as int?,
      servoAngle: (map['servo_angle'] as num?)?.toInt() ?? 0,
      ledStatus: (map['led_status'] as num?)?.toInt() ?? 0,
      buzzerStatus: (map['buzzer_status'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }
}
