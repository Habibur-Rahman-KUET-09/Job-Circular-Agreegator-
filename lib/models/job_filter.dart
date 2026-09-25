import 'job.dart';

enum JobSort { newest, deadlineSoon }

/// What the job list shows. Applied on the device to the loaded jobs, so
/// any combination works without Firestore indexes.
class JobFilter {
  final String query;
  final JobCategory? category;
  final Set<JobType> jobTypes;

  /// Matched against any part of the job's location, e.g. "Mirpur".
  final String location;

  /// Jobs asking for at most this many years; unspecified counts as 0.
  final int? maxExperience;

  final bool hideExpired;
  final bool closingSoon;
  final int? postedWithinDays;
  final bool salaryMentioned;
  final JobSort sort;

  static const closingSoonDays = 7;

  const JobFilter({
    this.query = '',
    this.category,
    this.jobTypes = const {},
    this.location = '',
    this.maxExperience,
    this.hideExpired = true,
    this.closingSoon = false,
    this.postedWithinDays,
    this.salaryMentioned = false,
    this.sort = JobSort.newest,
  });

  /// Filters chosen in the filter sheet (search and category have their
  /// own controls on the list), for the badge on the filter button.
  int get sheetFilterCount => [
        jobTypes.isNotEmpty,
        location.trim().isNotEmpty,
        maxExperience != null,
        !hideExpired,
        closingSoon,
        postedWithinDays != null,
        salaryMentioned,
        sort != JobSort.newest,
      ].where((active) => active).length;

  bool get isDefault => query.trim().isEmpty && category == null && sheetFilterCount == 0;

  List<Job> apply(List<Job> jobs, {DateTime? now}) {
    final result = jobs.where((job) => matches(job, now: now)).toList();
    if (sort == JobSort.deadlineSoon) {
      result.sort((a, b) {
        if (a.deadline == null && b.deadline == null) return b.postedDate.compareTo(a.postedDate);
        if (a.deadline == null) return 1;
        if (b.deadline == null) return -1;
        return a.deadline!.compareTo(b.deadline!);
      });
    } else {
      result.sort((a, b) => b.postedDate.compareTo(a.postedDate));
    }
    return result;
  }

  bool matches(Job job, {DateTime? now, bool ignoreCategory = false}) {
    final today = _dateOnly(now ?? DateTime.now());
    if (!ignoreCategory && category != null && job.category != category) return false;
    if (jobTypes.isNotEmpty && !jobTypes.contains(job.jobType)) return false;

    final place = location.trim().toLowerCase();
    if (place.isNotEmpty && !'${job.location} ${job.locationDetail ?? ''}'.toLowerCase().contains(place)) return false;

    if (maxExperience != null && (job.minYearsExperience ?? 0) > maxExperience!) return false;

    final deadline = job.deadline == null ? null : _dateOnly(job.deadline!.toLocal());
    if (hideExpired && deadline != null && deadline.isBefore(today)) return false;
    if (closingSoon &&
        (deadline == null ||
            deadline.isBefore(today) ||
            deadline.isAfter(today.add(const Duration(days: closingSoonDays))))) {
      return false;
    }
    if (postedWithinDays != null &&
        job.postedDate.toLocal().isBefore(today.subtract(Duration(days: postedWithinDays! - 1)))) {
      return false;
    }
    if (salaryMentioned && (job.salaryMin ?? job.salaryMax ?? '').trim().isEmpty) return false;

    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final text =
          '${job.title} ${job.company} ${job.location} ${job.locationDetail ?? ''} ${job.description}'.toLowerCase();
      if (!q.split(RegExp(r'\s+')).every(text.contains)) return false;
    }
    return true;
  }

  /// How many jobs each category would show with the other filters kept.
  Map<JobCategory, int> categoryCounts(List<Job> jobs, {DateTime? now}) {
    final counts = <JobCategory, int>{};
    for (final job in jobs) {
      if (matches(job, now: now, ignoreCategory: true)) {
        counts[job.category] = (counts[job.category] ?? 0) + 1;
      }
    }
    return counts;
  }

  /// Location parts in the loaded jobs, most common first, for suggestions.
  static List<String> locationSuggestions(List<Job> jobs) {
    final counts = <String, int>{};
    for (final job in jobs) {
      // "Dhaka (Mirpur 2)" also suggests the city, which list locations omit.
      final city = (job.locationDetail ?? '').split('(').first;
      for (final part in {...job.location.split(','), ...city.split(',')}) {
        final name = part.trim();
        if (name.isEmpty || name.toLowerCase() == 'not specified') continue;
        counts[name] = (counts[name] ?? 0) + 1;
      }
    }
    final names = counts.keys.toList()..sort((a, b) => counts[b]!.compareTo(counts[a]!));
    return names;
  }

  JobFilter copyWith({
    String? query,
    JobCategory? Function()? category,
    Set<JobType>? jobTypes,
    String? location,
    int? Function()? maxExperience,
    bool? hideExpired,
    bool? closingSoon,
    int? Function()? postedWithinDays,
    bool? salaryMentioned,
    JobSort? sort,
  }) {
    return JobFilter(
      query: query ?? this.query,
      category: category != null ? category() : this.category,
      jobTypes: jobTypes ?? this.jobTypes,
      location: location ?? this.location,
      maxExperience: maxExperience != null ? maxExperience() : this.maxExperience,
      hideExpired: hideExpired ?? this.hideExpired,
      closingSoon: closingSoon ?? this.closingSoon,
      postedWithinDays: postedWithinDays != null ? postedWithinDays() : this.postedWithinDays,
      salaryMentioned: salaryMentioned ?? this.salaryMentioned,
      sort: sort ?? this.sort,
    );
  }

  /// Keeps search and category; resets everything in the filter sheet.
  JobFilter clearSheet() => JobFilter(query: query, category: category);

  static DateTime _dateOnly(DateTime t) => DateTime(t.year, t.month, t.day);
}
