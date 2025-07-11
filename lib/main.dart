import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'models/icons_preserver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  IconPreserver.preserveIcons();
  runApp(
    const ProviderScope(
        child: MyApp(),
      ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottom Tab App',
      home: MainTabScreen(),
    );
  }
}

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});
  @override
  MainTabScreenState createState() => MainTabScreenState();
}

class MainTabScreenState extends State<MainTabScreen> {
  int _selectedIndex = 0; // Start on Explore tab
  
  // Navigation callback function
  void navigateToLibrary() {
    setState(() {
      _selectedIndex = 2; // Library screen is at index 2
    });
  }
  
  // Build screens with navigation callback
  List<Widget> get _screens => [
    ExploreScreen(onNavigateToLibrary: navigateToLibrary),
    HomeScreen(onNavigateToLibrary: navigateToLibrary),
    LibraryScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Library',
          ),
        ],
      ),
    );
  }
}