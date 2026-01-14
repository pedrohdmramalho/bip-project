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
  String? _libraryCategory; // Stocke la catégorie cible

  // Mise à jour de la fonction pour accepter la catégorie
  void changeTab(int index, {String? libraryCategory}) {
    setState(() {
      _selectedIndex = index;
      _libraryCategory = libraryCategory;
    });
  }

  @override
  Widget build(BuildContext context) {
    // On définit les pages ici pour injecter la catégorie dynamiquement
    final List<Widget> _pages = [
      const MyHomePage(),
      LibraryPage(title: "Library", initialCategory: _libraryCategory),
      const MeditationPage(),
      const Center(child: Text('Profile')),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Si on change d'onglet manuellement, on réinitialise le filtre
          if (index != 1) {
            setState(() {
              _libraryCategory = null;
            });
          }
          changeTab(index);
        },
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