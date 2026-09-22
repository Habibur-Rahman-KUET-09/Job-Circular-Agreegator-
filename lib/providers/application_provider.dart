import 'package:flutter/foundation.dart';
import '../models/index.dart';
import '../services/index.dart';

class ApplicationProvider extends ChangeNotifier {
  final ApplicationService _applicationService;
  final String userId;

  ApplicationProvider(this._applicationService, this.userId);

  List<Application> _applications = [];
  Map<String, int> _statusCounts = {};
  bool _isLoading = false;
  String? _error;

  List<Application> get applications => _applications;
  Map<String, int> get statusCounts => _statusCounts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalApplications => _applications.length;
  int get successCount => (_applications
          .where((a) =>
              a.status == ApplicationStatus.selected ||
              a.status == ApplicationStatus.interviewed)
          .length);

  // Fetch all applications
  Future<void> fetchApplications() async {
    _setLoading(true);
    _setError(null);
    try {
      _applications = await _applicationService.getUserApplications(userId);
      await _calculateStatusCounts();
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Create application
  Future<String?> createApplication({
    required String jobId,
    required String jobTitle,
    required String company,
    String? coverLetter,
    String? cvUsed,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final appId = await _applicationService.createApplication(
        userId: userId,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        coverLetter: coverLetter,
        cvUsed: cvUsed,
      );
      await fetchApplications();
      return appId;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Update application status
  Future<void> updateStatus(
    String applicationId,
    ApplicationStatus status,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.updateApplicationStatus(userId, applicationId, status);
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Schedule interview
  Future<void> scheduleInterview(
    String applicationId, {
    required DateTime interviewDate,
    required String interviewTime,
    String? interviewLocation,
    String? interviewType,
    String? interviewNotes,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.updateInterviewDetails(
        userId,
        applicationId,
        interviewDate: interviewDate,
        interviewTime: interviewTime,
        interviewLocation: interviewLocation,
        interviewType: interviewType,
        interviewNotes: interviewNotes,
      );
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Update callback info
  Future<void> updateCallbackInfo(
    String applicationId, {
    String? phone,
    String? email,
    String? website,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.updateCallbackInfo(
        userId,
        applicationId,
        phone: phone,
        email: email,
        website: website,
      );
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Add notes
  Future<void> addNotes(String applicationId, String notes) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.updateApplicationNotes(userId, applicationId, notes);
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Record outcome
  Future<void> recordOutcome(
    String applicationId,
    String outcome,
    String? rejectionReason,
  ) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.recordInterviewOutcome(
        userId,
        applicationId,
        outcome,
        rejectionReason,
      );
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Withdraw application
  Future<void> withdrawApplication(String applicationId) async {
    _setLoading(true);
    _setError(null);
    try {
      await _applicationService.withdrawApplication(userId, applicationId);
      await fetchApplications();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Check if already applied
  Future<bool> hasApplied(String jobId) async {
    try {
      return await _applicationService.hasApplied(userId, jobId);
    } catch (e) {
      return false;
    }
  }

  // Get applications by status
  Future<List<Application>> getByStatus(ApplicationStatus status) async {
    try {
      return await _applicationService.getApplicationsByStatus(userId, status);
    } catch (e) {
      _setError(e.toString());
      return [];
    }
  }

  Future<void> _calculateStatusCounts() async {
    try {
      _statusCounts = await _applicationService.getApplicationStats(userId);
    } catch (e) {
      _statusCounts = {};
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
  }

  void _setError(String? error) {
    _error = error;
  }
}
