import 'package:flutter/material.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const SportMatchmakerApp());
}

class SportMatchmakerApp extends StatelessWidget {
  const SportMatchmakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sport Matchmaker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.amber[700]!,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}
