class ConnectionSettingsModel {
  final int? id;
  final String esp32Ip;
  final String updatedAt;

  ConnectionSettingsModel({
    this.id,
    required this.esp32Ip,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'esp32_ip': esp32Ip,
      'updated_at': updatedAt,
    };
  }

  factory ConnectionSettingsModel.fromMap(Map<String, dynamic> map) {
    return ConnectionSettingsModel(
      id: map['id'] as int?,
      esp32Ip: (map['esp32_ip'] ?? '') as String,
      updatedAt: (map['updated_at'] ?? '') as String,
    );
  }
}
