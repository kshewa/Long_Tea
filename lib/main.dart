import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:longtea_mobile/providers/auth_notifier.dart';
import 'package:longtea_mobile/screens/onboarding_screen.dart';
import 'package:longtea_mobile/screens/home_screen.dart';
import 'package:longtea_mobile/screens/login_screen.dart';
import 'package:longtea_mobile/screens/main_navigation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  runApp(const ProviderScope(child: LongTea()));
}

class LongTea extends StatelessWidget {
  const LongTea({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Long Tea',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: {
        '/onboarding': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const MainNavigation(initialTab: 0),
        '/products': (context) => HomeScreen(),
      },
    );
  }
}

/// Wrapper widget that determines initial screen based on auth state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Show loading screen while checking auth state
    if (authState.isLoading && authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If authenticated, go to main navigation
    if (authState.isAuthenticated) {
      return const MainNavigation(initialTab: 0);
    }

    // Otherwise, show onboarding/login
    return const OnboardingScreen();
  }
}
