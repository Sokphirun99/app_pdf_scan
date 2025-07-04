import 'package:flutter/material.dart';
import '../config/navigation_config.dart';

/// Simplified Main Screen
/// Clean and organized main screen using configuration
class SimpleMainScreen extends StatefulWidget {
  const SimpleMainScreen({super.key});

  @override
  State<SimpleMainScreen> createState() => _SimpleMainScreenState();
}

class _SimpleMainScreenState extends State<SimpleMainScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final screens = NavigationConfig.getScreens();
    final navItems = NavigationConfig.getBottomNavItems();

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: const Color(0xFF1E40AF),
        unselectedItemColor: Colors.grey,
        items: navItems,
      ),
    );
  }

  /// Handle tab tap
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
