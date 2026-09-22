import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/index.dart';

class SavedJobProvider extends ChangeNotifier {
  final SavedJobService _savedJobService;
  final String userId;

  SavedJobProvider(this._savedJobService, this.userId);

  List<SavedJob> _savedJobs = [];
  bool _isLoading = false;
  String? _error;

  List<SavedJob> get savedJobs => _savedJobs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get savedJobCount => _savedJobs.length;

  // Fetch all saved jobs
  Future<void> fetchSavedJobs() async {
    _setLoading(true);
    _setError(null);
    try {
      _savedJobs = await _savedJobService.getSavedJobs(userId);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Save a job
  Future<bool> saveJob({
    required String jobId,
    required String jobTitle,
    required String company,
    required String location,
    String? notes,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _savedJobService.saveJob(
        userId: userId,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        location: location,
        notes: notes,
      );
      await fetchSavedJobs();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove saved job
  Future<bool> removeSavedJob(String savedJobId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _savedJobService.removeSavedJob(userId, savedJobId);
      await fetchSavedJobs();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Remove by job ID
  Future<bool> removeSavedJobByJobId(String jobId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _savedJobService.removeSavedJobByJobId(userId, jobId);
      await fetchSavedJobs();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Check if job is saved
  Future<bool> isJobSaved(String jobId) async {
    try {
      return await _savedJobService.isJobSaved(userId, jobId);
    } catch (e) {
      return false;
    }
  }

  // Get saved job by job ID
  Future<SavedJob?> getSavedJobByJobId(String jobId) async {
    try {
      return await _savedJobService.getSavedJobByJobId(userId, jobId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Update notes
  Future<bool> updateNotes(String savedJobId, String notes) async {
    _setLoading(true);
    _setError(null);
    try {
      await _savedJobService.updateSavedJobNotes(userId, savedJobId, notes);
      await fetchSavedJobs();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Toggle save status
  Future<bool> toggleSaveJob({
    required String jobId,
    required String jobTitle,
    required String company,
    required String location,
  }) async {
    final isSaved = await isJobSaved(jobId);
    if (isSaved) {
      return removeSavedJobByJobId(jobId);
    } else {
      return saveJob(
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        location: location,
      );
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }
}
