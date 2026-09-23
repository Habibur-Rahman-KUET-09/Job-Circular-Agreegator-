import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'l10n/locale_provider.dart';
import 'l10n/strings.dart';
import 'providers/index.dart';
import 'providers/notification_provider.dart';
import 'screens/auth/auth_gate.dart';
import 'services/index.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final localeProvider = LocaleProvider();
  await localeProvider.load();
  runApp(JobCircularApp(localeProvider: localeProvider));
}

class JobCircularApp extends StatelessWidget {
  final LocaleProvider localeProvider;
  const JobCircularApp({super.key, required this.localeProvider});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF00695C); // teal — matches the app icon
    final firestore = FirebaseFirestore.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeProvider),
        ChangeNotifierProvider(create: (_) => JobProvider(JobService(firestore))),
        ChangeNotifierProvider(
          create: (_) => NotificationProvider(NotificationService()),
        ),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, locale, _) => MaterialApp(
          title: Strings(locale.language).appTitle,
          debugShowCheckedModeBanner: false,
          locale: locale.locale,
          supportedLocales: const [Locale('bn'), Locale('en')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
            useMaterial3: true,
            fontFamily: 'NotoSansBengali',
            appBarTheme: const AppBarTheme(centerTitle: false),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: seedColor,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            fontFamily: 'NotoSansBengali',
          ),
          home: const AuthGate(),
        ),
      ),
    );
  }
}
