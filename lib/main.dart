import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/lens_screen.dart';
import 'screens/memories_screen.dart';
import 'screens/family_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AlaAlaApp());
}

class AlaAlaApp extends StatefulWidget {
  const AlaAlaApp({super.key});

  @override
  State<AlaAlaApp> createState() => _AlaAlaAppState();
}

class _AlaAlaAppState extends State<AlaAlaApp> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    const beigeBackground = Color(0xFFF6F1E8);
    const goldAccent = Color(0xFFCFAE68);
    const creamSurface = Color(0xFFFFFDF9);
    const darkText = Color(0xFF383229);

    final pages = [
      HomeScreen(onCameraTap: () => setState(() => _currentTab = 1)),
      const LensScreen(),
      const MemoriesScreen(),
      const FamilyScreen(),
    ];

    return MaterialApp(
      title: 'Ala-ala',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: beigeBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: goldAccent,
          surface: creamSurface,
        ),
        textTheme: ThemeData.light().textTheme.apply(
              fontFamily: 'sans-serif',
              bodyColor: darkText,
              displayColor: darkText,
            ),
        cardTheme: const CardThemeData(
          color: creamSurface,
          elevation: 0,
          margin: EdgeInsets.zero,
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: IndexedStack(
            index: _currentTab,
            children: pages,
          ),
        ),
        bottomNavigationBar: NavigationBar(
          backgroundColor: creamSurface,
          indicatorColor: goldAccent.withValues(alpha: 0.15),
          selectedIndex: _currentTab,
          onDestinationSelected: (index) {
            setState(() {
              _currentTab = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded, color: goldAccent),
              label: 'Tahanan',
            ),
            NavigationDestination(
              icon: Icon(Icons.camera_alt_outlined),
              selectedIcon: Icon(Icons.camera_alt_rounded, color: goldAccent),
              label: 'MemoryLens',
            ),
            NavigationDestination(
              icon: Icon(Icons.auto_stories_outlined),
              selectedIcon: Icon(Icons.auto_stories_rounded, color: goldAccent),
              label: 'Alaala',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people_rounded, color: goldAccent),
              label: 'Pamilya',
            ),
          ],
        ),
      ),
    );
  }
}
