import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:starteu/auth/services/auth_service.dart';
import 'package:starteu/bloc/mood_bloc.dart';
import 'package:starteu/pages/notifications_page.dart';
import 'package:starteu/pages/daily_reflection_page.dart';
import 'package:starteu/widgets/recommendation_tile.dart';
import 'package:starteu/widgets/streak_card.dart';
import 'main_navigation_page.dart';

class MyHomePage extends StatefulWidget {
  final AuthService authService;

  const MyHomePage({super.key, required this.authService});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: _buildHeader(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            tooltip: 'Logout',
            onPressed: () {
              widget.authService.signOut();
            },
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

                  RecommendationTile(
                    icon: Icons.spa,
                    title: "5-Min Morning Zen",
                    subtitle: "A quick session to start your day focused.",
                    backgroundColor: const Color(0xFFE3F2FD),
                    onTap: () {
                      MainNavigationPage.of(context)?.changeTab(2);
                    },
                  ),
                  RecommendationTile(
                    icon: Icons.headphones,
                    title: "Calming Music",
                    subtitle: "Listen to ambient sounds for deep focus.",
                    backgroundColor: const Color(0xFFFFF3E0),
                    onTap: () {
                      MainNavigationPage.of(context)?.changeTab(1);
                    },
                  ),
                  RecommendationTile(
                    icon: Icons.edit_note,
                    title: "Daily Reflection",
                    subtitle: "Write down three things you're grateful for.",
                    backgroundColor: const Color(0xFFE8F5E9),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const DailyReflectionPage(),
                        ),
                      );
                    },
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

  Widget _buildHeader(BuildContext context) {
    final user = widget.authService.currentUser;
    final displayName = user?.displayName ?? 'User';

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Hello,",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsPage(),
                ),
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
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        TextButton(
          onPressed: () {},
          child: const Text(
            "See all",
            style: TextStyle(color: Colors.deepPurple),
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
            color: isSelected ? Colors.deepPurple : Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
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
