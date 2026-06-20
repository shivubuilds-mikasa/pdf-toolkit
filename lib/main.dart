import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/localization/localizations.dart';
import 'core/storage/storage_service.dart';
import 'core/theme/theme.dart';
import 'features/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final storageService = StorageService(prefs);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeThemeMode = ref.watch(themeModeProvider);
    final activeLocale = ref.watch(localeProvider);
    final storage = ref.read(storageServiceProvider);

    // Sync saved language preferences to activeLocale on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedLang = storage.language;
      if (activeLocale.languageCode != savedLang) {
        ref.read(localeProvider.notifier).setLocale(Locale(savedLang));
      }
    });

    return MaterialApp(
      title: 'PDF Toolkit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: activeThemeMode,
      locale: activeLocale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', ''),
        Locale('es', ''),
        Locale('fr', ''),
        Locale('de', ''),
        Locale('hi', ''),
      ],
      home: const MainLayout(),
    );
  }
}
