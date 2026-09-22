import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class ApplicationService {
  final FirebaseFirestore _firestore;

  ApplicationService(this._firestore);

  CollectionReference<Map<String, dynamic>> _applicationsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('applications');

  // Create new application
  Future<String> createApplication({
    required String userId,
    required String jobId,
    required String jobTitle,
    required String company,
    String? coverLetter,
    String? cvUsed,
  }) async {
    try {
      final applicationId = const Uuid().v4();
      final application = Application(
        id: applicationId,
        userId: userId,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        status: ApplicationStatus.submitted,
        appliedDate: DateTime.now(),
        lastUpdated: DateTime.now(),
        coverLetter: coverLetter,
        cvUsed: cvUsed,
      );

      await _applicationsCollection(userId).doc(applicationId).set(application.toJson());

      // Also increment application count in jobs collection
      await _firestore.collection('jobs').doc(jobId).update({
        'applicationCount': FieldValue.increment(1),
      }).catchError((_) {});

      return applicationId;
    } catch (e) {
      throw Exception('Failed to create application: $e');
    }
  }

  // Get application by ID
  Future<Application?> getApplicationById(String userId, String applicationId) async {
    try {
      final doc = await _applicationsCollection(userId).doc(applicationId).get();
      if (doc.exists) {
        return Application.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch application: $e');
    }
  }

  // Get all applications for a user
  Future<List<Application>> getUserApplications(String userId) async {
    try {
      final snapshot = await _applicationsCollection(userId)
          .orderBy('appliedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Application.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch user applications: $e');
    }
  }

  // Get applications by status
  Future<List<Application>> getApplicationsByStatus(
    String userId,
    ApplicationStatus status,
  ) async {
    try {
      final snapshot = await _applicationsCollection(userId)
          .where('status', isEqualTo: status.name)
          .orderBy('appliedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Application.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch applications by status: $e');
    }
  }

  // Update application status
  Future<void> updateApplicationStatus(
    String userId,
    String applicationId,
    ApplicationStatus status,
  ) async {
    try {
      await _applicationsCollection(userId).doc(applicationId).update({
        'status': status.name,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update application status: $e');
    }
  }

  // Update interview details
  Future<void> updateInterviewDetails(
    String userId,
    String applicationId, {
    required DateTime interviewDate,
    required String interviewTime,
    String? interviewLocation,
    String? interviewType,
    String? interviewNotes,
  }) async {
    try {
      await _applicationsCollection(userId).doc(applicationId).update({
        'interviewDate': interviewDate.toIso8601String(),
        'interviewTime': interviewTime,
        'interviewLocation': interviewLocation,
        'interviewType': interviewType,
        'interviewNotes': interviewNotes,
        'status': ApplicationStatus.interviewScheduled.name,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update interview details: $e');
    }
  }

  // Update callback information
  Future<void> updateCallbackInfo(
    String userId,
    String applicationId, {
    String? phone,
    String? email,
    String? website,
  }) async {
    try {
      final updates = <String, dynamic>{
        'lastUpdated': DateTime.now().toIso8601String(),
      };
      if (phone != null) updates['callbackPhone'] = phone;
      if (email != null) updates['callbackEmail'] = email;
      if (website != null) updates['callbackWebsite'] = website;

      await _applicationsCollection(userId).doc(applicationId).update(updates);
    } catch (e) {
      throw Exception('Failed to update callback info: $e');
    }
  }

  // Add notes to application
  Future<void> updateApplicationNotes(
    String userId,
    String applicationId,
    String notes,
  ) async {
    try {
      await _applicationsCollection(userId).doc(applicationId).update({
        'notes': notes,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to update application notes: $e');
    }
  }

  // Record interview outcome
  Future<void> recordInterviewOutcome(
    String userId,
    String applicationId,
    String outcome,
    String? rejectionReason,
  ) async {
    try {
      final status = outcome == 'selected'
          ? ApplicationStatus.selected
          : outcome == 'rejected'
              ? ApplicationStatus.rejected
              : ApplicationStatus.interviewed;

      await _applicationsCollection(userId).doc(applicationId).update({
        'status': status.name,
        'outcome': outcome,
        'rejectionReason': rejectionReason,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to record interview outcome: $e');
    }
  }

  // Withdraw application
  Future<void> withdrawApplication(String userId, String applicationId) async {
    try {
      await _applicationsCollection(userId).doc(applicationId).update({
        'status': ApplicationStatus.withdrawn.name,
        'lastUpdated': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to withdraw application: $e');
    }
  }

  // Check if user already applied for a job
  Future<bool> hasApplied(String userId, String jobId) async {
    try {
      final snapshot = await _applicationsCollection(userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get application statistics for user
  Future<Map<String, int>> getApplicationStats(String userId) async {
    try {
      final allApps = await getUserApplications(userId);
      final stats = <String, int>{};

      for (final status in ApplicationStatus.values) {
        stats[status.name] = allApps.where((a) => a.status == status).length;
      }

      return stats;
    } catch (e) {
      throw Exception('Failed to fetch application statistics: $e');
    }
  }

  // Watch user applications in real-time
  Stream<List<Application>> watchUserApplications(String userId) {
    return _applicationsCollection(userId)
        .orderBy('appliedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Application.fromJson(doc.data())).toList());
  }

  // Watch specific application in real-time
  Stream<Application?> watchApplicationById(String userId, String applicationId) {
    return _applicationsCollection(userId)
        .doc(applicationId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists) {
        return Application.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  // Delete application
  Future<void> deleteApplication(String userId, String applicationId) async {
    try {
      await _applicationsCollection(userId).doc(applicationId).delete();
    } catch (e) {
      throw Exception('Failed to delete application: $e');
    }
  }
}
