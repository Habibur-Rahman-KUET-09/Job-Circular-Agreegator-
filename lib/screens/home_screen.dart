import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/strings.dart';
import '../models/job.dart';
import '../providers/job_provider.dart';
import '../services/auth_service.dart';
import 'auth/login_screen.dart';
import 'job_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  JobCategory? _selectedCategory;
  String? _selectedLocation;
  String? _searchTerm;

  @override
  void initState() {
    super.initState();
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
            onPressed: _showProfileMenu,
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
              : ListView.builder(
                  itemCount: jobs.length,
                  padding: const EdgeInsets.all(8),
                  itemBuilder: (context, index) {
                    final job = jobs[index];
                    return JobCard(
                      job: job,
                      onTap: () => _navigateToJobDetails(context, job),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFilterDialog,
        tooltip: s.filterJobs,
        child: const Icon(Icons.filter_list),
      ),
    );
  }

  void _navigateToJobDetails(BuildContext context, Job job) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JobDetailsScreen(job: job),
      ),
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

  void _showProfileMenu() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: Text(Strings.of(context).myProfile),
              onTap: () {
                Navigator.pop(context);
                // Navigate to profile screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: Text(Strings.of(context).savedJobs),
              onTap: () {
                Navigator.pop(context);
                // Navigate to saved jobs screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.work_history),
              title: Text(Strings.of(context).myApplications),
              onTap: () {
                Navigator.pop(context);
                // Navigate to applications screen
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: Text(Strings.of(context).logout),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(Strings.of(context).confirmLogout),
        content: Text(Strings.of(context).logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(Strings.of(context).cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              AuthService.instance.signOut().then((_) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              });
            },
            child: Text(Strings.of(context).logout),
          ),
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
                    label: Text(job.category.name),
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
                  child: Text(cat.name),
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
