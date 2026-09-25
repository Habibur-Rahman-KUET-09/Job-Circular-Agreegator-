import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/notification_provider.dart';
import '../utils/safe_padding.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<NotificationProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final notificationProvider = context.watch<NotificationProvider>();
    final notifications = notificationProvider.notificationHistory;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.notifications),
        elevation: 0,
        actions: [
          if (notificationProvider.unreadCount > 0)
            TextButton(
              onPressed: notificationProvider.markAllAsRead,
              child: Text(s.markAllAsRead),
            ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: Text(s.clearAll),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(s.clearNotifications),
                      content: Text(s.clearNotificationsConfirm),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(s.cancel),
                        ),
                        FilledButton(
                          onPressed: () {
                            notificationProvider.clearHistory();
                            Navigator.pop(context);
                          },
                          child: Text(s.delete),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      body: notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(s.noNotifications),
                ],
              ),
            )
          : ListView.builder(
              itemCount: notifications.length,
              padding: safeBodyPadding(context, amount: 8),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return NotificationTile(
                  notification: notification,
                  index: index,
                  onTap: () {
                    context
                        .read<NotificationProvider>()
                        .markNotificationAsRead(index);
                  },
                );
              },
            ),
    );
  }
}

class NotificationTile extends StatelessWidget {
  final Map<String, dynamic> notification;
  final int index;
  final VoidCallback onTap;

  const NotificationTile({
    super.key,
    required this.notification,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final isRead = notification['read'] as bool? ?? false;
    final timestamp = notification['timestamp'] as DateTime?;
    final type = notification['type'] as String? ?? 'general';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: isRead ? null : Colors.blue[50],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: _getTypeColor(type),
                child: Icon(
                  _getTypeIcon(type),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'] as String? ?? '',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  fontWeight: isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification['body'] as String? ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (timestamp != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _formatTime(s, timestamp),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'application_update':
        return Colors.orange;
      case 'job_deadline':
        return Colors.red;
      case 'job_match':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'application_update':
        return Icons.work;
      case 'job_deadline':
        return Icons.alarm;
      case 'job_match':
        return Icons.star;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(Strings s, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return s.justNow;
    } else if (difference.inHours < 1) {
      return s.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return s.hoursAgo(difference.inHours);
    } else if (difference.inDays < 7) {
      return s.daysAgo(difference.inDays);
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
