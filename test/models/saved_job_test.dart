import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/saved_job.dart';

SavedJob _savedJob({String? notes}) => SavedJob(
      id: 'saved-1',
      userId: 'uid-1',
      jobId: 'job-1',
      jobTitle: 'Accountant',
      company: 'BRAC',
      location: 'Sylhet',
      savedAt: DateTime.utc(2026, 9, 3, 14, 5),
      notes: notes,
    );

void main() {
  test('round-trips through toJson/fromJson', () {
    final saved = _savedJob(notes: 'Apply before Friday');
    final restored = SavedJob.fromJson(saved.toJson());

    expect(restored.toJson(), saved.toJson());
    expect(restored.savedAt, DateTime.utc(2026, 9, 3, 14, 5));
  });

  test('keeps notes null when none were written', () {
    final restored = SavedJob.fromJson(_savedJob().toJson());
    expect(restored.notes, isNull);
  });

  test('copyWith updates notes only', () {
    final original = _savedJob();
    final updated = original.copyWith(notes: 'Called HR');

    expect(updated.notes, 'Called HR');
    expect(updated.jobId, original.jobId);
    expect(updated.savedAt, original.savedAt);
  });
}
