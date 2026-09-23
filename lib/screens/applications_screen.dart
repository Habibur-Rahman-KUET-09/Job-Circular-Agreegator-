import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/application_provider.dart';

class ApplicationsScreen extends StatefulWidget {
  const ApplicationsScreen({super.key});

  @override
  State<ApplicationsScreen> createState() => _ApplicationsScreenState();
}

class _ApplicationsScreenState extends State<ApplicationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Applied', 'Interviewed', 'Selected', 'Rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() {
      context.read<ApplicationProvider>().fetchApplications();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final appProvider = context.watch<ApplicationProvider>();
    final applications = appProvider.applications;
    final isLoading = appProvider.isLoading;
    final error = appProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.myApplications),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
      ),
      body: isLoading && applications.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && applications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(s.errorOccurred),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          appProvider.fetchApplications();
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildApplicationsList(s, applications, appProvider),
                    _buildStatusList(s, applications, 'applied', appProvider),
                    _buildStatusList(s, applications, 'interviewed', appProvider),
                    _buildStatusList(s, applications, 'selected', appProvider),
                    _buildStatusList(s, applications, 'rejected', appProvider),
                  ],
                ),
    );
  }

  Widget _buildApplicationsList(
    Strings s,
    List<Application> applications,
    ApplicationProvider provider,
  ) {
    if (applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.work_history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(s.noApplications),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: applications.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final application = applications[index];
        return ApplicationCard(
          application: application,
          onStatusChange: (status) {
            provider.updateStatus(application.id, status);
          },
        );
      },
    );
  }

  Widget _buildStatusList(
    Strings s,
    List<Application> applications,
    String status,
    ApplicationProvider provider,
  ) {
    final filtered = applications
        .where((app) => app.status.name == status)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(s.noApplicationsInStatus),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final application = filtered[index];
        return ApplicationCard(
          application: application,
          onStatusChange: (status) {
            provider.updateStatus(application.id, status);
          },
        );
      },
    );
  }
}

class ApplicationCard extends StatelessWidget {
  final Application application;
  final Function(ApplicationStatus) onStatusChange;

  const ApplicationCard({
    super.key,
    required this.application,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final statusColor = _getStatusColor(application.status);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.jobTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        application.company,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(
                    application.status.name.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: statusColor,
                  labelStyle: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  s.appliedOn(_formatDate(application.appliedAt)),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (application.interviewDate != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.interviewScheduled,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            '${_formatDate(application.interviewDate!)} at ${application.interviewTime}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (application.notes != null && application.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                s.notes,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                application.notes!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  _showStatusMenu(context);
                },
                child: Text(s.updateStatus),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Applied'),
              onTap: () {
                onStatusChange(ApplicationStatus.applied);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Interviewed'),
              onTap: () {
                onStatusChange(ApplicationStatus.interviewed);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Selected'),
              onTap: () {
                onStatusChange(ApplicationStatus.selected);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Rejected'),
              onTap: () {
                onStatusChange(ApplicationStatus.rejected);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.applied:
        return Colors.blue;
      case ApplicationStatus.interviewed:
        return Colors.orange;
      case ApplicationStatus.selected:
        return Colors.green;
      case ApplicationStatus.rejected:
        return Colors.red;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Model classes (should be in models)
enum ApplicationStatus { applied, interviewed, selected, rejected }

class Application {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? interviewDate;
  final String? interviewTime;
  final String? notes;

  Application({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.status,
    required this.appliedAt,
    this.interviewDate,
    this.interviewTime,
    this.notes,
  });

  factory Application.fromJson(Map<String, dynamic> json) {
    return Application(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String,
      company: json['company'] as String,
      status: ApplicationStatus.values.byName(json['status'] as String? ?? 'applied'),
      appliedAt: DateTime.parse(json['appliedAt'] as String),
      interviewDate: json['interviewDate'] != null
          ? DateTime.parse(json['interviewDate'] as String)
          : null,
      interviewTime: json['interviewTime'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'company': company,
    'status': status.name,
    'appliedAt': appliedAt.toIso8601String(),
    'interviewDate': interviewDate?.toIso8601String(),
    'interviewTime': interviewTime,
    'notes': notes,
  };
}
