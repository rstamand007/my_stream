import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_stream/screens/settings_screen.dart';
import 'package:my_stream/providers/theme_provider.dart';
import 'package:my_stream/providers/locale_provider.dart';
import 'package:my_stream/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

class MockThemeProvider extends ChangeNotifier implements ThemeProvider {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  ThemeMode get themeMode => _themeMode;

  @override
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockLocaleProvider extends ChangeNotifier implements LocaleProvider {
  @override
  Locale? get locale => const Locale('en');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late MockThemeProvider mockThemeProvider;
  late MockLocaleProvider mockLocaleProvider;

  setUp(() {
    mockThemeProvider = MockThemeProvider();
    mockLocaleProvider = MockLocaleProvider();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('fr')],
      home: MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeProvider>.value(value: mockThemeProvider),
          ChangeNotifierProvider<LocaleProvider>.value(
            value: mockLocaleProvider,
          ),
        ],
        child: const SettingsScreen(),
      ),
    );
  }

  testWidgets('Theme selection dropdown updates provider state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Verify initial value is System
    expect(find.text('System'), findsOneWidget);

    // Open dropdown
    await tester.tap(find.text('System'));
    await tester.pumpAndSettle();

    // Select Light theme
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();

    // Verify provider was updated
    expect(mockThemeProvider.themeMode, ThemeMode.light);
    expect(find.text('Light'), findsOneWidget);

    // Open dropdown again
    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();

    // Select Dark theme
    await tester.tap(find.text('Dark').last);
    await tester.pumpAndSettle();

    // Verify provider was updated
    expect(mockThemeProvider.themeMode, ThemeMode.dark);
    expect(find.text('Dark'), findsOneWidget);
  });
}
