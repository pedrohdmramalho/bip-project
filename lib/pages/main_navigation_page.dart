import 'package:flutter/material.dart';
import 'package:starteu/auth/services/auth_service.dart';
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
  Map<String, dynamic>? _selectedMusicForMeditation;
  String? _libraryCategory; 
  int? _suggestedMinutes; 

  void changeTab(int index, {String? libraryCategory, int? suggestedMinutes}) {
    setState(() {
      _selectedIndex = index;
      _libraryCategory = libraryCategory;
      _suggestedMinutes = suggestedMinutes;
    });
  }

  void setMeditationMusic(Map<String, dynamic> music) {
    setState(() {
      _selectedMusicForMeditation = music;
      _selectedIndex = 2;
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return MyHomePage(authService: widget.authService);
      case 1:
        return LibraryPage(title: "Library", initialCategory: _libraryCategory);
      case 2:
        return MeditationPage(
          selectedMusic: _selectedMusicForMeditation,
          suggestedMinutes: _suggestedMinutes, // Transmission du timer basé sur l'humeur
        );
      case 3:
        return const Center(child: Text('Profile'));
      default:
        return MyHomePage(authService: widget.authService);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getPage(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          // Réinitialise la catégorie si on quitte l'onglet Library
          if (index != 1 && _selectedIndex == 1) {
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