import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/models/user_profile.dart';

void main() {
  final createdAt = DateTime.utc(2026, 8, 20);

  test('new profiles default to notifications on and Bangla UI', () {
    final profile = UserProfile(userId: 'uid-1', fullName: 'Rahim', createdAt: createdAt);

    expect(profile.notificationsEnabled, isTrue);
    expect(profile.preferredLanguage, 'bn');
    expect(profile.skills, isEmpty);
    expect(profile.preferredLocations, isEmpty);
    expect(profile.totalApplications, 0);
  });

  test('fromJson applies the same defaults for missing fields', () {
    final profile = UserProfile.fromJson({
      'userId': 'uid-1',
      'fullName': 'Rahim',
      'createdAt': createdAt.toIso8601String(),
    });

    expect(profile.notificationsEnabled, isTrue);
    expect(profile.preferredLanguage, 'bn');
    expect(profile.skills, isEmpty);
    expect(profile.updatedAt, isNull);
  });

  test('round-trips a filled-in profile', () {
    final profile = UserProfile(
      userId: 'uid-2',
      fullName: 'Karim',
      email: 'karim@example.com',
      yearsOfExperience: 4,
      skills: const ['Excel', 'Tally'],
      preferredLocations: const ['Dhaka', 'Chittagong'],
      preferredIndustries: const ['bank'],
      notificationsEnabled: false,
      preferredLanguage: 'en',
      createdAt: createdAt,
      updatedAt: DateTime.utc(2026, 9, 1),
      totalApplications: 7,
      successCount: 2,
    );

    final restored = UserProfile.fromJson(profile.toJson());
    expect(restored.toJson(), profile.toJson());
  });

  test('copyWith replaces skills without touching other fields', () {
    final profile = UserProfile(
      userId: 'uid-1',
      fullName: 'Rahim',
      skills: const ['Dart'],
      createdAt: createdAt,
    );
    final updated = profile.copyWith(skills: ['Dart', 'Firebase']);

    expect(updated.skills, ['Dart', 'Firebase']);
    expect(updated.fullName, 'Rahim');
    expect(updated.createdAt, createdAt);
  });
}
