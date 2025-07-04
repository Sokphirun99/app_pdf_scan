import 'package:flutter/material.dart';
import '../widgets/settings_widgets.dart';

/// Individual Screen Components
/// Separated screen widgets for better organization

/// Favorites Screen
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: const EmptyStateWidget(
        icon: Icons.favorite_outline,
        title: 'No favorite tools yet',
        subtitle: 'Add tools to favorites to see them here',
      ),
    );
  }
}

/// Recent Screen
class RecentScreen extends StatelessWidget {
  const RecentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent'),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
      ),
      body: const EmptyStateWidget(
        icon: Icons.history,
        title: 'No recent files',
        subtitle: 'Your recent PDF activities will appear here',
      ),
    );
  }
}
