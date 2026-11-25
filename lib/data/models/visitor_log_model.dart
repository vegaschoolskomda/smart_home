class VisitorLogModel {
  final int? id;
  final double distance;
  final int detected; // 0: none, 1: detected
  final String detectedAt;

  VisitorLogModel({
    this.id,
    required this.distance,
    required this.detected,
    required this.detectedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'distance': distance,
      'detected': detected,
      'detected_at': detectedAt,
    };
  }

  factory VisitorLogModel.fromMap(Map<String, dynamic> map) {
    return VisitorLogModel(
      id: map['id'] as int?,
      distance: (map['distance'] as num?)?.toDouble() ?? 0.0,
      detected: (map['detected'] as num?)?.toInt() ?? 0,
      detectedAt: (map['detected_at'] ?? '') as String,
    );
  }
}
