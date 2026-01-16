import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

// BLoCs
import '../bloc/mood_bloc.dart';

// Services & Models
import '../auth/services/auth_service.dart';

// Widgets
import '../widgets/streak_card.dart';
import '../widgets/recommendation_tile.dart';

// Pages & Navigation
import '../config/api_keys.dart';
import 'notifications_page.dart';
import 'main_navigation_page.dart';
import 'statistics_page.dart';
import 'daily_reflection_page.dart';

class MyHomePage extends StatefulWidget {
  final AuthService authService;
  const MyHomePage({super.key, required this.authService});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  
  // --- HELPERS: MOOD MAPPING LOGIC ---

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

  int _getDurationForMood(String mood) {
    switch (mood) {
      case 'Great': return 5;
      case 'Good': return 10;
      case 'Okay': return 15;
      case 'Sad': return 20;
      case 'Awful': return 30;
      default: return 10;
    }
  }

  String _getMeditationTitle(String mood) {
    int minutes = _getDurationForMood(mood);
    switch (mood) {
      case 'Great': return "$minutes-Min Joy Anchor";
      case 'Good': return "$minutes-Min Daily Balance";
      case 'Okay': return "$minutes-Min Mindful Reset";
      case 'Sad': return "$minutes-Min Deep Calm";
      case 'Awful': return "$minutes-Min Stress Relief";
      default: return "$minutes-Min Meditation";
    }
  }

  // --- API CALL FOR MUSIC ---

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
      debugPrint('Error fetching music: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        title: _buildHeader(context),
        actions: [
          IconButton(
            icon: Icon(
              Icons.logout,
              color: Theme.of(context).iconTheme.color,
            ),
            tooltip: 'Logout',
            onPressed: () => widget.authService.signOut(),
          ),
        ],
      ),
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
                  Text(
                    "How are you feeling today?",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

                  // --- DYNAMIC RECOMMENDATIONS ---
                  if (state.todayMood != null) ...[
                    // 1. Meditation Recommendation based on Mood Timer
                    RecommendationTile(
                      icon: Icons.self_improvement,
                      title: _getMeditationTitle(state.todayMood!),
                      subtitle: "Ideal duration for your ${state.todayMood} mood",
                      backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
                      onTap: () {
                        MainNavigationPage.of(context)?.changeTab(
                          2,
                          suggestedMinutes: _getDurationForMood(state.todayMood!),
                        );
                      },
                    ),

                    // 2. Music Recommendation based on API fetch
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _fetchMoodMusic(state.todayMood!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: LinearProgressIndicator(),
                          );
                        }
                        if (snapshot.hasData && snapshot.data != null) {
                          return RecommendationTile(
                            icon: Icons.auto_awesome,
                            title: "Perfect music for your mood",
                            subtitle: snapshot.data!['name'] ?? "Tap to listen",
                            backgroundColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.9),
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
                  ],

                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final user = widget.authService.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Good Morning,",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
            ),
            Text(
              displayName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const Spacer(),
        Row(
          children: [
            _headerCircleButton(
              icon: Icons.bar_chart_rounded,
              color: Theme.of(context).colorScheme.primary,
              bgColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const TestPage())),
            ),
            const SizedBox(width: 8),
            _headerCircleButton(
              icon: Icons.notifications_none,
              color: Theme.of(context).iconTheme.color ?? Theme.of(context).colorScheme.onSurface,
              bgColor: Theme.of(context).colorScheme.surfaceVariant,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationsPage())),
            ),
          ],
        ),
      ],
    );
  }

  Widget _headerCircleButton({required IconData icon, required Color color, required Color bgColor, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: color), onPressed: onPressed),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
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
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isSelected
                ? Theme.of(context).colorScheme.onPrimaryContainer
                : Theme.of(context).iconTheme.color?.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}