import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_scope.dart';
import '../../services/demo_notification_service.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const _notifications = [
    _NotificationItem(
      title: 'Optimal sowing season for Wheat',
      body:
          'Temperature in Punjab has reached ideal levels for Rabi season planting. Review your field preparation.',
      time: '2 hours ago',
      icon: Icons.agriculture_rounded,
      tint: AppColors.farmTint,
      accent: AppColors.farmAccent,
      unread: true,
    ),
    _NotificationItem(
      title: 'New nurseries added nearby',
      body:
          'Green Acres Nursery in Lahore has listed 25 new indoor plants and organic saplings.',
      time: 'Yesterday',
      icon: Icons.storefront_rounded,
      tint: AppColors.nurseryTint,
      accent: AppColors.primary,
      unread: true,
    ),
    _NotificationItem(
      title: 'Welcome to Baghbani!',
      body:
          'Explore your Dashboard to discover crop recommendations, care advice, and local community assistance.',
      time: '2 days ago',
      icon: Icons.eco_rounded,
      tint: AppColors.soft,
      accent: AppColors.primary,
      unread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.cream,
          title: const Text('Notifications'),
          elevation: 0,
        ),
        body: FutureBuilder<List<DemoNotification>>(
          future: DemoNotificationService()
              .getForUser(AuthScope.of(context).profile?.email ?? ''),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Could not load notifications: ${snapshot.error}',
                  style: const TextStyle(color: AppColors.muted),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = [
              ...snapshot.data!.map(
                (notification) => _NotificationItem(
                  title: notification.title,
                  body: notification.body,
                  time: _timeText(notification.createdAt),
                  icon: Icons.agriculture_rounded,
                  tint: AppColors.farmTint,
                  accent: AppColors.farmAccent,
                  unread: true,
                ),
              ),
              ..._notifications,
            ];
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = items[i];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: item.unread
                          ? item.accent.withValues(alpha: 0.3)
                          : AppColors.borderLight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: item.tint,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(item.icon, color: item.accent, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: item.unread
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: AppColors.dark,
                                    ),
                                  ),
                                ),
                                if (item.unread)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: item.accent,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.body,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.muted,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.time,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: AppColors.muted.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      );
}

String _timeText(DateTime date) {
  final now = DateTime.now();
  final sameDay =
      date.year == now.year && date.month == now.month && date.day == now.day;
  return sameDay
      ? 'Today'
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.body,
    required this.time,
    required this.icon,
    required this.tint,
    required this.accent,
    required this.unread,
  });

  final String title;
  final String body;
  final String time;
  final IconData icon;
  final Color tint;
  final Color accent;
  final bool unread;
}
