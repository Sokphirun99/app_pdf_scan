import 'package:flutter/material.dart';
import '../models/screen_models.dart';

/// Settings Configuration
/// Centralized configuration for all settings items

class SettingsConfig {
  /// Get all settings sections
  static List<SettingsSection> getAllSections() {
    return [
      _getAppearanceSection(),
      _getPreferencesSection(),
      _getSupportSection(),
    ];
  }

  /// Appearance Settings Section
  static SettingsSection _getAppearanceSection() {
    return SettingsSection(
      title: 'Appearance',
      items: [
        SettingsItem(
          icon: Icons.palette,
          title: 'Theme',
          subtitle: 'Choose your preferred theme',
          onTap: () {
            // Theme selection logic will go here
            debugPrint('Theme settings tapped');
          },
        ),
      ],
    );
  }

  /// Preferences Settings Section
  static SettingsSection _getPreferencesSection() {
    return SettingsSection(
      title: 'Preferences',
      items: [
        SettingsItem(
          icon: Icons.notifications,
          title: 'Notifications',
          subtitle: 'Configure notification preferences',
          onTap: () {
            debugPrint('Notifications tapped');
          },
        ),
        SettingsItem(
          icon: Icons.language,
          title: 'Language',
          subtitle: 'English (US)',
          onTap: () {
            debugPrint('Language settings tapped');
          },
        ),
        SettingsItem(
          icon: Icons.storage,
          title: 'Storage',
          subtitle: 'Manage app data and cache',
          onTap: () {
            debugPrint('Storage settings tapped');
          },
        ),
      ],
    );
  }

  /// Support Settings Section
  static SettingsSection _getSupportSection() {
    return SettingsSection(
      title: 'Support',
      items: [
        SettingsItem(
          icon: Icons.help,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          onTap: () {
            debugPrint('Help & Support tapped');
          },
        ),
        SettingsItem(
          icon: Icons.feedback,
          title: 'Send Feedback',
          subtitle: 'Help us improve the app',
          onTap: () {
            debugPrint('Send feedback tapped');
          },
        ),
        SettingsItem(
          icon: Icons.info,
          title: 'About',
          subtitle: 'Version 1.0.0',
          onTap: () {
            debugPrint('About tapped');
          },
        ),
      ],
    );
  }

  /// Premium upgrade action
  static void handlePremiumUpgrade() {
    debugPrint('Premium upgrade tapped');
    // Premium upgrade logic will go here
  }
}
