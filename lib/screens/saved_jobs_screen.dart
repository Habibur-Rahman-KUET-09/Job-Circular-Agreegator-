import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../providers/saved_job_provider.dart';

class SavedJobsScreen extends StatefulWidget {
  const SavedJobsScreen({super.key});

  @override
  State<SavedJobsScreen> createState() => _SavedJobsScreenState();
}

class _SavedJobsScreenState extends State<SavedJobsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<SavedJobProvider>().fetchSavedJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final savedJobProvider = context.watch<SavedJobProvider>();
    final savedJobs = savedJobProvider.savedJobs;
    final isLoading = savedJobProvider.isLoading;
    final error = savedJobProvider.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.savedJobs),
        elevation: 0,
      ),
      body: isLoading && savedJobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && savedJobs.isEmpty
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
                          savedJobProvider.fetchSavedJobs();
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : savedJobs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.bookmark_border,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(s.noSavedJobs),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: savedJobs.length,
                      padding: const EdgeInsets.all(8),
                      itemBuilder: (context, index) {
                        final savedJob = savedJobs[index];
                        return SavedJobCard(
                          savedJob: savedJob,
                          onRemove: () {
                            savedJobProvider.removeSavedJob(savedJob.id);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(s.jobRemoved)),
                            );
                          },
                        );
                      },
                    ),
    );
  }
}

class SavedJobCard extends StatelessWidget {
  final SavedJob savedJob;
  final VoidCallback onRemove;

  const SavedJobCard({
    super.key,
    required this.savedJob,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        savedJob.jobTitle,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        savedJob.company,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onRemove,
                  tooltip: s.remove,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    savedJob.location,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            if (savedJob.notes != null && savedJob.notes!.isNotEmpty) ...[
              const SizedBox(height: 12),
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
                      s.notes,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      savedJob.notes!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.savedOn(_formatDate(savedJob.savedAt)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    // Navigate to job details or open apply link
                  },
                  icon: const Icon(Icons.open_in_new, size: 16),
                  label: Text(s.viewDetails),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Model class (should be in models/saved_job.dart)
class SavedJob {
  final String id;
  final String jobId;
  final String jobTitle;
  final String company;
  final String location;
  final DateTime savedAt;
  final String? notes;

  SavedJob({
    required this.id,
    required this.jobId,
    required this.jobTitle,
    required this.company,
    required this.location,
    required this.savedAt,
    this.notes,
  });

  factory SavedJob.fromJson(Map<String, dynamic> json) {
    return SavedJob(
      id: json['id'] as String,
      jobId: json['jobId'] as String,
      jobTitle: json['jobTitle'] as String,
      company: json['company'] as String,
      location: json['location'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'jobId': jobId,
    'jobTitle': jobTitle,
    'company': company,
    'location': location,
    'savedAt': savedAt.toIso8601String(),
    'notes': notes,
  };
}
