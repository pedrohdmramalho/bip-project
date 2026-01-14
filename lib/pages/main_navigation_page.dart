import 'package:flutter/material.dart';
import 'package:starteu/auth/services/auth_service.dart'; // Import AuthService
import 'my_homepage.dart';
import 'library_page.dart';
import 'meditation_page.dart';

class MainNavigationPage extends StatefulWidget {
  final AuthService authService;

  const MainNavigationPage({super.key, required this.authService});

  static _MainNavigationPageState? of(BuildContext context) =>
      context.findAncestorStateOfType<_MainNavigationPageState>();

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _selectedIndex = 0;

  void changeTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    // Initialize pages here to pass the authService correctly
    _pages = [
      MyHomePage(authService: widget.authService), // Pass service to Home
      const LibraryPage(title: "Library"),
      const MeditationPage(),
      const Center(child: Text('Profile')),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => changeTab(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.deepPurple,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_rounded),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.self_improvement),
            label: 'Meditate',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
