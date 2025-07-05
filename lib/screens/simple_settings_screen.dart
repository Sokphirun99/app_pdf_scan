import 'package:flutter/material.dart';
import '../widgets/theme_toggle_widget.dart';
import '../widgets/settings_widgets.dart';
import '../config/settings_config.dart';

/// Simplified Settings Screen
/// Uses organized components for cleaner code
class SimpleSettingsScreen extends StatelessWidget {
  const SimpleSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: _buildBody(),
    );
  }

  /// Build App Bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        'Settings',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      actions: const [FloatingThemeToggle(), SizedBox(width: 8)],
    );
  }

  /// Build Body Content
  Widget _buildBody() {
    return ListView(
      children: [
        const SizedBox(height: 16),

        // Settings Sections
        ...SettingsConfig.getAllSections().map(
          (section) => Column(
            children: [
              SettingsSection(title: section.title, items: section.items),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
