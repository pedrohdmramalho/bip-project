import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/mood_bloc.dart';
import '../widgets/mood_chart.dart';
import '../data/repositories/meditation_repository.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final MeditationRepository _repository = MeditationRepository();
  Map<String, int> _meditationCounts = {};
  bool _isLoading = true;

  late DateTime _currentMonth;
  final List<String> _weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    final counts = await _repository.getMeditationCounts("user_123");
    if (mounted) {
      setState(() {
        _meditationCounts = counts;
        _isLoading = false;
      });
    }
  }

  Color _getStepColor(int count) {
    if (count == 0) return Colors.grey.withOpacity(0.1);
    if (count == 1) return Colors.deepPurple.withOpacity(0.3);
    if (count == 2) return Colors.deepPurple.withOpacity(0.6);
    return Colors.deepPurple;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          "Analytics",
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your Mood Progress",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            BlocBuilder<MoodBloc, MoodState>(
              builder: (context, state) =>
                  MoodChart(scores: state.weeklyScores),
            ),

            const SizedBox(height: 40),
            const Text(
              "Meditation Activity",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
              ),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Text(
                          DateFormat('MMMM yyyy').format(_currentMonth),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: _weekDays
                              .map(
                                (day) => Text(
                                  day,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 10),
                        _buildCalendarGrid(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final daysInMonth = DateTime(
      _currentMonth.year,
      _currentMonth.month + 1,
      0,
    ).day;
    final firstDayOffset =
        DateTime(_currentMonth.year, _currentMonth.month, 1).weekday - 1;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: daysInMonth + firstDayOffset,
      itemBuilder: (context, index) {
        if (index < firstDayOffset) return const SizedBox.shrink();

        final day = index - firstDayOffset + 1;
        final dateKey =
            "${_currentMonth.year}-${_currentMonth.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";
        final count = _meditationCounts[dateKey] ?? 0;

        return Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _getStepColor(count),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "$day",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: count > 1
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        );
      },
    );
  }
}
