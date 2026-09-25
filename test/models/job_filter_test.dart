import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/job.dart';
import 'package:job_circular_aggregator/models/job_filter.dart';

final now = DateTime(2026, 9, 25, 10);

Job job(
  String id, {
  JobCategory category = JobCategory.it,
  JobType? type = JobType.fullTime,
  String location = 'Banani',
  String? locationDetail,
  int? minYears,
  int postedDaysAgo = 0,
  int? deadlineInDays = 20,
  String? salary,
  String title = 'Officer',
}) =>
    Job(
      id: id,
      title: title,
      company: 'Acme',
      description: 'Work',
      location: location,
      locationDetail: locationDetail,
      category: category,
      jobType: type,
      source: 'bdjobs',
      sourceType: JobSourceType.scraped,
      postedDate: now.subtract(Duration(days: postedDaysAgo)),
      deadline: deadlineInDays == null ? null : now.add(Duration(days: deadlineInDays)),
      minYearsExperience: minYears,
      salaryMin: salary,
      status: JobStatus.approved,
      createdAt: now,
    );

List<String> ids(JobFilter f, List<Job> jobs) => f.apply(jobs, now: now).map((j) => j.id).toList();

void main() {
  test('hides expired jobs by default and can show them', () {
    final jobs = [job('open'), job('expired', deadlineInDays: -1), job('today', deadlineInDays: 0), job('none', deadlineInDays: null)];
    expect(ids(const JobFilter(), jobs), ['open', 'today', 'none']);
    expect(ids(const JobFilter(hideExpired: false), jobs), hasLength(4));
  });

  test('category filter and per-category counts', () {
    final jobs = [job('a'), job('b', category: JobCategory.bank), job('c', category: JobCategory.bank)];
    const bank = JobFilter(category: JobCategory.bank);
    expect(ids(bank, jobs), ['b', 'c']);
    // Counts ignore the chosen category but respect the other filters.
    expect(bank.categoryCounts(jobs, now: now), {JobCategory.it: 1, JobCategory.bank: 2});
    expect(bank.copyWith(query: 'nothing').categoryCounts(jobs, now: now), isEmpty);
    expect(bank.copyWith(category: () => null).category, isNull);
  });

  test('job type, location, experience, salary and posted date', () {
    final jobs = [
      job('intern', type: JobType.internship, minYears: 0, salary: 'Tk. 10000'),
      job('senior', minYears: 6, location: 'Agrabad', locationDetail: 'Chattogram (Agrabad)', postedDaysAgo: 5),
      job('mid', type: JobType.contract, minYears: 2, postedDaysAgo: 1),
      job('na', minYears: null, postedDaysAgo: 10),
    ];
    expect(ids(const JobFilter(jobTypes: {JobType.internship, JobType.contract}), jobs), ['intern', 'mid']);
    expect(ids(const JobFilter(location: 'chattogram'), jobs), ['senior']);
    expect(ids(const JobFilter(maxExperience: 0), jobs), ['intern', 'na']);
    expect(ids(const JobFilter(maxExperience: 2), jobs), ['intern', 'mid', 'na']);
    expect(ids(const JobFilter(salaryMentioned: true), jobs), ['intern']);
    expect(ids(const JobFilter(postedWithinDays: 1), jobs), ['intern']);
    expect(ids(const JobFilter(postedWithinDays: 3), jobs), ['intern', 'mid']);
  });

  test('closing soon keeps deadlines within a week', () {
    final jobs = [job('soon', deadlineInDays: 3), job('later', deadlineInDays: 20), job('none', deadlineInDays: null)];
    expect(ids(const JobFilter(closingSoon: true), jobs), ['soon']);
  });

  test('search matches every word anywhere', () {
    final jobs = [job('a', title: 'Senior Flutter Developer'), job('b', title: 'Flutter Intern')];
    expect(ids(const JobFilter(query: 'flutter senior'), jobs), ['a']);
    expect(ids(const JobFilter(query: '  flutter '), jobs), ['a', 'b']);
  });

  test('sorts by newest or by nearest deadline', () {
    final jobs = [
      job('old-soon', postedDaysAgo: 5, deadlineInDays: 2),
      job('new-late', postedDaysAgo: 0, deadlineInDays: 30),
      job('mid-none', postedDaysAgo: 2, deadlineInDays: null),
    ];
    expect(ids(const JobFilter(), jobs), ['new-late', 'mid-none', 'old-soon']);
    expect(ids(const JobFilter(sort: JobSort.deadlineSoon), jobs), ['old-soon', 'new-late', 'mid-none']);
  });

  test('counts sheet filters and clears them without touching search or category', () {
    const f = JobFilter(
      query: 'x',
      category: JobCategory.it,
      jobTypes: {JobType.contract},
      closingSoon: true,
      sort: JobSort.deadlineSoon,
    );
    expect(f.sheetFilterCount, 3);
    expect(f.isDefault, isFalse);
    final cleared = f.clearSheet();
    expect(cleared.sheetFilterCount, 0);
    expect((cleared.query, cleared.category), ('x', JobCategory.it));
    expect(const JobFilter().isDefault, isTrue);
  });

  test('suggests locations and cities, most common first', () {
    final jobs = [
      job('a', location: 'Mirpur 2', locationDetail: 'Dhaka (Mirpur 2)'),
      job('b', location: 'Banani, Gulshan', locationDetail: 'Dhaka (Banani)'),
      job('c', location: 'Not specified'),
    ];
    final suggestions = JobFilter.locationSuggestions(jobs);
    expect(suggestions.first, 'Dhaka');
    expect(suggestions, containsAll(['Mirpur 2', 'Banani', 'Gulshan']));
    expect(suggestions, isNot(contains('Not specified')));
  });
}
