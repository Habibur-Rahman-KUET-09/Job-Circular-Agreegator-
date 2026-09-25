import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/job.dart';
import '../providers/application_provider.dart';
import '../providers/job_provider.dart';
import '../providers/saved_job_provider.dart';
import '../services/application_service.dart';
import '../services/auth_service.dart';
import '../services/saved_job_service.dart';
import 'account_screen.dart';
import 'job_details_screen.dart';
import '../widgets/job_filter_sheet.dart';
import '../utils/safe_padding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _search = TextEditingController();
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = AuthService.instance.currentUser?.uid ?? '';
    _search.text = context.read<JobProvider>().filter.query;
    Future.microtask(() {
      if (mounted) context.read<JobProvider>().fetchAllJobs();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final provider = context.watch<JobProvider>();
    final jobs = provider.jobs;
    final filter = provider.filter;

    return Scaffold(
      appBar: AppBar(
        title: Text(s.appTitle),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: s.loginAccount,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AccountScreen()),
            ),
          ),
        ],
      ),
      body: provider.isLoading && provider.allJobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : provider.error != null && provider.allJobs.isEmpty
              ? _ErrorView(onRetry: () => context.read<JobProvider>().fetchAllJobs())
              : Column(
                  children: [
                    _SearchRow(
                      controller: _search,
                      activeFilters: filter.sheetFilterCount,
                      onChanged: (q) => provider.setFilter(filter.copyWith(query: q)),
                      onClear: () {
                        _search.clear();
                        provider.setFilter(filter.copyWith(query: ''));
                      },
                      onOpenFilters: _openFilters,
                    ),
                    _CategoryBar(
                      selected: filter.category,
                      counts: provider.categoryCounts,
                      onSelected: (c) => provider.setFilter(filter.copyWith(category: () => c)),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(s.jobCount(jobs.length), style: Theme.of(context).textTheme.bodySmall),
                          ),
                          if (!filter.isDefault)
                            TextButton.icon(
                              onPressed: () {
                                _search.clear();
                                provider.clearFilters();
                              },
                              icon: const Icon(Icons.filter_alt_off, size: 18),
                              label: Text(s.clearFilters),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () => context.read<JobProvider>().fetchAllJobs(),
                        child: jobs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(32),
                                children: [
                                  const SizedBox(height: 80),
                                  Text(
                                    filter.isDefault ? s.noJobsFound : s.noJobsMatchFilters,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            : ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: jobs.length,
                                padding: safeBodyPadding(context, amount: 8).copyWith(top: 0),
                                itemBuilder: (context, index) {
                                  final job = jobs[index];
                                  return JobCard(
                                    job: job,
                                    onTap: () => _navigateToJobDetails(context, job),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _openFilters() async {
    final provider = context.read<JobProvider>();
    final result = await showJobFilterSheet(context, filter: provider.filter, jobs: provider.allJobs);
    if (result != null && mounted) provider.setFilter(result);
  }

  void _navigateToJobDetails(BuildContext context, Job job) {
    final firestore = FirebaseFirestore.instance;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => SavedJobProvider(SavedJobService(firestore), userId),
            ),
            ChangeNotifierProvider(
              create: (_) => ApplicationProvider(ApplicationService(firestore), userId),
            ),
          ],
          child: JobDetailsScreen(job: job),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorView({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(s.errorOccurred),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: Text(s.retry)),
        ],
      ),
    );
  }
}

class _SearchRow extends StatelessWidget {
  final TextEditingController controller;
  final int activeFilters;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onOpenFilters;

  const _SearchRow({
    required this.controller,
    required this.activeFilters,
    required this.onChanged,
    required this.onClear,
    required this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: s.searchJobsField,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controller,
                  builder: (_, value, _) => value.text.isEmpty
                      ? const SizedBox.shrink()
                      : IconButton(icon: const Icon(Icons.clear), onPressed: onClear),
                ),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: s.filters,
            onPressed: onOpenFilters,
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.tune),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final JobCategory? selected;
  final Map<JobCategory, int> counts;
  final ValueChanged<JobCategory?> onSelected;

  const _CategoryBar({required this.selected, required this.counts, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    // Busiest categories first; the selected one stays even at zero.
    final categories = JobCategory.values
        .where((c) => (counts[c] ?? 0) > 0 || c == selected)
        .toList()
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    Widget chip(String label, int count, bool isSelected, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text('$label (${s.number(count)})'),
            selected: isSelected,
            onSelected: (_) => onTap(),
          ),
        );

    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          chip(s.allCategories, total, selected == null, () => onSelected(null)),
          for (final c in categories)
            chip(s.categoryLabel(c), counts[c] ?? 0, c == selected, () => onSelected(c == selected ? null : c)),
        ],
      ),
    );
  }
}

class JobCard extends StatelessWidget {
  final Job job;
  final VoidCallback onTap;

  const JobCard({
    super.key,
    required this.job,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final daysAgo = DateTime.now().difference(job.postedDate).inDays;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: InkWell(
        onTap: onTap,
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
                          job.title,
                          style: Theme.of(context).textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          job.company,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(Strings.of(context).categoryLabel(job.category)),
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
                      job.location,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (job.deadline != null) _DeadlineRow(deadline: job.deadline!),
              if (job.jobType != null || _salary(job) != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          [if (job.jobType != null) s.jobTypeLabel(job.jobType!), ?_salary(job)].join(' · '),
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    s.postedTime(daysAgo),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${job.viewCount}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String? _salary(Job job) {
    final salary = (job.salaryMin ?? job.salaryMax ?? '').trim();
    return salary.isEmpty ? null : salary;
  }
}

class _DeadlineRow extends StatelessWidget {
  final DateTime deadline;

  const _DeadlineRow({required this.deadline});

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final theme = Theme.of(context);
    final now = DateTime.now();
    final local = deadline.toLocal();
    final days = DateTime(local.year, local.month, local.day).difference(DateTime(now.year, now.month, now.day)).inDays;
    final urgent = days <= 3;
    final color = urgent ? theme.colorScheme.error : Colors.grey[600];
    final date = '${s.number(local.day)}/${s.number(local.month)}/${s.number(local.year)}';
    return Row(
      children: [
        Icon(Icons.calendar_today, size: 16, color: color),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${s.deadline(date)} · ${days < 0 ? s.expired : s.daysLeft(days)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: urgent ? theme.colorScheme.error : null,
              fontWeight: urgent ? FontWeight.w600 : null,
            ),
          ),
        ),
      ],
    );
  }
}
