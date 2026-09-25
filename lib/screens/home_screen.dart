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
import '../utils/safe_padding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JobCategory? _selectedCategory;
  String? _selectedLocation;
  String? _searchTerm;
  late String userId;

  @override
  void initState() {
    super.initState();
    userId = AuthService.instance.currentUser?.uid ?? '';
    Future.microtask(() {
      context.read<JobProvider>().fetchAllJobs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    final isLoading = context.watch<JobProvider>().isLoading;
    final jobs = context.watch<JobProvider>().jobs;
    final error = context.watch<JobProvider>().error;

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
      body: isLoading && jobs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && jobs.isEmpty
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
                          context.read<JobProvider>().fetchAllJobs();
                        },
                        child: Text(s.retry),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refresh,
                  child: jobs.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const SizedBox(height: 120),
                            Center(child: Text(s.noJobsFound)),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: jobs.length,
                          padding: safeBodyPadding(context, amount: 8, fab: true),
                          itemBuilder: (context, index) {
                            final job = jobs[index];
                            return JobCard(
                              job: job,
                              onTap: () => _navigateToJobDetails(context, job),
                            );
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        tooltip: s.filterJobs,
        child: const Icon(Icons.filter_list),
      ),
    );
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

  Future<void> _refresh() {
    final provider = context.read<JobProvider>();
    final filtered = _searchTerm != null || _selectedLocation != null || _selectedCategory != null;
    if (!filtered) return provider.fetchAllJobs();
    return provider.searchJobs(
      searchTerm: _searchTerm,
      location: _selectedLocation,
      category: _selectedCategory?.name,
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => FilterDialog(
        selectedCategory: _selectedCategory,
        selectedLocation: _selectedLocation,
        searchTerm: _searchTerm,
        onApply: (category, location, searchTerm) {
          setState(() {
            _selectedCategory = category;
            _selectedLocation = location;
            _searchTerm = searchTerm;
          });
          // Apply filters via provider
          context.read<JobProvider>().searchJobs(
            searchTerm: searchTerm,
            location: location,
            category: category?.name,
          );
          Navigator.pop(context);
        },
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
              if (job.deadline != null)
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      s.deadline(_formatDate(job.deadline!)),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class FilterDialog extends StatefulWidget {
  final JobCategory? selectedCategory;
  final String? selectedLocation;
  final String? searchTerm;
  final Function(JobCategory?, String?, String?) onApply;

  const FilterDialog({
    super.key,
    this.selectedCategory,
    this.selectedLocation,
    this.searchTerm,
    required this.onApply,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late JobCategory? _category;
  late String? _location;
  late String? _searchTerm;
  late TextEditingController _searchController;
  late TextEditingController _locationController;

  @override
  void initState() {
    super.initState();
    _category = widget.selectedCategory;
    _location = widget.selectedLocation;
    _searchTerm = widget.searchTerm;
    _searchController = TextEditingController(text: _searchTerm ?? '');
    _locationController = TextEditingController(text: _location ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = Strings.of(context);
    return AlertDialog(
      title: Text(s.filterJobs),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.search),
            const SizedBox(height: 8),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: s.searchJobsHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _searchTerm = value.isEmpty ? null : value,
            ),
            const SizedBox(height: 16),
            Text(s.category),
            const SizedBox(height: 8),
            DropdownButton<JobCategory>(
              value: _category,
              isExpanded: true,
              items: JobCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text(s.categoryLabel(cat)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value),
            ),
            const SizedBox(height: 16),
            Text(s.location),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: s.locationHint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) => _location = value.isEmpty ? null : value,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: () => widget.onApply(_category, _location, _searchTerm),
          child: Text(s.apply),
        ),
      ],
    );
  }
}
