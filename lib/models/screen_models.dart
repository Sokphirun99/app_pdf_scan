import 'package:flutter/material.dart';

/// Navigation and Screen Models
/// This file contains data structures for main screen navigation

/// Bottom Navigation Item Data
class NavigationItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.screen,
  });
}

/// Settings Item Data
class SettingsItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

/// Settings Section Data
class SettingsSection {
  final String title;
  final List<SettingsItem> items;

  const SettingsSection({required this.title, required this.items});
}
