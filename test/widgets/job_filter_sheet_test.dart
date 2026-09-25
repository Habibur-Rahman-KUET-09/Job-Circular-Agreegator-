import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/models/job_filter.dart';
import 'package:job_circular_aggregator/widgets/job_filter_sheet.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Job _job(String id, JobType type, {int? minYears}) => Job(
      id: id,
      title: 'Job $id',
      company: 'Acme',
      description: '',
      location: 'Banani',
      category: JobCategory.it,
      jobType: type,
      minYearsExperience: minYears,
      source: 'bdjobs',
      sourceType: JobSourceType.scraped,
      postedDate: DateTime.now(),
      deadline: DateTime.now().add(const Duration(days: 30)),
      status: JobStatus.approved,
      createdAt: DateTime.now(),
    );

void main() {
  testWidgets('choices update the live count and are returned on apply', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 2.5;
    addTearDown(tester.view.reset);
    final locale = LocaleProvider();
    await locale.setLanguage(AppLanguage.en);
    final jobs = [
      _job('1', JobType.fullTime, minYears: 5),
      _job('2', JobType.internship),
      _job('3', JobType.internship, minYears: 1),
    ];
    JobFilter? result;

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: locale,
      child: MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await showJobFilterSheet(context, filter: const JobFilter(), jobs: jobs),
            child: const Text('open'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Show 3 jobs'), findsOneWidget);

    await tester.tap(find.text('Internship'));
    await tester.pump();
    expect(find.text('Show 2 jobs'), findsOneWidget);

    await tester.tap(find.text('Fresher'));
    await tester.pump();
    expect(find.text('Show 1 jobs'), findsOneWidget);

    await tester.tap(find.text('Show 1 jobs'));
    await tester.pumpAndSettle();
    expect(result!.jobTypes, {JobType.internship});
    expect(result!.maxExperience, 0);
    expect(result!.sheetFilterCount, 2);
  });
}
