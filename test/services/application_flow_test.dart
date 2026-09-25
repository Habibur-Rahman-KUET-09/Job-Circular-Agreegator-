import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/application.dart';
import 'package:job_circular_aggregator/providers/application_provider.dart';
import 'package:job_circular_aggregator/providers/saved_job_provider.dart';
import 'package:job_circular_aggregator/services/application_service.dart';
import 'package:job_circular_aggregator/services/saved_job_service.dart';

void main() {
  test('adding a job to my applications makes it show up as submitted', () async {
    final firestore = FakeFirebaseFirestore();
    final provider = ApplicationProvider(ApplicationService(firestore), 'uid-1');

    final id = await provider.createApplication(jobId: 'job-1', jobTitle: 'Accountant', company: 'Acme Ltd');

    expect(id, isNotNull);
    expect(provider.applications.map((a) => a.jobId), ['job-1']);
    expect(provider.applications.single.status, ApplicationStatus.submitted);
    final stored = await firestore.collection('users').doc('uid-1').collection('applications').get();
    expect(stored.docs, hasLength(1));
  });

  test('saved jobs are loaded so the details page knows a job is already saved', () async {
    final firestore = FakeFirebaseFirestore();
    await SavedJobProvider(SavedJobService(firestore), 'uid-1')
        .saveJob(jobId: 'job-1', jobTitle: 'Accountant', company: 'Acme Ltd', location: 'Dhaka');

    final fresh = SavedJobProvider(SavedJobService(firestore), 'uid-1');
    expect(fresh.savedJobs, isEmpty);
    await fresh.fetchSavedJobs();
    expect(fresh.savedJobs.map((j) => j.jobId), ['job-1']);
  });
}
