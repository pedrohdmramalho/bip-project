import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert'; // Pour décoder le JSON de l'API
import 'package:http/http.dart' as http; // Pour l'appel API
import '../config/api_keys.dart'; // Pour ta clé API
import '../bloc/mood_bloc.dart';
import '../widgets/streak_card.dart';
import '../widgets/recommendation_tile.dart';
import 'notifications_page.dart'; 
import 'main_navigation_page.dart'; 

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key});
  
  // --- MAPPING COHÉRENT : MOOD -> CATÉGORIE LIBRARY ---
  String _getLibraryCategoryForMood(String mood) {
    switch (mood) {
      case 'Great': return 'Chill';
      case 'Good': return 'Focus';
      case 'Okay': return 'Meditation';
      case 'Sad': return 'Anxiety';
      case 'Awful': return 'Sleep';
      default: return 'All';
    }
  }

  // --- LOGIQUE DE MAPPING MOOD -> REQUÊTE API FREESOUND ---
  String _getQueryForMood(String mood) {
    switch (mood) {
      case 'Great': return 'chill lofi relax';
      case 'Good': return 'concentration study focus';
      case 'Okay': return 'meditation zen mindfulness';
      case 'Sad': return 'calm peaceful stress relief';
      case 'Awful': return 'sleep relaxing ambient';
      default: return 'relaxing';
    }
  }

  // --- APPEL API POUR RÉCUPÉRER UNE PISTE CORRESPONDANTE ---
  Future<Map<String, dynamic>?> _fetchMoodMusic(String mood) async {
    final query = _getQueryForMood(mood);
    final url = Uri.parse(
      'https://freesound.org/apiv2/search/text/?query=$query&fields=name&token=${ApiKeys.freesoundApiKey}&page_size=1'
    );
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          return data['results'][0];
        }
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: BlocBuilder<MoodBloc, MoodState>(
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildHeader(context), 
                  const SizedBox(height: 30),
                  
                  const Text(
                    "How are you feeling today?",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  
                  _buildMoodRow(context, state.todayMood),
                  const SizedBox(height: 30),

                  StreakCard(
                    streakCount: state.streakCount,
                    progress: (state.streakCount % 7) / 7,
                  ),
                  
                  const SizedBox(height: 30),
                  _buildSectionHeader("Today's Recommendations"),
                  const SizedBox(height: 15),

                  // --- RECOMMANDATION DYNAMIQUE BASÉE SUR L'HUMEUR ---
                  if (state.todayMood != null)
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchMoodMusic(state.todayMood!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 15),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return RecommendationTile(
                            icon: Icons.auto_awesome,
                            title: "Perfect for your ${state.todayMood} mood",
                            subtitle: snapshot.data!['name'] ?? "Tap to listen",
                            backgroundColor: const Color(0xFFF3E5F5), 
                            onTap: () {
                              final category = _getLibraryCategoryForMood(state.todayMood!);
                              MainNavigationPage.of(context)?.changeTab(
                                1, 
                                libraryCategory: category,
                              );
                            },
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                  // --- RECOMMANDATIONS STATIQUES ---
                  RecommendationTile(
                    icon: Icons.spa,
                    title: "5-Min Morning Zen",
                    subtitle: "A quick session to start your day focused.",
                    backgroundColor: const Color(0xFFE3F2FD),
                    onTap: () => MainNavigationPage.of(context)?.changeTab(2),
                  ),

                  RecommendationTile(
                    icon: Icons.headphones,
                    title: "Calming Music",
                    subtitle: "Listen to ambient sounds for deep focus.",
                    backgroundColor: const Color(0xFFFFF3E0),
                    onTap: () => MainNavigationPage.of(context)?.changeTab(1),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION ---

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good Morning,", style: TextStyle(color: Colors.grey, fontSize: 14)),
            // TODO: Implement dynamic user name retrieval (e.g. from Firebase Auth)
            Text("User", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
        Container(
          decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const NotificationsPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {},
          child: const Text("See all", style: TextStyle(color: Colors.deepPurple)),
        ),
      ],
    );
  }

  Widget _buildMoodRow(BuildContext context, String? currentMood) {
    final List<Map<String, dynamic>> moods = [
      {'icon': Icons.sentiment_very_satisfied, 'label': 'Great'},
      {'icon': Icons.sentiment_satisfied, 'label': 'Good'},
      {'icon': Icons.sentiment_neutral, 'label': 'Okay'},
      {'icon': Icons.sentiment_dissatisfied, 'label': 'Sad'},
      {'icon': Icons.sentiment_very_dissatisfied, 'label': 'Awful'},
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: moods.map((mood) {
        final bool isSelected = currentMood == mood['label'];
        return GestureDetector(
          onTap: () => context.read<MoodBloc>().add(SelectMood(mood['label'])),
          child: _moodItem(mood['icon'], mood['label'], isSelected),
        );
      }).toList(),
    );
  }

  Widget _moodItem(IconData icon, String label, bool isSelected) {
    return Column(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.deepPurple : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: isSelected ? Colors.white : Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.deepPurple : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}