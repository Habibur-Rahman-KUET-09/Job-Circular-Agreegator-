import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/screens/add_job_screen.dart';
import 'package:job_circular_aggregator/services/job_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeJobService extends JobService {
  final submitted = <Job>[];
  _FakeJobService() : super(FakeFirebaseFirestore());

  @override
  Future<String> submitManualJob(Job job) async {
    submitted.add(job);
    return 'new-id';
  }
}

Future<_FakeJobService> _pump(WidgetTester tester, {String? lockedCompany}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final locale = LocaleProvider();
  await locale.setLanguage(AppLanguage.en);
  final service = _FakeJobService();
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: locale,
    child: MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddJobScreen(postedBy: 'uid-1', lockedCompany: lockedCompany, jobService: service),
            )),
            child: const Text('open'),
          ),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return service;
}

Future<void> _fill(WidgetTester tester, String label, String text) async {
  await tester.enterText(find.widgetWithText(TextFormField, label), text);
}

void main() {
  testWidgets('required fields block submission', (tester) async {
    final service = await _pump(tester);
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('This field is required'), findsNWidgets(4));
    expect(service.submitted, isEmpty);
  });

  testWidgets('rejects an apply link that is not a web address', (tester) async {
    final service = await _pump(tester);
    await _fill(tester, 'Job title', 'Accountant');
    await _fill(tester, 'Company', 'Acme Ltd');
    await _fill(tester, 'Location', 'Dhaka');
    await _fill(tester, 'Description', 'Keep the books');
    await _fill(tester, 'Apply Link', 'call 01700000000');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(find.text('Enter a valid link (https://...)'), findsOneWidget);
    expect(service.submitted, isEmpty);
  });

  testWidgets('submits a pending manual job and closes the form', (tester) async {
    final service = await _pump(tester);
    await _fill(tester, 'Job title', 'Accountant');
    await _fill(tester, 'Company', 'Acme Ltd');
    await _fill(tester, 'Location', 'Dhaka');
    await _fill(tester, 'Description', 'Keep the books');
    await _fill(tester, 'Apply Link', 'https://acme.example/jobs/1');
    await _fill(tester, 'Min experience (years)', '2');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(service.submitted, hasLength(1));
    final job = service.submitted.single;
    expect(job.title, 'Accountant');
    expect(job.company, 'Acme Ltd');
    expect(job.status, JobStatus.pending);
    expect(job.sourceType, JobSourceType.manual);
    expect(job.postedBy, 'uid-1');
    expect(job.applyLink, 'https://acme.example/jobs/1');
    expect(job.minYearsExperience, 2);
    expect(find.text('Submit for review'), findsNothing);
    expect(find.text('Job submitted; everyone will see it once approved'), findsOneWidget);
  });

  testWidgets('recruiters post under their own company', (tester) async {
    final service = await _pump(tester, lockedCompany: 'Recruit Co');
    final company = tester.widget<TextField>(
      find.descendant(of: find.widgetWithText(TextFormField, 'Company'), matching: find.byType(TextField)),
    );
    expect(company.readOnly, isTrue);
    expect(company.controller!.text, 'Recruit Co');

    await _fill(tester, 'Job title', 'Sales Officer');
    await _fill(tester, 'Location', 'Khulna');
    await _fill(tester, 'Description', 'Sell things');
    await tester.tap(find.text('Submit for review'));
    await tester.pumpAndSettle();

    expect(service.submitted.single.company, 'Recruit Co');
  });
}
