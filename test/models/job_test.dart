import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/job.dart';

Job _fullJob() => Job(
      id: 'job-1',
      title: 'Senior Flutter Developer',
      company: 'Acme Ltd',
      description: 'Build mobile apps',
      location: 'Dhaka',
      category: JobCategory.it,
      source: 'bdjobs',
      sourceType: JobSourceType.scraped,
      postedDate: DateTime.utc(2026, 9, 1),
      status: JobStatus.approved,
      createdAt: DateTime.utc(2026, 9, 1, 8),
      jobType: JobType.fullTime,
      requiredSkills: const ['Dart', 'Flutter'],
      minYearsExperience: 3,
      maxYearsExperience: 5,
      salaryMin: '80000',
      salaryMax: '120000',
      applyLink: 'https://www.bdjobs.com/jobs/1',
      deadline: DateTime.utc(2026, 10, 1),
      scrapedAt: DateTime.utc(2026, 9, 1, 6),
      viewCount: 12,
      applicationCount: 3,
    );

Map<String, dynamic> _minimalJson() => {
      'id': 'job-2',
      'title': 'Officer',
      'company': 'Sonali Bank',
      'description': 'Banking role',
      'location': 'Khulna',
      'category': 'bank',
      'source': 'manual',
      'sourceType': 'manual',
      'postedDate': '2026-09-01T00:00:00.000Z',
      'createdAt': '2026-09-01T00:00:00.000Z',
    };

void main() {
  group('Job JSON', () {
    test('round-trips every field through toJson/fromJson', () {
      final job = _fullJob();
      final restored = Job.fromJson(job.toJson());

      expect(restored.toJson(), job.toJson());
      expect(restored.category, JobCategory.it);
      expect(restored.jobType, JobType.fullTime);
      expect(restored.requiredSkills, ['Dart', 'Flutter']);
      expect(restored.deadline, DateTime.utc(2026, 10, 1));
    });

    test('fills defaults when optional fields are missing', () {
      final job = Job.fromJson(_minimalJson());

      expect(job.status, JobStatus.approved);
      expect(job.viewCount, 0);
      expect(job.applicationCount, 0);
      expect(job.jobType, isNull);
      expect(job.requiredSkills, isNull);
      expect(job.deadline, isNull);
      expect(job.postedBy, isNull);
    });

    test('reads the pending status written for scraped jobs', () {
      final job = Job.fromJson({..._minimalJson(), 'status': 'pending'});
      expect(job.status, JobStatus.pending);
    });

    test('omits jobType and requiredSkills from JSON when null', () {
      final json = Job.fromJson(_minimalJson()).toJson();

      expect(json.containsKey('jobType'), isFalse);
      expect(json.containsKey('requiredSkills'), isFalse);
      expect(json['deadline'], isNull);
    });

    test('writes postedBy under the key the Firestore rules check', () {
      final job = _fullJob().copyWith(postedBy: 'uid-123');
      expect(job.toJson()['postedBy'], 'uid-123');
    });

    test('accepts every category the Python scrapers can emit', () {
      const scraperCategories = [
        'it', 'finance', 'bank', 'govt', 'ngo', 'healthcare',
        'education', 'sales', 'marketing', 'operations', 'hr', 'other',
      ];
      for (final category in scraperCategories) {
        final job = Job.fromJson({..._minimalJson(), 'category': category});
        expect(job.category.name, category);
      }
    });
  });

  group('Job.jobType', () {
    test('parses the job type names the scrapers write', () {
      for (final type in JobType.values) {
        final job = Job.fromJson({..._minimalJson(), 'jobType': type.name});
        expect(job.jobType, type);
      }
    });

    test('treats an unknown job type as unspecified instead of crashing', () {
      final job = Job.fromJson({..._minimalJson(), 'jobType': 'full-time'});
      expect(job.jobType, isNull);
    });
  });

  group('Job.copyWith', () {
    test('changes only the given fields', () {
      final original = _fullJob();
      final updated = original.copyWith(
        status: JobStatus.rejected,
        viewCount: 13,
      );

      expect(updated.status, JobStatus.rejected);
      expect(updated.viewCount, 13);
      expect(updated.title, original.title);
      expect(updated.deadline, original.deadline);
      expect(updated.requiredSkills, original.requiredSkills);
    });
  });
}
