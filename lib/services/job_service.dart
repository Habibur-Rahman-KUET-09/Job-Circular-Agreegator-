import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/index.dart';

class JobService {
  final FirebaseFirestore _firestore;

  JobService(this._firestore);

  // Collection references
  CollectionReference<Map<String, dynamic>> get _jobsCollection => _firestore.collection('jobs');

  // Fetch all approved jobs
  Future<List<Job>> getAllJobs() async {
    try {
      final snapshot = await _jobsCollection
          .where('status', isEqualTo: 'approved')
          .orderBy('postedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Job.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs: $e');
    }
  }

  // Search jobs with filters
  Future<List<Job>> searchJobs({
    String? searchTerm,
    String? location,
    String? jobType,
    String? category,
    List<String>? skills,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _jobsCollection.where('status', isEqualTo: 'approved');

      if (location != null && location.isNotEmpty) {
        query = query.where('location', isEqualTo: location);
      }

      if (jobType != null && jobType.isNotEmpty) {
        query = query.where('jobType', isEqualTo: jobType);
      }

      if (category != null && category.isNotEmpty) {
        query = query.where('category', isEqualTo: category);
      }

      final snapshot = await query.orderBy('postedDate', descending: true).get();
      var jobs = snapshot.docs.map((doc) => Job.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();

      // Client-side filtering for search term and skills
      if (searchTerm != null && searchTerm.isNotEmpty) {
        final lowerTerm = searchTerm.toLowerCase();
        jobs = jobs.where((job) {
          return job.title.toLowerCase().contains(lowerTerm) ||
              job.company.toLowerCase().contains(lowerTerm) ||
              job.description.toLowerCase().contains(lowerTerm);
        }).toList();
      }

      if (skills != null && skills.isNotEmpty) {
        jobs = jobs.where((job) {
          return skills.any((skill) =>
              job.requiredSkills.any((required) =>
                  required.toLowerCase().contains(skill.toLowerCase())));
        }).toList();
      }

      return jobs;
    } catch (e) {
      throw Exception('Failed to search jobs: $e');
    }
  }

  // Get job by ID
  Future<Job?> getJobById(String jobId) async {
    try {
      final doc = await _jobsCollection.doc(jobId).get();
      if (doc.exists) {
        await _incrementJobViewCount(jobId);
        return Job.fromJson({
          'id': doc.id,
          ...doc.data()!,
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch job: $e');
    }
  }

  // Get jobs from a specific source
  Future<List<Job>> getJobsByPlatform(String platform) async {
    try {
      final snapshot = await _jobsCollection
          .where('source', isEqualTo: platform)
          .where('status', isEqualTo: 'approved')
          .orderBy('postedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Job.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs from $platform: $e');
    }
  }

  // Get jobs by category
  Future<List<Job>> getJobsByCategory(String category) async {
    try {
      final snapshot = await _jobsCollection
          .where('category', isEqualTo: category)
          .where('status', isEqualTo: 'approved')
          .orderBy('postedDate', descending: true)
          .get();
      return snapshot.docs.map((doc) => Job.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch jobs in category: $e');
    }
  }

  // Get jobs expiring soon (deadline within N days)
  Future<List<Job>> getExpiringJobs({int daysFromNow = 7}) async {
    try {
      final future = DateTime.now().add(Duration(days: daysFromNow));
      final snapshot = await _jobsCollection
          .where('deadline', isLessThanOrEqualTo: future.toIso8601String())
          .where('deadline', isGreaterThanOrEqualTo: DateTime.now().toIso8601String())
          .where('status', isEqualTo: 'approved')
          .orderBy('deadline', descending: false)
          .get();
      return snapshot.docs.map((doc) => Job.fromJson({
        'id': doc.id,
        ...doc.data(),
      })).toList();
    } catch (e) {
      throw Exception('Failed to fetch expiring jobs: $e');
    }
  }

  // Create a new job (admin/scraper only)
  Future<String> createJob(Job job) async {
    try {
      final newJob = job.copyWith(createdAt: DateTime.now());
      await _jobsCollection.doc(job.id).set(newJob.toJson());
      return job.id;
    } catch (e) {
      throw Exception('Failed to create job: $e');
    }
  }

  // Update job
  Future<void> updateJob(String jobId, Map<String, dynamic> updates) async {
    try {
      await _jobsCollection.doc(jobId).update(updates);
    } catch (e) {
      throw Exception('Failed to update job: $e');
    }
  }

  // Increment view count
  Future<void> _incrementJobViewCount(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).update({
        'viewCount': FieldValue.increment(1),
      });
    } catch (e) {
      // Silently fail - don't throw for view count updates
    }
  }

  // Deactivate job (mark as rejected)
  Future<void> deactivateJob(String jobId) async {
    try {
      await _jobsCollection.doc(jobId).update({'status': 'rejected'});
    } catch (e) {
      throw Exception('Failed to deactivate job: $e');
    }
  }

  // Batch create jobs (for scraping/import)
  Future<void> batchCreateJobs(List<Job> jobs) async {
    try {
      final batch = _firestore.batch();
      for (final job in jobs) {
        batch.set(_jobsCollection.doc(job.id), job.toJson());
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch create jobs: $e');
    }
  }

  // Watch jobs in real-time
  Stream<List<Job>> watchJobs() {
    return _jobsCollection
        .where('status', isEqualTo: 'approved')
        .orderBy('postedDate', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Job.fromJson({
              'id': doc.id,
              ...doc.data(),
            })).toList());
  }

  // Watch specific job in real-time
  Stream<Job?> watchJobById(String jobId) {
    return _jobsCollection.doc(jobId).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Job.fromJson({
          'id': snapshot.id,
          ...snapshot.data()!,
        });
      }
      return null;
    });
  }
}
