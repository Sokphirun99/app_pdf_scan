import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'themes/app_themes.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider()..loadThemeMode(),
      child: const PDFToolsProApp(),
    ),
  );
}

class PDFToolsProApp extends StatelessWidget {
  const PDFToolsProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'PDF Tools By Phirun',
          debugShowCheckedModeBanner: false,
          theme: AppThemes.lightTheme,
          darkTheme: AppThemes.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: const SplashScreen(),
        );
      },
    );
  }
}
