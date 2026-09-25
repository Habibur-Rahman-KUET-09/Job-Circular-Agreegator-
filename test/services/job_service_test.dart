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

  test('approveJobs publishes every given job', () async {
    await service.approveJobs(['old', 'new']);
    final pending = await service.watchPendingJobs().first;
    expect(pending, isEmpty);
    final doc = await firestore.collection('jobs').doc('old').get();
    expect(doc.data()!['status'], 'approved');
  });

  test('submitManualJob stores a pending manual job under its generated id', () async {
    final id = await service.submitManualJob(Job(
      id: '',
      title: 'Clerk',
      company: 'Acme Ltd',
      description: 'Filing',
      location: 'Dhaka',
      category: JobCategory.other,
      source: 'ignored',
      sourceType: JobSourceType.scraped,
      postedDate: DateTime.utc(2020),
      status: JobStatus.approved,
      createdAt: DateTime.utc(2020),
      postedBy: 'uid-1',
    ));

    final data = (await firestore.collection('jobs').doc(id).get()).data()!;
    expect(data['id'], id);
    expect(data['status'], 'pending');
    expect(data['sourceType'], 'manual');
    expect(data['source'], 'manual');
    expect(data['postedBy'], 'uid-1');
    final pending = await service.watchPendingJobs().first;
    expect(pending.map((j) => j.id), contains(id));
  });

  test('setJobStatus can reject a job', () async {
    await service.setJobStatus('old', JobStatus.rejected);
    final doc = await firestore.collection('jobs').doc('old').get();
    expect(doc.data()!['status'], 'rejected');
  });
}
