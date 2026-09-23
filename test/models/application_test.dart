import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/application.dart';

Application _application() => Application(
      id: 'app-1',
      userId: 'uid-1',
      jobId: 'job-1',
      jobTitle: 'Flutter Developer',
      company: 'Acme Ltd',
      status: ApplicationStatus.interviewScheduled,
      appliedDate: DateTime.utc(2026, 9, 2),
      lastUpdated: DateTime.utc(2026, 9, 5),
      notes: 'Referred by a friend',
      documents: const ['https://example.com/cv.pdf'],
      callbackPhone: '01700000000',
      interviewDate: DateTime.utc(2026, 9, 10),
      interviewTime: '10:30',
      interviewType: 'video',
    );

void main() {
  test('round-trips through toJson/fromJson', () {
    final app = _application();
    final restored = Application.fromJson(app.toJson());

    expect(restored.toJson(), app.toJson());
    expect(restored.status, ApplicationStatus.interviewScheduled);
    expect(restored.interviewDate, DateTime.utc(2026, 9, 10));
  });

  test('defaults documents to an empty list when missing', () {
    final json = _application().toJson()..remove('documents');
    expect(Application.fromJson(json).documents, isEmpty);
  });

  test('stores status by enum name', () {
    expect(_application().toJson()['status'], 'interviewScheduled');
  });

  test('copyWith updates status and keeps everything else', () {
    final original = _application();
    final updated = original.copyWith(status: ApplicationStatus.selected);

    expect(updated.status, ApplicationStatus.selected);
    expect(updated.jobId, original.jobId);
    expect(updated.interviewDate, original.interviewDate);
    expect(updated.documents, original.documents);
  });
}
