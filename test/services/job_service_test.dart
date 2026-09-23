import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/services/job_service.dart';

Map<String, dynamic> _job(String title, String status, String postedDate) => {
      'title': title,
      'company': 'Acme Ltd',
      'description': 'A job',
      'location': 'Dhaka',
      'category': 'it',
      'source': 'bdjobs',
      'sourceType': 'scraped',
      'postedDate': postedDate,
      'createdAt': postedDate,
      'status': status,
    };

void main() {
  late FakeFirebaseFirestore firestore;
  late JobService service;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = JobService(firestore);
    final jobs = firestore.collection('jobs');
    await jobs.doc('old').set(_job('Older pending', 'pending', '2026-09-01T00:00:00.000Z'));
    await jobs.doc('new').set(_job('Newer pending', 'pending', '2026-09-05T00:00:00.000Z'));
    await jobs.doc('done').set(_job('Approved', 'approved', '2026-09-03T00:00:00.000Z'));
    await jobs.doc('bad').set({
      ..._job('Malformed', 'pending', '2026-09-04T00:00:00.000Z'),
      'category': 'not-a-category',
    });
  });

  test('watchPendingJobs returns only parseable pending jobs, newest first', () async {
    final jobs = await service.watchPendingJobs().first;
    expect(jobs.map((j) => j.title), ['Newer pending', 'Older pending']);
  });

  test('setJobStatus approves a job so it leaves the pending queue', () async {
    await service.setJobStatus('new', JobStatus.approved);

    final doc = await firestore.collection('jobs').doc('new').get();
    expect(doc.data()!['status'], 'approved');
    final pending = await service.watchPendingJobs().first;
    expect(pending.map((j) => j.id), ['old']);
  });

  test('setJobStatus can reject a job', () async {
    await service.setJobStatus('old', JobStatus.rejected);
    final doc = await firestore.collection('jobs').doc('old').get();
    expect(doc.data()!['status'], 'rejected');
  });
}
