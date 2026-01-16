import 'package:flutter/material.dart';

class StreakCard extends StatelessWidget {
  final int streakCount;
  final double progress; // Valeur entre 0.0 et 1.0

  const StreakCard({
    super.key,
    required this.streakCount,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: () {
        // Logique de navigation vers les détails du streak ici
        print("Navigation vers les détails du streak");
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Icon(Icons.local_fire_department, color: colorScheme.primary, size: 40),
            Text(
              "$streakCount",
              style: textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            Text(
              "Day Streak!",
              style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "You've checked in every day this week. Keep the momentum going.",
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: textTheme.bodySmall?.color?.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 15),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}