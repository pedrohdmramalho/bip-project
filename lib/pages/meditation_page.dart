import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'main_navigation_page.dart';
import '../data/repositories/meditation_repository.dart';

class SmoothBreathCurve extends Curve {
  const SmoothBreathCurve();

  @override
  double transformInternal(double t) {
    return _smoothstep(t);
  }
  
  double _smoothstep(double t) {
    return t * t * (3.0 - 2.0 * t);
  }
}

class BreathingFlowerPainter extends CustomPainter {
  final double progress;

  BreathingFlowerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width * 0.3;
    
    const numPetals = 5;
    for (int i = 0; i < numPetals; i++) {
      final angle = (2 * pi * i) / numPetals - pi / 2;
      
      final petalScale = 0.7 + (progress * 0.3);
      final petalRadius = baseRadius * petalScale;
      
      final petalX = center.dx + cos(angle) * baseRadius * 0.6;
      final petalY = center.dy + sin(angle) * baseRadius * 0.6;
      
      final paint = Paint()
        ..color = Color.lerp(
          const Color(0xFF7C3AED).withOpacity(0.4),
          const Color(0xFF7C3AED).withOpacity(0.8),
          progress,
        )!
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(
        Offset(petalX, petalY),
        petalRadius,
        paint,
      );
    }
    
    final centerPaint = Paint()
      ..color = const Color(0xFF7C3AED)
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, baseRadius * 0.3, centerPaint);
  }

  @override
  bool shouldRepaint(BreathingFlowerPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class MeditationPage extends StatefulWidget {
  final Map<String, dynamic>? selectedMusic;
  final int? suggestedMinutes;

  const MeditationPage({super.key, this.selectedMusic, this.suggestedMinutes});

  @override
  State<MeditationPage> createState() => _MeditationPageState();
}

class _MeditationPageState extends State<MeditationPage>
    with TickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late int _selectedMinutes;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  final MeditationRepository _meditationRepository = MeditationRepository();
  
  bool _isSessionActive = false;
  bool _isPaused = false;
  Duration _sessionDuration = Duration.zero;
  Duration _elapsedTime = Duration.zero;
  Timer? _sessionTimer;
  
  Map<String, dynamic>? _currentMusic;
  bool _isPlayingMusic = false;
  Duration _musicPosition = Duration.zero;
  Duration _musicDuration = Duration.zero;
  
  bool _showMusicSelector = false;
  List<Map<String, dynamic>> _meditationMusicList = [];
  bool _isMusicLoading = false;
  
  String? _previewPlayingId; 
  bool _isPreviewPlaying = false;

  final List<String> _affirmations = [
    'Find peace within yourself',
    'Breathe slowly and deeply',
    'Let go of stress and worry',
    'You are calm and centered',
    'Every breath brings clarity',
  ];

  Future<void> _endSession() async {
    await _audioPlayer.stop();
    _sessionTimer?.cancel();
    
    final String formattedDuration = _formatDuration(_elapsedTime);
    final String sessionTitle = _currentMusic?['title'] ?? 'General Meditation';
    
    await _meditationRepository.saveCompletedSession(
      userId: "user_123", 
      title: sessionTitle,
      duration: formattedDuration,
    );

    setState(() {
      _isSessionActive = false;
      _isPaused = false;
      _isPlayingMusic = false;
      _breathingController.repeat();
    });

    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Meditation Complete!'),
          content: Text('Session saved: $formattedDuration meditated.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.suggestedMinutes ?? 25;
    _breathingController = AnimationController(
      duration: const Duration(seconds: 10),
      
      vsync: this,
    )..repeat(reverse: true);
    
    _breathingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const SmoothBreathCurve(),
      ),
    );
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // If music is selected from library, use it
    if (widget.selectedMusic != null) {
      _currentMusic = widget.selectedMusic;
    }
    _loadMeditationMusic();
  }
  
  Future<void> _togglePreviewPlayback(String musicId, String audioPath) async {
    if (_previewPlayingId == musicId && _isPreviewPlaying) {
      // Stop playing
      await _audioPlayer.stop();
      setState(() {
        _previewPlayingId = null;
        _isPreviewPlaying = false;
      });
    } else {
      // Start playing
      if (_previewPlayingId != musicId) {
        await _audioPlayer.stop();
        if (audioPath.isNotEmpty) {
          try {
            await _audioPlayer.play(UrlSource(audioPath), volume: 0.6);
            setState(() {
              _previewPlayingId = musicId;
              _isPreviewPlaying = true;
            });
          } catch (e) {
            debugPrint('Error playing preview: $e');
          }
        }
      } else {
        // Resume paused preview
        await _audioPlayer.resume();
        setState(() => _isPreviewPlaying = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text("Meditation", style: TextStyle(fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 2,
        foregroundColor: Colors.black,
      ),
      body: _isSessionActive 
          ? _buildSessionUI()
          : _buildSetupUI(),
    );
  }

  Widget _buildSetupUI() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 30),
            
            // Affirmation
            Text(
              _affirmations[DateTime.now().microsecond % _affirmations.length],
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
            
            const SizedBox(height: 50),
            
            // Time selector card
            _buildTimeSelectorCard(),
            
            const SizedBox(height: 40),
            
            // Music selector card
            _buildMusicSelectorCard(),
            
            const SizedBox(height: 40),
            
            // Start button
            _buildStartButton(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingAnimation() {
    return AnimatedBuilder(
      animation: Listenable.merge([_breathingAnimation, _pulseAnimation]),
      builder: (context, child) {
        final scale = 0.6 + (_breathingAnimation.value * 0.4);
        
        return Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // Outer pulsing ring
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Container(
                    width: 220 * _pulseAnimation.value,
                    height: 220 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.1),
                        width: 2,
                      ),
                    ),
                  ),
                ),
                
                // Main breathing circle
                Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.deepPurple.withOpacity(0.4),
                          Colors.deepPurple.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.deepPurple.withOpacity(0.6),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.withOpacity(0.2),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🧘',
                            style: TextStyle(fontSize: 70),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Breathing text
            AnimatedOpacity(
              opacity: _breathingAnimation.value < 0.5 ? 1.0 : 0.6,
              duration: const Duration(milliseconds: 500),
              child: Text(
                _breathingAnimation.value < 0.5 ? 'Inhale' : 'Exhale',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.deepPurple,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTimeSelectorCard() {
    final times = [5, 10, 15, 20, 25, 30];
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Session Duration',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: times.map((time) {
              final isSelected = _selectedMinutes == time;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: !_isSessionActive
                      ? () => setState(() => _selectedMinutes = time)
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.deepPurple
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? Colors.deepPurple
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    child: Text(
                      '$time min',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : Colors.grey[700],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMusicSelectorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Background Music',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          if (_currentMusic != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.deepPurple.withOpacity(0.05),
                    Colors.deepPurple.withOpacity(0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _currentMusic!['imageUrl'] ?? '',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.music_note),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentMusic!['title'] ?? 'Unknown',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _formatDuration(Duration(
                            seconds: int.tryParse(
                              _currentMusic!['duration'].toString(),
                            ) ?? 0,
                          )),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey[600],
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() => _currentMusic = null);
                    },
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No music selected',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          
          const SizedBox(height: 12),
          
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                setState(() => _showMusicSelector = !_showMusicSelector);
              },
              icon: Icon(
                _showMusicSelector ? Icons.expand_less : Icons.expand_more,
              ),
              label: Text(
                _showMusicSelector 
                    ? 'Hide Library' 
                    : 'Choose from Library',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepPurple,
                side: const BorderSide(color: Colors.deepPurple),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          if (_showMusicSelector) ...[
            const SizedBox(height: 12),
            _isMusicLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.deepPurple,
                        ),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 180,
                    child: ListView.builder(
                      itemCount: _meditationMusicList.length,
                      itemBuilder: (context, index) {
                        final music = _meditationMusicList[index];
                        final isSelected = _currentMusic?['id'] == music['id'];
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Material(
                            color: isSelected
                                ? Colors.deepPurple.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _currentMusic = music;
                                  _showMusicSelector = false;
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8.0,
                                  vertical: 4.0,
                                ),
                                child: ListTile(
                                  dense: true,
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      music['imageUrl'] ?? '',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        width: 40,
                                        height: 40,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.music_note,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    music['title'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.deepPurple
                                          : Colors.black87,
                                    ),
                                  ),
                                  subtitle: Text(
                                    _formatDuration(Duration(
                                      seconds: int.tryParse(
                                        music['duration'].toString(),
                                      ) ?? 0,
                                    )),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.check_circle,
                                          color: Colors.deepPurple,
                                          size: 20,
                                        )
                                      : IconButton(
                                          icon: Icon(
                                            _previewPlayingId == music['id'] && _isPreviewPlaying
                                                ? Icons.pause_circle
                                                : Icons.play_circle_outline,
                                            color: Colors.deepPurple,
                                            size: 20,
                                          ),
                                          onPressed: () => _togglePreviewPlayback(
                                            music['id'] ?? '',
                                            music['audioPath'] ?? '',
                                          ),
                                          constraints: const BoxConstraints(
                                            minWidth: 32,
                                            minHeight: 32,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurple, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _startSession,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Text(
                  'Start Meditation',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSessionUI() {
    final timeRemaining = _sessionDuration - _elapsedTime;
    final progressValue = _elapsedTime.inSeconds / _sessionDuration.inSeconds;
    
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 240,
                    height: 240,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: Listenable.merge([_breathingAnimation, _pulseAnimation]),
                          builder: (context, child) {
                            final breatheScale = 0.6 + (_breathingAnimation.value * 0.4);
                            return Transform.scale(
                              scale: breatheScale,
                              child: CustomPaint(
                                size: const Size(200, 200),
                                painter: BreathingFlowerPainter(
                                  progress: _breathingAnimation.value,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Column(
                    children: [
                      Text(
                        _formatDuration(timeRemaining),
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: Colors.black87,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isPaused ? 'PAUSED' : 'BREATHING',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          iconSize: 32,
                          color: Colors.deepPurple,
                          onPressed: () {
                            setState(() {
                              if (_sessionDuration.inMinutes > 1) {
                                _sessionDuration = Duration(
                                  minutes: _sessionDuration.inMinutes - 1,
                                );
                              }
                            });
                          },
                        ),
                        Column(
                          children: [
                            Text(
                              '${_sessionDuration.inMinutes}',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              'minutes',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          iconSize: 32,
                          color: Colors.deepPurple,
                          onPressed: () {
                            setState(() {
                              _sessionDuration = Duration(
                                minutes: _sessionDuration.inMinutes + 1,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Session Progress',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${(progressValue * 100).toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.deepPurple,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: progressValue,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200],
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.deepPurple,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  if (_currentMusic != null && _isPlayingMusic)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.deepPurple.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _currentMusic!['imageUrl'] ?? '',
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.music_note,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Now Playing',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _currentMusic!['title'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border(
              top: BorderSide(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                  label: Text(_isPaused ? 'Resume' : 'Pause'),
                  onPressed: _pauseResumeSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.stop),
                  label: const Text('End Session'),
                  onPressed: _endSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setupBreathingAnimation() {
    _breathingController = AnimationController(
      duration: const Duration(seconds: 8),
      vsync: this,
    )..repeat();

    _breathingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _musicDuration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _musicPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) async {
      if (_isSessionActive && _currentMusic != null) {
        await _audioPlayer.play(
          UrlSource(_currentMusic!['audioPath'] ?? ''),
          volume: 0.6,
        );
      }
    });
  }

  Future<void> _loadMeditationMusic() async {
    if (!mounted) return;
    setState(() => _isMusicLoading = true);
    
    List<Map<String, dynamic>> allTracks = [];
    
    try {
      final storedExercises = await _meditationRepository.fetchExercises();
      
      if (storedExercises.isNotEmpty) {
        allTracks = storedExercises.map((e) => {
          'id': e.id,
          'title': e.title,
          'duration': e.durationInMinutes.toString(),
          'imageUrl': e.imageUrl,
          'audioPath': e.audioUrl,
        }).toList();
      } else {

        final url = Uri.parse(
          'https://freesound.org/apiv2/search/text/?query=meditation zen mindfulness&fields=id,name,previews,duration&token=${ApiKeys.freesoundApiKey}&page_size=15'
        );
        
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'] ?? [];
          
          allTracks = results.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return {
              'id': 'med_${item['id']}',
              'title': item['name'] ?? 'Untitled',
              'duration': (item['duration'] ?? 0).toStringAsFixed(0),
              'imageUrl': 'https://picsum.photos/seed/${500 + index}/400/200',
              'audioPath': item['previews']?['preview-hq-mp3'] ?? item['previews']?['preview-lq-mp3'] ?? '',
            };
          }).where((track) => track['audioPath'].toString().isNotEmpty).toList();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement musique: $e');
      allTracks = _getExampleMeditationTracks();
    }

    if (!mounted) return;
    setState(() {
      _meditationMusicList = allTracks.isNotEmpty ? allTracks : _getExampleMeditationTracks();
      _isMusicLoading = false;
    });
    
    setState(() {
      _meditationMusicList = allTracks.isNotEmpty ? allTracks : _getExampleMeditationTracks();
      _isMusicLoading = false;
    });
  }

  List<Map<String, dynamic>> _getExampleMeditationTracks() {
    return [
      {
        'id': 'med_example_1',
        'title': 'Peaceful Morning',
        'duration': '600',
        'imageUrl': 'https://picsum.photos/seed/501/400/200',
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      },
      {
        'id': 'med_example_2',
        'title': 'Zen Garden',
        'duration': '720',
        'imageUrl': 'https://picsum.photos/seed/502/400/200',
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      },
      {
        'id': 'med_example_3',
        'title': 'Ocean Waves',
        'duration': '540',
        'imageUrl': 'https://picsum.photos/seed/503/400/200',
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      },
    ];
  }

  void _selectRandomMusic() {
    if (_meditationMusicList.isEmpty) return;
    final random = _meditationMusicList[DateTime.now().microsecond % _meditationMusicList.length];
    setState(() {
      _currentMusic = random;
    });
  }

  void _startSession() async {
    if (_currentMusic == null && _meditationMusicList.isNotEmpty) {
      _selectRandomMusic();
    }

    setState(() {
      _isSessionActive = true;
      _isPaused = false;
      _sessionDuration = Duration(minutes: _selectedMinutes);
      _elapsedTime = Duration.zero;
    });

    // Start playing music
    if (_currentMusic != null && _currentMusic!['audioPath'].toString().isNotEmpty) {
      try {
        await _audioPlayer.play(
          UrlSource(_currentMusic!['audioPath'] ?? ''),
          volume: 0.6,
        );
        setState(() => _isPlayingMusic = true);
      } catch (e) {
        debugPrint('Error playing audio: $e');
      }
    }

    // Start session timer
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _elapsedTime = Duration(seconds: _elapsedTime.inSeconds + 1);
          
          if (_elapsedTime >= _sessionDuration) {
            _endSession();
            timer.cancel();
          }
        });
      }
    });
  }

  void _pauseResumeSession() {
    setState(() {
      _isPaused = !_isPaused;
      if (_isPaused) {
        _audioPlayer.pause();
      } else {
        _audioPlayer.resume();
      }
    });
  }


  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    _breathingController.dispose();
    _pulseController.dispose(); 
  
    _audioPlayer.dispose();
    _sessionTimer?.cancel();
    
    super.dispose();
  }
}