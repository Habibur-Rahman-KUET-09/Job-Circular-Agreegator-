import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../utils/open_link.dart';
import '../models/job.dart';
import '../providers/application_provider.dart';
import '../providers/saved_job_provider.dart';

class JobDetailsScreen extends StatefulWidget {
  final Job job;

  const JobDetailsScreen({super.key, required this.job});

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<SavedJobProvider>().fetchSavedJobs();
      context.read<ApplicationProvider>().fetchApplications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final savedJobProvider = context.watch<SavedJobProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(s.jobDetails),
        actions: [
          IconButton(
            icon: Icon(savedJobProvider.savedJobs.any((j) => j.jobId == widget.job.id)
                ? Icons.bookmark
                : Icons.bookmark_border),
            onPressed: () {
              savedJobProvider.toggleSaveJob(
                jobId: widget.job.id,
                jobTitle: widget.job.title,
                company: widget.job.company,
                location: widget.job.location,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              Text(
                widget.job.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.job.company,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(s.categoryLabel(widget.job.category)),
                    avatar: const Icon(Icons.work, size: 18),
                  ),
                  if (widget.job.jobType != null)
                    Chip(
                      label: Text(s.jobTypeLabel(widget.job.jobType!)),
                    ),
                  Chip(
                    label: Text(widget.job.location),
                    avatar: const Icon(Icons.location_on, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Key information
              _buildInfoRow(
                context,
                icon: Icons.calendar_today,
                label: s.postedDate,
                value: _formatDate(widget.job.postedDate),
              ),
              const SizedBox(height: 12),
              if (widget.job.deadline != null)
                _buildInfoRow(
                  context,
                  icon: Icons.alarm,
                  label: s.deadline(''),
                  value: _formatDate(widget.job.deadline!),
                ),
              if (widget.job.minYearsExperience != null || widget.job.maxYearsExperience != null)
                _buildInfoRow(
                  context,
                  icon: Icons.school,
                  label: s.experience,
                  value: _formatExperience(),
                ),
              if (widget.job.salaryMin != null || widget.job.salaryMax != null)
                _buildInfoRow(
                  context,
                  icon: Icons.attach_money,
                  label: s.salary,
                  value: _formatSalary(),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Description
              Text(
                s.description,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Text(widget.job.description),
              const SizedBox(height: 16),

              // Required skills
              if (widget.job.requiredSkills != null && widget.job.requiredSkills!.isNotEmpty) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  s.requiredSkills,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.job.requiredSkills!
                      .map((skill) => Chip(
                            label: Text(skill),
                            backgroundColor: Colors.blue[100],
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Source information
              _buildInfoRow(
                context,
                icon: Icons.source,
                label: s.source,
                value: widget.job.source,
              ),
              const SizedBox(height: 12),
              if (widget.job.applyLink != null)
                _buildInfoRow(
                  context,
                  icon: Icons.link,
                  label: s.applyLink,
                  value: widget.job.applyLink!,
                  isLink: isWebLink(widget.job.applyLink),
                ),
              const SizedBox(height: 32),

              // Action buttons
              Row(
                children: [
                  if (isWebLink(widget.job.applyLink))
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => openInAppBrowser(context, widget.job.applyLink!),
                        icon: const Icon(Icons.open_in_new),
                        label: Text(s.applyNow),
                      ),
                    ),
                  if (isWebLink(widget.job.applyLink)) const SizedBox(width: 12),
                  if (savedJobProvider.savedJobs.every((j) => j.jobId != widget.job.id))
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          savedJobProvider.saveJob(
                            jobId: widget.job.id,
                            jobTitle: widget.job.title,
                            company: widget.job.company,
                            location: widget.job.location,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(s.jobSaved)),
                          );
                        },
                        icon: const Icon(Icons.bookmark),
                        label: Text(s.saveJob),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _buildApplicationButton(s),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApplicationButton(Strings s) {
    final applications = context.watch<ApplicationProvider>();
    final alreadyApplied = applications.applications.any((a) => a.jobId == widget.job.id);
    if (alreadyApplied) {
      return OutlinedButton.icon(
        onPressed: null,
        icon: const Icon(Icons.check_circle),
        label: Text(s.alreadyInApplications),
      );
    }
    return OutlinedButton.icon(
      onPressed: applications.isLoading
          ? null
          : () async {
              final id = await applications.createApplication(
                jobId: widget.job.id,
                jobTitle: widget.job.title,
                company: widget.job.company,
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(id != null ? s.addedToApplications : s.errorOccurred)),
              );
            },
      icon: const Icon(Icons.playlist_add_check),
      label: Text(s.markApplied),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 4),
              if (isLink)
                LinkText(value)
              else
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatExperience() {
    if (widget.job.minYearsExperience != null && widget.job.maxYearsExperience != null) {
      return '${widget.job.minYearsExperience} - ${widget.job.maxYearsExperience} years';
    }
    return '${widget.job.minYearsExperience ?? widget.job.maxYearsExperience} years';
  }

  String _formatSalary() {
    if (widget.job.salaryMin != null && widget.job.salaryMax != null) {
      return '${widget.job.salaryMin} - ${widget.job.salaryMax}';
    }
    return '${widget.job.salaryMin ?? widget.job.salaryMax}';
  }
}
