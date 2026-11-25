class NotificationModel {
  final int? id;
  final String title;
  final String message;
  final String type; // visitor, temperature, gas, rain, system
  final int isRead; // 0: unread, 1: read
  final String createdAt;

  NotificationModel({
    this.id,
    required this.title,
    required this.message,
    required this.type,
    this.isRead = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'message': message,
      'type': type,
      'is_read': isRead,
      'created_at': createdAt,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      title: (map['title'] ?? '') as String,
      message: (map['message'] ?? '') as String,
      type: (map['type'] ?? 'system') as String,
      isRead: (map['is_read'] as num?)?.toInt() ?? 0,
      createdAt: (map['created_at'] ?? '') as String,
    );
  }

  NotificationModel copyWith({
    int? id,
    String? title,
    String? message,
    String? type,
    int? isRead,
    String? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
