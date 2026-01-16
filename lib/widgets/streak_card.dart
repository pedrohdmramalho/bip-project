import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streakCount;
  final double progress;

  const StreakCard({
    super.key,
    required this.streakCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print("Navigation vers les détails du streak");
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF3E5F5),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.deepPurple,
              size: 40,
            ),
            Text(
              "$streakCount",
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            const Text(
              "Day Streak!",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            const Text(
              "You've checked in every day this week. Keep the momentum going.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Colors.white,
                color: Colors.deepPurple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
