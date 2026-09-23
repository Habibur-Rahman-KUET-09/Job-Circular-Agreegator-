import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/notification_provider.dart';
import '../services/auth_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  late bool _enableNotifications;
  late bool _jobDeadlineReminders;
  late bool _applicationUpdates;
  late bool _jobMatches;
  late bool _dailyDigest;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    _enableNotifications = true;
    _jobDeadlineReminders = true;
    _applicationUpdates = true;
    _jobMatches = true;
    _dailyDigest = false;
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final notificationProvider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(s.notificationSettings)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.enableNotifications,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              s.notificationDesc,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                        Switch(
                          value: _enableNotifications,
                          onChanged: (value) {
                            setState(() => _enableNotifications = value);
                            final userId =
                                AuthService.instance.currentUser?.uid ?? '';
                            if (value) {
                              notificationProvider
                                  .enableNotifications(userId);
                            } else {
                              notificationProvider
                                  .disableNotifications(userId);
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notification types
            if (_enableNotifications) ...[
              Text(
                s.notificationType,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              _buildNotificationTypeCard(
                context,
                s,
                s.jobDeadlineReminders,
                s.jobDeadlineRemindersDesc,
                _jobDeadlineReminders,
                (value) {
                  setState(() => _jobDeadlineReminders = value);
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationTypeCard(
                context,
                s,
                s.applicationUpdates,
                s.applicationUpdatesDesc,
                _applicationUpdates,
                (value) {
                  setState(() => _applicationUpdates = value);
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationTypeCard(
                context,
                s,
                s.jobMatches,
                s.jobMatchesDesc,
                _jobMatches,
                (value) {
                  setState(() => _jobMatches = value);
                },
              ),
              const SizedBox(height: 8),
              _buildNotificationTypeCard(
                context,
                s,
                s.dailyDigest,
                s.dailyDigestDesc,
                _dailyDigest,
                (value) {
                  setState(() => _dailyDigest = value);
                },
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Notification timing
              Text(
                s.notificationTiming,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.quietHours,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.from,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton(
                                  onPressed: _selectStartTime,
                                  child: Text(s.startTime),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.to,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                OutlinedButton(
                                  onPressed: _selectEndTime,
                                  child: Text(s.endTime),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.notifications_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        s.notificationsDisabled,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Info section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.tip,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.notificationTip,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeCard(
    BuildContext context,
    Strings s,
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }

  void _selectStartTime() {
    showDialog(
      context: context,
      builder: (context) => const TimePickerDialog(
        title: 'Select Quiet Hours Start Time',
      ),
    );
  }

  void _selectEndTime() {
    showDialog(
      context: context,
      builder: (context) => const TimePickerDialog(
        title: 'Select Quiet Hours End Time',
      ),
    );
  }
}

class TimePickerDialog extends StatelessWidget {
  final String title;

  const TimePickerDialog({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 300,
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '22:00',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
