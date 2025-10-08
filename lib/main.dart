import 'package:flutter/material.dart';
import 'package:longtea_mobile/screens/onboarding_screen.dart';
import 'package:longtea_mobile/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const LongTea());
}

class LongTea extends StatelessWidget {
  const LongTea({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Long Tea',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Roboto'),
      debugShowCheckedModeBanner: false,

      // ✅ Use named routes so you can navigate easily
      initialRoute: '/',
      routes: {
        '/': (context) => const OnboardingScreen(),
        '/products': (context) => HomeScreen(),
      },
    );
  }
}
