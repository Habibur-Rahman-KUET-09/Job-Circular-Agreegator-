import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/models/scraper_source.dart';
import 'package:job_circular_aggregator/screens/job_source_form_screen.dart';
import 'package:job_circular_aggregator/services/scraper_source_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/source_preview_test.dart' show sitePage;

class _FakeSourceService extends ScraperSourceService {
  final saved = <ScraperSource>[];
  _FakeSourceService() : super(FakeFirebaseFirestore());

  @override
  Future<void> save(ScraperSource source) async => saved.add(source);
}

Future<(_FakeSourceService, List<Uri>)> _pump(WidgetTester tester, {bool failFetch = false}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 5000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final locale = LocaleProvider();
  await locale.setLanguage(AppLanguage.en);
  final service = _FakeSourceService();
  final fetched = <Uri>[];
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: locale,
    child: MaterialApp(
      home: JobSourceFormScreen(
        service: service,
        uid: 'admin1',
        pageFetcher: (url) async {
          fetched.add(url);
          if (failFetch) throw Exception('HTTP 403');
          return sitePage;
        },
      ),
    ),
  ));
  return (service, fetched);
}

Finder _field(String label) => find.widgetWithText(TextFormField, label);

void main() {
  testWidgets('detect, test, then save a source', (tester) async {
    final (service, fetched) = await _pump(tester);
    await tester.enterText(_field('Website name'), 'Example Jobs');
    await tester.enterText(_field('Job list link'), 'https://jobs.example.com/latest');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required'), findsOneWidget); // item selector
    expect(service.saved, isEmpty);

    await tester.tap(find.text('Detect'));
    await tester.pumpAndSettle();
    expect(find.text('Found: div.job-card'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Tap "Test" before saving'), findsOneWidget);

    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.text('2 jobs found'), findsOneWidget);
    expect(find.text('Senior Officer, IT'), findsOneWidget);
    expect(fetched, hasLength(1)); // detect and test share one download

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.saved, hasLength(1));
    final saved = service.saved.single;
    expect(saved.name, 'Example Jobs');
    expect(saved.itemSelector, 'div.job-card');
    expect(saved.enabled, isTrue);
    expect(saved.createdBy, 'admin1');
  });

  testWidgets('changing a selector requires testing again', (tester) async {
    final (service, _) = await _pump(tester);
    await tester.enterText(_field('Website name'), 'Example Jobs');
    await tester.enterText(_field('Job list link'), 'https://jobs.example.com/latest');
    await tester.enterText(_field('Selector for each job'), 'div.job-card');
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.text('Senior Officer, IT'), findsOneWidget);

    await tester.enterText(_field('Selector for each job'), 'li.nothing');
    await tester.pump();
    expect(find.text('Senior Officer, IT'), findsNothing);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(service.saved, isEmpty);
  });

  testWidgets('shows why a page could not be read', (tester) async {
    final (service, _) = await _pump(tester, failFetch: true);
    await tester.enterText(_field('Job list link'), 'https://blocked.example.com');
    await tester.enterText(_field('Selector for each job'), 'div.job-card');
    await tester.tap(find.text('Test'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not read the page'), findsOneWidget);
    expect(service.saved, isEmpty);
  });
}
