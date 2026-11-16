import 'package:flutter/material.dart';
import 'matches/match_feed_screen.dart';
import 'matches/my_matches_screen.dart';
import 'matches/create_match_screen.dart';
import 'profile/profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    MatchFeedScreen(),
    MyMatchesScreen(),
    CreateMatchScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer),
            label: 'Feed',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            label: 'My Matches',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            label: 'Host Game',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}