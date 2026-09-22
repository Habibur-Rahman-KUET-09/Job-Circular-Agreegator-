import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/index.dart';

class JobProvider extends ChangeNotifier {
  final JobService _jobService;

  JobProvider(this._jobService);

  List<Job> _jobs = [];
  List<Job> _filteredJobs = [];
  Job? _selectedJob;
  bool _isLoading = false;
  String? _error;

  List<Job> get jobs => _filteredJobs.isEmpty ? _jobs : _filteredJobs;
  Job? get selectedJob => _selectedJob;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Current filter state
  String? _searchTerm;
  String? _selectedLocation;
  String? _selectedJobType;
  String? _selectedCategory;
  List<String>? _selectedSkills;

  String? get searchTerm => _searchTerm;
  String? get selectedLocation => _selectedLocation;
  String? get selectedJobType => _selectedJobType;
  String? get selectedCategory => _selectedCategory;
  List<String>? get selectedSkills => _selectedSkills;

  // Fetch all jobs
  Future<void> fetchAllJobs() async {
    _setLoading(true);
    _setError(null);
    try {
      _jobs = await _jobService.getAllJobs();
      _filteredJobs = _jobs;
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Search and filter jobs
  Future<void> searchJobs({
    String? searchTerm,
    String? location,
    String? jobType,
    String? category,
    List<String>? skills,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      _searchTerm = searchTerm;
      _selectedLocation = location;
      _selectedJobType = jobType;
      _selectedCategory = category;
      _selectedSkills = skills;

      _filteredJobs = await _jobService.searchJobs(
        searchTerm: searchTerm,
        location: location,
        jobType: jobType,
        category: category,
        skills: skills,
      );
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Clear filters
  Future<void> clearFilters() async {
    _searchTerm = null;
    _selectedLocation = null;
    _selectedJobType = null;
    _selectedCategory = null;
    _selectedSkills = null;
    _filteredJobs = _jobs;
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
      _jobs = await _jobService.getJobsByPlatform(platform);
      _filteredJobs = _jobs;
      notifyListeners();
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
      _jobs = await _jobService.getJobsByCategory(category);
      _filteredJobs = _jobs;
      notifyListeners();
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
      _jobs = await _jobService.getExpiringJobs(daysFromNow: daysFromNow);
      _filteredJobs = _jobs;
      notifyListeners();
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
