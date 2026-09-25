import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../models/job_filter.dart';
import '../services/index.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService;

  JobProvider(this._jobService);

  List<Job> _jobs = [];
  List<Job> _visibleJobs = [];
  Job? _selectedJob;
  bool _isLoading = false;
  String? _error;
  JobFilter _filter = const JobFilter();

  /// Every loaded job, before filtering.
  List<Job> get allJobs => _jobs;

  /// The loaded jobs that match [filter], in its sort order.
  List<Job> get jobs => _visibleJobs;
  Job? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;
  JobFilter get filter => _filter;

  Map<JobCategory, int> get categoryCounts => _filter.categoryCounts(_jobs);

  // Fetch all jobs
  Future<void> fetchAllJobs() async {
    _setLoading(true);
    _setError(null);
    try {
      _setJobs(await _jobService.getAllJobs());
    } catch (e) {
      _setError(e.toString());
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  void setFilter(JobFilter filter) {
    _filter = filter;
    _visibleJobs = _filter.apply(_jobs);
    notifyListeners();
  }

  void clearFilters() => setFilter(const JobFilter());

  void _setJobs(List<Job> jobs) {
    _jobs = jobs;
    _visibleJobs = _filter.apply(_jobs);
    notifyListeners();
  }

  // Get job by ID and set as selected
  Future<void> selectJob(String jobId) async {
    _setLoading(true);
    _setError(null);
    try {
      _selectedJob = await _jobService.getJobById(jobId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Clear selected job
  void clearSelectedJob() {
    _selectedJob = null;
    notifyListeners();
  }

  // Get jobs by platform
  Future<void> fetchJobsByPlatform(String platform) async {
    _setLoading(true);
    _setError(null);
    try {
      _setJobs(await _jobService.getJobsByPlatform(platform));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get jobs by category
  Future<void> fetchJobsByCategory(String category) async {
    _setLoading(true);
    _setError(null);
    try {
      _setJobs(await _jobService.getJobsByCategory(category));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Get expiring jobs
  Future<void> fetchExpiringJobs({int daysFromNow = 7}) async {
    _setLoading(true);
    _setError(null);
    try {
      _setJobs(await _jobService.getExpiringJobs(daysFromNow: daysFromNow));
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }
}
