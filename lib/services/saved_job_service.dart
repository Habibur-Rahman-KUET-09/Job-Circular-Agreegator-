import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class SavedJobService {
  final FirebaseFirestore _firestore;

  SavedJobService(this._firestore);

  CollectionReference<Map<String, dynamic>> _savedJobsCollection(String userId) =>
      _firestore.collection('users').doc(userId).collection('savedJobs');

  // Save a job
  Future<String> saveJob({
    required String userId,
    required String jobId,
    required String jobTitle,
    required String company,
    required String location,
    String? notes,
  }) async {
    try {
      final savedJobId = const Uuid().v4();
      final savedJob = SavedJob(
        id: savedJobId,
        userId: userId,
        jobId: jobId,
        jobTitle: jobTitle,
        company: company,
        location: location,
        savedAt: DateTime.now(),
        notes: notes,
      );

      await _savedJobsCollection(userId).doc(savedJobId).set(savedJob.toJson());
      return savedJobId;
    } catch (e) {
      throw Exception('Failed to save job: $e');
    }
  }

  // Get all saved jobs for a user
  Future<List<SavedJob>> getSavedJobs(String userId) async {
    try {
      final snapshot = await _savedJobsCollection(userId)
          .orderBy('savedAt', descending: true)
          .get();
      return snapshot.docs.map((doc) => SavedJob.fromJson(doc.data())).toList();
    } catch (e) {
      throw Exception('Failed to fetch saved jobs: $e');
    }
  }

  // Get saved job by ID
  Future<SavedJob?> getSavedJobById(String userId, String savedJobId) async {
    try {
      final doc = await _savedJobsCollection(userId).doc(savedJobId).get();
      if (doc.exists) {
        return SavedJob.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch saved job: $e');
    }
  }

  // Check if job is saved
  Future<bool> isJobSaved(String userId, String jobId) async {
    try {
      final snapshot = await _savedJobsCollection(userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get the saved job record for a specific job ID
  Future<SavedJob?> getSavedJobByJobId(String userId, String jobId) async {
    try {
      final snapshot = await _savedJobsCollection(userId)
          .where('jobId', isEqualTo: jobId)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return SavedJob.fromJson(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update saved job notes
  Future<void> updateSavedJobNotes(
    String userId,
    String savedJobId,
    String notes,
  ) async {
    try {
      await _savedJobsCollection(userId).doc(savedJobId).update({'notes': notes});
    } catch (e) {
      throw Exception('Failed to update notes: $e');
    }
  }

  // Remove saved job
  Future<void> removeSavedJob(String userId, String savedJobId) async {
    try {
      await _savedJobsCollection(userId).doc(savedJobId).delete();
    } catch (e) {
      throw Exception('Failed to remove saved job: $e');
    }
  }

  // Remove saved job by job ID
  Future<void> removeSavedJobByJobId(String userId, String jobId) async {
    try {
      final savedJob = await getSavedJobByJobId(userId, jobId);
      if (savedJob != null) {
        await removeSavedJob(userId, savedJob.id);
      }
    } catch (e) {
      throw Exception('Failed to remove saved job: $e');
    }
  }

  // Get count of saved jobs
  Future<int> getSavedJobCount(String userId) async {
    try {
      final snapshot = await _savedJobsCollection(userId).count().get();
      return snapshot.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Watch saved jobs in real-time
  Stream<List<SavedJob>> watchSavedJobs(String userId) {
    return _savedJobsCollection(userId)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => SavedJob.fromJson(doc.data())).toList());
  }

  // Watch if a specific job is saved
  Stream<bool> watchIsJobSaved(String userId, String jobId) {
    return _savedJobsCollection(userId)
        .where('jobId', isEqualTo: jobId)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty);
  }
}
