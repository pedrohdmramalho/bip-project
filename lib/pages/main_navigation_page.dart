import 'package:flutter/material.dart';
import 'my_homepage.dart';
import 'library_page.dart';
import 'meditation_page.dart';

class MainNavigationPage extends StatefulWidget {
const MainNavigationPage({super.key});

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

final List<Widget> _pages = [
  const MyHomePage(),
  const LibraryPage(title: "Library"),
  const MeditationPage(),
  const Center(child: Text('Profile')),
];

@override
Widget build(BuildContext context) {
  return Scaffold(
    body: _pages[_selectedIndex],
    bottomNavigationBar: BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) => changeTab(index), // Utilise la méthode changeTab
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.library_music_rounded), label: 'Library'),
        BottomNavigationBarItem(icon: Icon(Icons.self_improvement), label: 'Meditate'),
        BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
      ],
    ),
  );
}
}