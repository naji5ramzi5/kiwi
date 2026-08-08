import 'dart:convert';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  String? imageUrl;
  final DateTime timestamp;
  final DateTime expiresAt;
  bool isRead;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.timestamp,
    DateTime? expiresAt,
    this.isRead = false,
  }) : expiresAt = expiresAt ?? timestamp.add(const Duration(hours: 48));

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'imageUrl': imageUrl,
    'timestamp': timestamp.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isRead': isRead,
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) => NotificationItem(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    imageUrl: json['imageUrl'],
    timestamp: DateTime.parse(json['timestamp']),
    expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt']) : null,
    isRead: json['isRead'] ?? false,
  );

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  String encode() => jsonEncode(toJson());
  static NotificationItem decode(String source) => NotificationItem.fromJson(jsonDecode(source));
}