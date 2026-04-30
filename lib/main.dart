import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:travel_pass/l10n/app_localizations.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/permit/screens/travel_permit_application_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'screens/home_screen.dart';
import 'screens/splash_screen.dart';
import 'core/constants/app_fonts.dart';
import 'core/network/token_storage.dart';
import 'dart:async';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

// Language Provider - allows dynamic language switching
final languageProvider =
    StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  return LanguageNotifier(const Locale('bn'));
});

class LanguageNotifier extends StateNotifier<Locale> {
  LanguageNotifier(super.initialState);

  void setLanguage(String languageCode) {
    state = Locale(languageCode);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(languageProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Travel Pass',
      locale: locale,
      supportedLocales: const [
        Locale('bn'),
        Locale('bn'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        fontFamily: AppFonts.english,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF16A34A),
          primary: const Color(0xFF16A34A),
        ),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/apply': (context) => const TravelPermitApplicationScreen(),
      },
    );
  }
}

// Verification Status Provider - tracks if user is verified
// `null` means the app is still checking stored tokens.
final verificationStatusProvider =
    StateNotifierProvider<VerificationStatusNotifier, bool?>((ref) {
  return VerificationStatusNotifier();
});

class VerificationStatusNotifier extends StateNotifier<bool?> {
  VerificationStatusNotifier() : super(null) {
    // Defer token check to avoid blocking main thread
    Future.microtask(_checkVerificationStatus);
  }

  Future<void> _checkVerificationStatus() async {
    try {
      // Check if token exists in secure storage
      final token = await TokenStorage.getAccessToken();
      state = token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Error checking verification status: $e');
      state = false;
    }
  }

  Future<void> setVerified(bool verified) async {
    state = verified;
    if (!verified) {
      // Clear tokens when logging out
      await TokenStorage.clearTokens();
    }
  }

  Future<void> logout() async {
    await setVerified(false);
  }
}