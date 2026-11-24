import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class DemoNotification {
  const DemoNotification({
    required this.userId,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String userId;
  final String title;
  final String body;
  final DateTime createdAt;

  Map<String, Object> toJson() => {
        'userId': userId,
        'title': title,
        'body': body,
        'createdAt': createdAt.toIso8601String(),
      };

  factory DemoNotification.fromJson(Map<String, dynamic> json) =>
      DemoNotification(
        userId: json['userId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class DemoNotificationService {
  static const _notificationsKey = 'baghbani.demo_notifications';

  Future<void> add({
    required String userId,
    required String title,
    required String body,
    required DateTime createdAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final notifications = prefs.getStringList(_notificationsKey) ?? [];
    notifications.insert(
      0,
      jsonEncode(
        DemoNotification(
          userId: userId,
          title: title,
          body: body,
          createdAt: createdAt,
        ).toJson(),
      ),
    );
    await prefs.setStringList(_notificationsKey, notifications);
  }

  Future<List<DemoNotification>> getForUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_notificationsKey) ?? [];
    return raw
        .map((item) =>
            DemoNotification.fromJson(jsonDecode(item) as Map<String, dynamic>))
        .where((item) => item.userId == userId)
        .toList();
  }
}
