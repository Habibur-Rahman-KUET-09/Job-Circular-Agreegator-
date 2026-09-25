import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/providers/application_provider.dart';
import 'package:job_circular_aggregator/providers/saved_job_provider.dart';
import 'package:job_circular_aggregator/screens/job_details_screen.dart';
import 'package:job_circular_aggregator/services/application_service.dart';
import 'package:job_circular_aggregator/services/saved_job_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Job _job({Map<String, String> details = const {}, String description = ''}) => Job(
      id: 'j1',
      title: 'Senior Sales Executive',
      company: 'Almadina Abason',
      description: description,
      location: 'Mirpur 2',
      locationDetail: 'Dhaka (Mirpur 2)',
      category: JobCategory.sales,
      jobType: JobType.fullTime,
      source: 'bdjobs',
      sourceType: JobSourceType.scraped,
      postedDate: DateTime(2026, 9, 18),
      deadline: DateTime.now().add(const Duration(days: 14)),
      minYearsExperience: 3,
      maxYearsExperience: 5,
      salaryMin: 'Tk. 30000 - 40000 (Monthly)',
      vacancies: '2',
      requiredSkills: const ['Customer Service'],
      details: details,
      applyLink: 'https://jobs.bdjobs.com/jobdetails.asp?id=1535146',
      status: JobStatus.approved,
      createdAt: DateTime(2026, 9, 18),
    );

Future<void> _pump(WidgetTester tester, Job job) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 6000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final locale = LocaleProvider();
  await locale.setLanguage(AppLanguage.en);
  final db = FakeFirebaseFirestore();
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: locale),
      ChangeNotifierProvider(create: (_) => SavedJobProvider(SavedJobService(db), 'u1')),
      ChangeNotifierProvider(create: (_) => ApplicationProvider(ApplicationService(db), 'u1')),
    ],
    child: MaterialApp(home: JobDetailsScreen(job: job)),
  ));
  await tester.pump();
}

void main() {
  testWidgets('shows each section of the circular under its heading', (tester) async {
    await _pump(tester, _job(details: {
      'responsibilities': 'Key Responsibilities:\n• Sell plots and land',
      'requirements': '• Age 24 to 50 years',
      'benefits': '• Mobile bill',
    }));

    expect(find.text('Job context & responsibilities'), findsOneWidget);
    expect(find.text('Key Responsibilities:\n• Sell plots and land'), findsOneWidget);
    expect(find.text('Additional requirements'), findsOneWidget);
    expect(find.text('Compensation & benefits'), findsOneWidget);
    expect(find.text('Education'), findsNothing);
    expect(find.text('Dhaka (Mirpur 2)'), findsOneWidget);
    expect(find.text('3–5 years'), findsOneWidget);
    expect(find.text('2'), findsOneWidget); // vacancies
    expect(find.text('Tk. 30000 - 40000 (Monthly)'), findsOneWidget);
    expect(find.textContaining('days left'), findsOneWidget);
    expect(find.text('Apply Now'), findsOneWidget);
    expect(find.text('Customer Service'), findsOneWidget);
    expect(find.textContaining("hasn't been fetched"), findsNothing);
  });

  testWidgets('falls back to the description, then to the original circular', (tester) async {
    await _pump(tester, _job(description: 'Sell land.'));
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Sell land.'), findsOneWidget);

    await _pump(tester, _job());
    expect(find.textContaining("hasn't been fetched"), findsOneWidget);
    expect(find.text('View original circular'), findsOneWidget);
  });
}
