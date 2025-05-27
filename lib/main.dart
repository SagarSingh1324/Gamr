import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/library_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodels/explore_viewmodel.dart';

void main() async{
  await dotenv.load(fileName: ".env");
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ExploreViewModel(),
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

  int _selectedIndex = 1; // Start on Home tab

  final List<Widget> _screens = [
    ExploreScreen(),
    HomeScreen(),
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
