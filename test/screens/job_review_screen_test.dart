import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/screens/job_review_screen.dart';
import 'package:job_circular_aggregator/services/job_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Job _job(String id, String title) => Job(
      id: id,
      title: title,
      company: 'Acme Ltd',
      description: 'A job',
      location: 'Dhaka',
      category: JobCategory.it,
      source: 'bdjobs',
      sourceType: JobSourceType.scraped,
      postedDate: DateTime.utc(2026, 9, 1),
      status: JobStatus.pending,
      createdAt: DateTime.utc(2026, 9, 1),
    );

class _FakeJobService extends JobService {
  final List<Job> pending;
  final List<(String, JobStatus)> statusChanges = [];
  final _controller = StreamController<List<Job>>.broadcast();

  _FakeJobService(this.pending) : super(FakeFirebaseFirestore());

  @override
  Stream<List<Job>> watchPendingJobs() async* {
    yield List.of(pending);
    yield* _controller.stream;
  }

  @override
  Future<void> approveJobs(List<String> jobIds) async {
    for (final id in jobIds) {
      statusChanges.add((id, JobStatus.approved));
    }
    pending.removeWhere((j) => jobIds.contains(j.id));
    _controller.add(List.of(pending));
  }

  @override
  Future<void> setJobStatus(String jobId, JobStatus status) async {
    statusChanges.add((jobId, status));
    pending.removeWhere((j) => j.id == jobId);
    _controller.add(List.of(pending));
  }
}

Future<void> _pumpScreen(WidgetTester tester, JobService service) async {
  SharedPreferences.setMockInitialValues({});
  final locale = LocaleProvider();
  await locale.setLanguage(AppLanguage.en);
  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: locale,
      child: MaterialApp(home: JobReviewScreen(jobService: service)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows each pending job with approve and reject buttons', (tester) async {
    await _pumpScreen(tester, _FakeJobService([_job('1', 'Flutter Developer'), _job('2', 'Accountant')]));

    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Accountant'), findsOneWidget);
    expect(find.text('Approve'), findsNWidgets(2));
    expect(find.text('Reject'), findsNWidgets(2));
  });

  testWidgets('approve marks the job approved and removes it', (tester) async {
    final service = _FakeJobService([_job('1', 'Flutter Developer')]);
    await _pumpScreen(tester, service);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    expect(service.statusChanges, [('1', JobStatus.approved)]);
    expect(find.text('Flutter Developer'), findsNothing);
    expect(find.text('Job approved'), findsOneWidget);
    expect(find.text('No jobs waiting for review'), findsOneWidget);
  });

  testWidgets('reject marks the job rejected', (tester) async {
    final service = _FakeJobService([_job('1', 'Flutter Developer')]);
    await _pumpScreen(tester, service);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(service.statusChanges, [('1', JobStatus.rejected)]);
    expect(find.text('Job rejected'), findsOneWidget);
  });

  testWidgets('approve all asks first, then approves every pending job', (tester) async {
    final service = _FakeJobService([_job('1', 'Flutter Developer'), _job('2', 'Accountant')]);
    await _pumpScreen(tester, service);

    await tester.tap(find.text('Approve all'));
    await tester.pumpAndSettle();
    expect(find.text('Approve all jobs?'), findsOneWidget);
    expect(service.statusChanges, isEmpty);

    await tester.tap(find.widgetWithText(FilledButton, 'Approve all'));
    await tester.pumpAndSettle();

    expect(service.statusChanges, [('1', JobStatus.approved), ('2', JobStatus.approved)]);
    expect(find.text('2 jobs approved'), findsOneWidget);
    expect(find.text('Approve all'), findsNothing);
  });

  testWidgets('cancelling approve all changes nothing', (tester) async {
    final service = _FakeJobService([_job('1', 'Flutter Developer')]);
    await _pumpScreen(tester, service);

    await tester.tap(find.text('Approve all'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(service.statusChanges, isEmpty);
    expect(find.text('Flutter Developer'), findsOneWidget);
  });

  testWidgets('shows an empty state when nothing is pending', (tester) async {
    await _pumpScreen(tester, _FakeJobService([]));
    expect(find.text('No jobs waiting for review'), findsOneWidget);
  });
}
