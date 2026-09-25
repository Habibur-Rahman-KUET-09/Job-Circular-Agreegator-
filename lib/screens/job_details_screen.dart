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
    final theme = Theme.of(context);
    final job = widget.job;
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              if (isWebLink(job.applyLink)) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => openInAppBrowser(context, job.applyLink!),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(s.applyNow),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(child: _buildApplicationButton(s)),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(job.title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(job.company, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(label: Text(s.categoryLabel(job.category)), avatar: const Icon(Icons.work, size: 18)),
                if (job.jobType != null) Chip(label: Text(s.jobTypeLabel(job.jobType!))),
                Chip(
                  label: Text(job.locationDetail ?? job.location),
                  avatar: const Icon(Icons.location_on, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (job.deadline != null)
                      _buildInfoRow(context, icon: Icons.alarm, label: s.deadline('').replaceAll(':', '').trim(),
                          value: _deadlineText(s, job.deadline!), highlight: _daysLeft(job.deadline!) <= 3),
                    _buildInfoRow(context, icon: Icons.calendar_today, label: s.postedDate,
                        value: _formatDate(s, job.postedDate)),
                    if (job.vacancies != null)
                      _buildInfoRow(context, icon: Icons.groups_outlined, label: s.vacancies, value: job.vacancies!),
                    if (job.minYearsExperience != null || job.maxYearsExperience != null)
                      _buildInfoRow(context, icon: Icons.school, label: s.experience,
                          value: s.yearsRange(job.minYearsExperience, job.maxYearsExperience)),
                    if ((job.salaryMin ?? job.salaryMax ?? '').trim().isNotEmpty)
                      _buildInfoRow(context, icon: Icons.payments_outlined, label: s.salary, value: _formatSalary()),
                    if (job.workplace != null)
                      _buildInfoRow(context, icon: Icons.apartment, label: s.workplace, value: job.workplace!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            ..._buildCircular(context, s),
            if (job.requiredSkills != null && job.requiredSkills!.isNotEmpty) ...[
              _sectionTitle(context, s.requiredSkills),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [for (final skill in job.requiredSkills!) Chip(label: Text(skill))],
              ),
            ],
            if (job.companyAddress != null || isWebLink(job.companyWebsite)) ...[
              const SizedBox(height: 8),
              if (job.companyAddress != null)
                _buildInfoRow(context, icon: Icons.place_outlined, label: s.companyAddress, value: job.companyAddress!),
              if (isWebLink(job.companyWebsite))
                _buildInfoRow(context, icon: Icons.language, label: s.website, value: job.companyWebsite!, isLink: true),
            ],
            const Divider(height: 32),
            _buildInfoRow(context, icon: Icons.source, label: s.source, value: job.source),
            if (job.applyLink != null)
              _buildInfoRow(context, icon: Icons.link, label: s.applyLink, value: job.applyLink!,
                  isLink: isWebLink(job.applyLink)),
            const SizedBox(height: 8),
            if (savedJobProvider.savedJobs.every((j) => j.jobId != job.id))
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    savedJobProvider.saveJob(
                      jobId: job.id,
                      jobTitle: job.title,
                      company: job.company,
                      location: job.location,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.jobSaved)));
                  },
                  icon: const Icon(Icons.bookmark_border),
                  label: Text(s.saveJob),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// The circular's sections in reading order, or the plain description.
  List<Widget> _buildCircular(BuildContext context, Strings s) {
    final job = widget.job;
    const order = ['responsibilities', 'education', 'experience', 'requirements', 'benefits', 'process', 'company'];
    final sections = [
      for (final key in order)
        if (job.details[key] != null) (s.detailSection(key), job.details[key]!),
      for (final entry in job.details.entries)
        if (!order.contains(entry.key)) (s.detailSection(entry.key), entry.value),
    ];
    if (sections.isEmpty && job.description.trim().isNotEmpty) {
      sections.add((s.description, job.description));
    }
    if (sections.isEmpty) {
      return [
        const SizedBox(height: 8),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullCircularOnSite),
                if (isWebLink(job.applyLink))
                  TextButton.icon(
                    onPressed: () => openInAppBrowser(context, job.applyLink!),
                    icon: const Icon(Icons.open_in_new),
                    label: Text(s.viewOriginal),
                  ),
              ],
            ),
          ),
        ),
      ];
    }
    return [
      for (final (title, text) in sections) ...[
        _sectionTitle(context, title),
        SelectableText(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
      ],
    ];
  }

  Widget _sectionTitle(BuildContext context, String title) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      );

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
    bool highlight = false,
  }) {
    final theme = Theme.of(context);
    final color = highlight ? theme.colorScheme.error : Colors.grey[600];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                const SizedBox(height: 2),
                if (isLink)
                  LinkText(value)
                else
                  Text(
                    value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: highlight ? theme.colorScheme.error : null,
                      fontWeight: highlight ? FontWeight.w600 : null,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _daysLeft(DateTime deadline) {
    final now = DateTime.now();
    final d = deadline.toLocal();
    return DateTime(d.year, d.month, d.day).difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  String _deadlineText(Strings s, DateTime deadline) {
    final days = _daysLeft(deadline);
    return '${_formatDate(s, deadline.toLocal())} (${days < 0 ? s.expired : s.daysLeft(days)})';
  }

  String _formatDate(Strings s, DateTime date) => '${s.number(date.day)}/${s.number(date.month)}/${s.number(date.year)}';

  String _formatSalary() {
    if (widget.job.salaryMin != null && widget.job.salaryMax != null) {
      return '${widget.job.salaryMin} - ${widget.job.salaryMax}';
    }
    return '${widget.job.salaryMin ?? widget.job.salaryMax}';
  }
}
