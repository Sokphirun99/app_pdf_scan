import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../themes/app_themes.dart';

class ThemeToggleWidget extends StatelessWidget {
  final bool showLabel;
  final EdgeInsets? padding;

  const ThemeToggleWidget({super.key, this.showLabel = true, this.padding});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return Container(
          padding:
              padding ??
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLabel) ...[
                Icon(
                  themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  themeProvider.isDarkMode ? 'Dark Mode' : 'Light Mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
              ],
              GestureDetector(
                onTap: () {
                  themeProvider.toggleTheme();
                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            themeProvider.isDarkMode
                                ? Icons.dark_mode
                                : Icons.light_mode,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${themeProvider.isDarkMode ? 'Dark' : 'Light'} mode enabled',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: 60,
                  height: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors:
                          themeProvider.isDarkMode
                              ? [
                                const Color(0xFF1A1A2E),
                                const Color(0xFF16213E),
                              ]
                              : [
                                const Color(0xFF4F46E5),
                                const Color(0xFF7C3AED),
                              ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (themeProvider.isDarkMode
                                ? const Color(0xFF1A1A2E)
                                : const Color(0xFF4F46E5))
                            .withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        left: themeProvider.isDarkMode ? 30 : 2,
                        top: 2,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Icon(
                            themeProvider.isDarkMode
                                ? Icons.nights_stay
                                : Icons.wb_sunny,
                            size: 16,
                            color:
                                themeProvider.isDarkMode
                                    ? const Color(0xFF1A1A2E)
                                    : const Color(0xFF4F46E5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Floating Theme Toggle Button
class FloatingThemeToggle extends StatelessWidget {
  const FloatingThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return FloatingActionButton.small(
          heroTag: "theme_toggle",
          onPressed: () {
            themeProvider.toggleTheme();
          },
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.primary,
          elevation: 4,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
              key: ValueKey(themeProvider.isDarkMode),
            ),
          ),
        );
      },
    );
  }
}

// Theme Selection Bottom Sheet
class ThemeSelectionSheet extends StatelessWidget {
  const ThemeSelectionSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeSelectionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 320,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Choose Theme',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Theme Options
          Expanded(
            child: Consumer<ThemeProvider>(
              builder: (context, themeProvider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _ThemeOption(
                        title: 'Light Mode',
                        subtitle: 'Clean and bright interface',
                        icon: Icons.light_mode,
                        isSelected: !themeProvider.isDarkMode,
                        onTap: () => themeProvider.setTheme(false),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ThemeOption(
                        title: 'Dark Mode',
                        subtitle: 'Easier on the eyes in low light',
                        icon: Icons.dark_mode,
                        isSelected: themeProvider.isDarkMode,
                        onTap: () => themeProvider.setTheme(true),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ThemeOption(
                        title: 'System Default',
                        subtitle: 'Follow system settings',
                        icon: Icons.settings_system_daydream,
                        isSelected: false, // Will implement later
                        onTap: () {
                          // Follow system theme
                          final brightness =
                              MediaQuery.of(context).platformBrightness;
                          themeProvider.setTheme(brightness == Brightness.dark);
                        },
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Gradient gradient;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: isSelected ? null : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: gradient.colors.first.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? Colors.white.withValues(alpha: 0.2)
                        : Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color:
                    isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color:
                          isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.8)
                              : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: Colors.white, size: 24),
          ],
        ),
      ),
    );
  }
}
