import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:my_pro9/screens/onboarding_screen.dart';
import 'package:my_pro9/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const LongTea());
}

class LongTea extends StatelessWidget {
  const LongTea({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Long Tea',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
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
