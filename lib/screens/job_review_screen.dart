import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/job.dart';
import '../services/job_service.dart';
import '../utils/open_link.dart';
import '../widgets/confirm_dialog.dart';

class JobReviewScreen extends StatefulWidget {
  final JobService? jobService;

  const JobReviewScreen({super.key, this.jobService});

  @override
  State<JobReviewScreen> createState() => _JobReviewScreenState();
}

class _JobReviewScreenState extends State<JobReviewScreen> {
  late final JobService _jobService =
      widget.jobService ?? JobService(FirebaseFirestore.instance);
  late final Stream<List<Job>> _pendingJobs = _jobService.watchPendingJobs();
  final Set<String> _busyIds = {};
  bool _approvingAll = false;

  Future<void> _setStatus(Job job, JobStatus status) async {
    final s = Strings.read(context);
    setState(() => _busyIds.add(job.id));
    try {
      await _jobService.setJobStatus(job.id, status);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(status == JobStatus.approved ? s.jobApproved : s.jobRejected),
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errorOccurred)));
    } finally {
      if (mounted) setState(() => _busyIds.remove(job.id));
    }
  }

  Future<void> _approveAll(List<Job> jobs) async {
    final s = Strings.read(context);
    final confirmed = await showConfirmDialog(
      context,
      title: s.approveAllTitle,
      message: s.approveAllMessage(jobs.length),
      confirmLabel: s.approveAll,
      isDestructive: false,
    );
    if (!confirmed || !mounted) return;
    setState(() => _approvingAll = true);
    try {
      await _jobService.approveJobs([for (final job in jobs) job.id]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.allJobsApproved(jobs.length))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errorOccurred)));
    } finally {
      if (mounted) setState(() => _approvingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return StreamBuilder<List<Job>>(
      stream: _pendingJobs,
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <Job>[];
        return Scaffold(
          appBar: AppBar(
            title: Text(s.reviewJobs),
            actions: [
              if (jobs.isNotEmpty)
                TextButton.icon(
                  onPressed: _approvingAll ? null : () => _approveAll(jobs),
                  icon: const Icon(Icons.done_all),
                  label: Text(s.approveAll),
                ),
            ],
          ),
          body: _buildBody(s, snapshot, jobs),
        );
      },
    );
  }

  Widget _buildBody(Strings s, AsyncSnapshot<List<Job>> snapshot, List<Job> jobs) {
    if (snapshot.hasError) {
      return Center(child: Text(s.errorOccurred));
    }
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (jobs.isEmpty) {
      return Center(child: Text(s.noPendingJobs));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        return _PendingJobCard(
          job: job,
          busy: _approvingAll || _busyIds.contains(job.id),
          onApprove: () => _setStatus(job, JobStatus.approved),
          onReject: () => _setStatus(job, JobStatus.rejected),
        );
      },
    );
  }
}

class _PendingJobCard extends StatelessWidget {
  final Job job;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _PendingJobCard({
    required this.job,
    required this.busy,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final deadline = job.deadline;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text('${job.company} • ${job.location}', style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(s.sourceLabel(job.source), style: theme.textTheme.bodySmall),
            if (deadline != null)
              Text(
                s.deadline('${deadline.day}/${deadline.month}/${deadline.year}'),
                style: theme.textTheme.bodySmall,
              ),
            if (job.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                job.description,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
            if (isWebLink(job.applyLink)) ...[
              const SizedBox(height: 4),
              LinkText(job.applyLink!, style: theme.textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onReject,
                  icon: const Icon(Icons.close),
                  label: Text(s.reject),
                  style: OutlinedButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: busy ? null : onApprove,
                  icon: const Icon(Icons.check),
                  label: Text(s.approve),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
