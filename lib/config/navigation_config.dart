import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/tab_screens.dart';
import '../screens/simple_settings_screen.dart';
import '../models/screen_models.dart';

/// Navigation Configuration
/// Centralized navigation setup for main screen

class NavigationConfig {
  /// Get all navigation items
  static List<NavigationItem> getNavigationItems() {
    return [
      const NavigationItem(
        label: 'Tools',
        icon: Icons.home,
        screen: HomeScreen(),
      ),
      const NavigationItem(
        label: 'Favorites',
        icon: Icons.favorite,
        screen: FavoritesScreen(),
      ),
      const NavigationItem(
        label: 'Recent',
        icon: Icons.history,
        screen: RecentScreen(),
      ),
      const NavigationItem(
        label: 'Settings',
        icon: Icons.settings,
        screen: SimpleSettingsScreen(),
      ),
    ];
  }

  /// Get bottom navigation bar items
  static List<BottomNavigationBarItem> getBottomNavItems() {
    return getNavigationItems()
        .map(
          (item) =>
              BottomNavigationBarItem(icon: Icon(item.icon), label: item.label),
        )
        .toList();
  }

  /// Get screens list
  static List<Widget> getScreens() {
    return getNavigationItems().map((item) => item.screen).toList();
  }
}
