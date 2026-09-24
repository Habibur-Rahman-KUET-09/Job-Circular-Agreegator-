import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:job_circular_aggregator/l10n/locale_provider.dart';
import 'package:job_circular_aggregator/screens/auth/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('logo image is bundled', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final data = await rootBundle.load('assets/images/logo.png');
    expect(data.lengthInBytes, greaterThan(1000));
  });

  testWidgets('login screen shows the logo and the Shondhan name', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final locale = LocaleProvider();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: locale,
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('সন্ধান'), findsOneWidget);
    final logo = tester.widget<Image>(find.byType(Image));
    expect((logo.image as AssetImage).assetName, 'assets/images/logo.png');
  });
}
