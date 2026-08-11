import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'state/app_scope.dart';
import 'ui/screens/home_screen.dart';
import 'ui/screens/onboarding/onboarding_screen.dart';
import 'ui/theme/nothing_theme.dart';

class EssentialKeyApp extends StatefulWidget {
  const EssentialKeyApp({super.key});

  @override
  State<EssentialKeyApp> createState() => _EssentialKeyAppState();
}

class _EssentialKeyAppState extends State<EssentialKeyApp> {
  bool? _onboardingCompleted;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool('onboarding_completed') ?? false;
    final savedTheme = prefs.getString('theme_mode') ?? 'dark';

    ThemeMode mode;
    if (savedTheme == 'light') {
      mode = ThemeMode.light;
    } else if (savedTheme == 'system') {
      mode = ThemeMode.system;
    } else {
      mode = ThemeMode.dark;
    }
    NothingTheme.themeModeNotifier.value = mode;

    if (mounted) {
      setState(() {
        _onboardingCompleted = completed;
      });
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);
    if (mounted) {
      setState(() {
        _onboardingCompleted = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: NothingTheme.themeModeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'buttonoo',
          debugShowCheckedModeBanner: false,
          theme: NothingTheme.lightTheme,
          darkTheme: NothingTheme.darkTheme,
          themeMode: currentMode,
          builder: (context, child) => AppScope(child: child!),
          home: _onboardingCompleted == null
              ? Scaffold(
                  backgroundColor: NothingTheme.bg(context),
                  body: const Center(
                    child: CircularProgressIndicator(color: NothingTheme.accentRed),
                  ),
                )
              : _onboardingCompleted!
              ? const HomeScreen()
              : OnboardingScreen(onComplete: _completeOnboarding),
        );
      },
    );
  }
}
