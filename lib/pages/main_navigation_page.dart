import 'package:flutter/material.dart';
import 'package:starteu/auth/services/auth_service.dart';
import 'my_homepage.dart';
import 'library_page.dart';
import 'meditation_page.dart';
import 'profile_page.dart';

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

  void changeTab(int index, {String? libraryCategory}) {
    setState(() {
      _selectedIndex = index;
      if (libraryCategory != null) {
        _libraryCategory = libraryCategory;
      }
    });
  }

  void setMeditationMusic(Map<String, dynamic> music) {
    setState(() {
      _selectedMusicForMeditation = music;
      _selectedIndex = 2; // Switch to meditation tab
    });
  }

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return MyHomePage(authService: widget.authService);
      case 1:
        return LibraryPage(title: "Library", initialCategory: _libraryCategory);
      case 2:
        return MeditationPage(selectedMusic: _selectedMusicForMeditation);
      case 3:
        return ProfilePage(authService: widget.authService);
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
