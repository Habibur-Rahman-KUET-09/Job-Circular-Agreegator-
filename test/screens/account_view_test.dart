import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/screens/account_view.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<(LocaleProvider, List<String>)> _pump(
  WidgetTester tester, {
  bool admin = false,
  bool recruiter = false,
  bool passwordUser = true,
}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(1080, 4000);
  tester.view.devicePixelRatio = 2.5;
  addTearDown(tester.view.reset);
  final locale = LocaleProvider();
  await locale.setLanguage(AppLanguage.en);
  final taps = <String>[];
  VoidCallback tap(String name) => () => taps.add(name);
  await tester.pumpWidget(ChangeNotifierProvider.value(
    value: locale,
    child: MaterialApp(
      home: AccountView(
        name: 'Rahim',
        email: 'rahim@example.com',
        canReviewJobs: admin,
        canAddJobs: admin || recruiter,
        isPasswordUser: passwordUser,
        onOpenProfile: tap('profile'),
        onOpenSavedJobs: tap('saved'),
        onOpenApplications: tap('applications'),
        onReviewJobs: tap('review'),
        onAddJob: tap('addJob'),
        onChangePassword: tap('password'),
        onHowItWorks: tap('how'),
        onOpenSop: tap('sop'),
        onDeleteAccount: tap('delete'),
        onLogout: tap('logout'),
      ),
    ),
  ));
  return (locale, taps);
}

void main() {
  testWidgets('shows the user and the reference sections', (tester) async {
    await _pump(tester);

    expect(find.text('Rahim'), findsOneWidget);
    expect(find.text('rahim@example.com'), findsOneWidget);
    for (final label in ['Change password', 'Language', 'How it works', 'Detailed guide (SOP)', 'Delete account', 'Logout']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text(sopUrl), findsOneWidget);
  });

  testWidgets('regular users do not see review or add-job', (tester) async {
    await _pump(tester);
    expect(find.text('Review jobs'), findsNothing);
    expect(find.text('Add job'), findsNothing);
  });

  testWidgets('admins see review and add-job; recruiters only add-job', (tester) async {
    await _pump(tester, admin: true);
    expect(find.text('Review jobs'), findsOneWidget);
    expect(find.text('Add job'), findsOneWidget);

    await _pump(tester, recruiter: true);
    expect(find.text('Review jobs'), findsNothing);
    expect(find.text('Add job'), findsOneWidget);
  });

  testWidgets('Google users have no change-password row', (tester) async {
    await _pump(tester, passwordUser: false);
    expect(find.text('Change password'), findsNothing);
  });

  testWidgets('language row toggles between English and Bangla', (tester) async {
    final (locale, _) = await _pump(tester);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();

    expect(locale.language, AppLanguage.bn);
    expect(find.text('ভাষা'), findsOneWidget);
  });

  testWidgets('rows call their actions', (tester) async {
    final (_, taps) = await _pump(tester, admin: true);
    for (final label in ['My Profile', 'Saved Jobs', 'My Applications', 'Review jobs', 'Add job',
        'Change password', 'How it works', 'Detailed guide (SOP)', 'Delete account', 'Logout']) {
      await tester.tap(find.text(label));
    }
    expect(taps, ['profile', 'saved', 'applications', 'review', 'addJob', 'password', 'how', 'sop', 'delete', 'logout']);
  });
}
