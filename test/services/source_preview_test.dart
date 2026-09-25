import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/scraper_source.dart';
import 'package:job_circular_aggregator/services/source_preview.dart';

// Same page as scrapers/tests/test_scrapers.py, so both readers agree.
const sitePage = '''<html><body>
<nav><a href="/about">About this website</a><a href="/contact">Contact the team</a></nav>
<div class="list">
<div class="job-card"><h3><a href="/jobs/101">Senior Officer, IT</a></h3>
  <span class="org">Pubali Bank PLC</span><span class="place">Dhaka</span>
  <span class="deadline">Deadline: 30 Oct 2026</span></div>
<div class="job-card"><h3><a href="https://other.example/jobs/102">Sales   Executive</a></h3>
  <span class="org"></span><span class="deadline">Apply before 5/11/2026</span></div>
<div class="job-card"><h3><a href="/jobs/101">Senior Officer, IT</a></h3></div>
<div class="job-card"><p>No title here</p></div>
</div></body></html>''';

final pageUrl = Uri.parse('https://jobs.example.com/latest');

ScraperSource source({String item = 'div.job-card', String title = '', String company = '', String deadline = ''}) =>
    ScraperSource(
      name: 'Example Jobs',
      listUrl: pageUrl.toString(),
      itemSelector: item,
      titleSelector: title,
      companySelector: company,
      deadlineSelector: deadline,
    );

void main() {
  test('reads each job with its fields and absolute link', () {
    final jobs = previewJobs(sitePage, pageUrl, source(title: 'h3 a', company: '.org', deadline: '.deadline'));
    expect(jobs.map((j) => j.title), ['Senior Officer, IT', 'Sales Executive']);
    expect(jobs[0].company, 'Pubali Bank PLC');
    expect(jobs[0].deadline, 'Deadline: 30 Oct 2026');
    expect(jobs[0].link, 'https://jobs.example.com/jobs/101');
    expect(jobs[1].company, '');
    expect(jobs[1].link, 'https://other.example/jobs/102');
  });

  test('without a title selector the first link is the job', () {
    final jobs = previewJobs(sitePage, pageUrl, source());
    expect(jobs.map((j) => j.title), ['Senior Officer, IT', 'Sales Executive']);
    expect(jobs[0].link, 'https://jobs.example.com/jobs/101');
  });

  test('an invalid selector is reported', () {
    expect(() => previewJobs(sitePage, pageUrl, source(item: 'div[[')), throwsA(isA<PreviewException>()));
  });

  test('detects the repeated job box, not the navigation', () {
    expect(suggestItemSelector(sitePage), 'div.job-card');
    expect(suggestItemSelector('<html><body><a href="/a">Only one link here</a></body></html>'), isNull);
  });

  test('round-trips through Firestore data', () {
    final original = source(title: 'h3 a');
    final copy = ScraperSource.fromMap('id1', {
      ...original.toMap(),
      'lastRunAt': '2026-09-25T09:00:00',
      'lastJobCount': 12,
      'lastError': null,
    });
    expect(copy.id, 'id1');
    expect(copy.titleSelector, 'h3 a');
    expect(copy.enabled, isTrue);
    expect(copy.lastJobCount, 12);
    expect(copy.lastRunAt, DateTime(2026, 9, 25, 9));
    expect(copy.toMap().containsKey('lastJobCount'), isFalse);
  });
}
