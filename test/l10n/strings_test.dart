import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/l10n/strings.dart';
import 'package:job_circular_aggregator/models/application.dart';
import 'package:job_circular_aggregator/models/job.dart';

void main() {
  const bn = Strings(AppLanguage.bn);
  const en = Strings(AppLanguage.en);

  void expectDistinctLabels<T extends Enum>(List<T> values, String Function(Strings, T) label) {
    for (final strings in [bn, en]) {
      final labels = values.map((v) => label(strings, v)).toList();
      expect(labels.toSet().length, values.length, reason: 'duplicate label in ${strings.lang}');
      for (final v in values) {
        expect(label(strings, v), isNot(v.name), reason: 'raw enum name shown for $v');
      }
    }
  }

  test('every job category has its own label in both languages', () {
    expectDistinctLabels(JobCategory.values, (s, v) => s.categoryLabel(v));
  });

  test('every job type has its own label in both languages', () {
    expectDistinctLabels(JobType.values, (s, v) => s.jobTypeLabel(v));
  });

  test('every application status has its own label in both languages', () {
    expectDistinctLabels(ApplicationStatus.values, (s, v) => s.applicationStatusLabel(v));
  });

  test('interviewAt omits the time when there is none', () {
    expect(en.interviewAt('10/9/2026', '10:30'), '10/9/2026 at 10:30');
    expect(en.interviewAt('10/9/2026', null), '10/9/2026');
    expect(bn.interviewAt('10/9/2026', '10:30'), '10/9/2026, 10:30');
  });
}
