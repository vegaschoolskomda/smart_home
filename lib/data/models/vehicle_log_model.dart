class VehicleLogModel {
  final int? id;
  final double distance;
  final String vehicleStatus;
  final String detectedAt;

  VehicleLogModel({
    this.id,
    required this.distance,
    required this.vehicleStatus,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'distance': distance,
      'vehicle_status': vehicleStatus,
      'detected_at': detectedAt,
    };
  }

  factory VehicleLogModel.fromMap(Map<String, dynamic> map) {
    return VehicleLogModel(
      id: map['id'] as int?,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      vehicleStatus: (map['vehicle_status'] ?? 'Tidak Ada') as String,
      detectedAt: (map['detected_at'] ?? '') as String,
    );
  }
}
