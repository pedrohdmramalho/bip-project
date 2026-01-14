import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_keys.dart';
import 'main_navigation_page.dart';

class LibraryPage extends StatefulWidget {
  final String title;
  final String? initialCategory; 

  const LibraryPage({super.key, required this.title, this.initialCategory});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _currentPlayingId;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  List<Map<String, dynamic>> _musicList = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';
  
  
  final List<String> _categories = ['All', 'Sleep', 'Anxiety', 'Focus', 'Chill', 'Meditation'];
  
  final Map<String, String> _categoryQueries = {
    'Sleep': 'sleep relaxing ambient',
    'Anxiety': 'calm peaceful stress relief',
    'Focus': 'concentration study focus',
    'Chill': 'chill lofi relax',
    'Meditation': 'meditation zen mindfulness',
  };

  String _getUnsplashImage(String category, int index) {
    final categorySeeds = {
      'Sleep': 100,
      'Anxiety': 200,
      'Focus': 300,
      'Chill': 400,
      'Meditation': 500,
    };
    final baseSeed = categorySeeds[category] ?? 600;
    final seed = baseSeed + index;
    // Picsum Photos API
    return 'https://picsum.photos/seed/$seed/400/200';
  }

  String _formatDurationString(dynamic duration) {
    int seconds = 0;
    if (duration is int) {
      seconds = duration;
    } else if (duration is String) {
      seconds = int.tryParse(duration) ?? 0;
    } else if (duration is double) {
      seconds = duration.round();
    }
    final minutes = (seconds ~/ 60).toString();
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return "$minutes:$secs";
  }

  Future<void> fetchFreesoundTracks() async {
    setState(() => _isLoading = true);
    
    List<Map<String, dynamic>> allTracks = [];
    try {
      for (var category in _categories) {
        if (category == 'All') continue;
        
        final query = _categoryQueries[category] ?? 'relaxing';
        final url = Uri.parse(
          'https://freesound.org/apiv2/search/text/?query=$query&fields=id,name,previews,duration&token=${ApiKeys.freesoundApiKey}&page_size=10'
        );
        
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final List results = data['results'] ?? [];
          
          allTracks.addAll(results.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return {
              'id': '${category}_${item['id']}',
              'title': item['name'] ?? 'No title',
              'duration': (item['duration'] ?? 0).toStringAsFixed(0),
              'category': category,
              'imageUrl': _getUnsplashImage(category, index),
              'audioPath': item['previews']?['preview-hq-mp3'] ?? item['previews']?['preview-lq-mp3'] ?? '',
            };
          }).where((track) => track['audioPath'].toString().isNotEmpty));
        }
      }
    } catch (e) {
      allTracks = _getExampleTracks();
    }
    
    setState(() {
      _musicList = allTracks;
      _isLoading = false;
    });
  }
  
  List<Map<String, dynamic>> _getExampleTracks() {
    return [
      {
        'id': 'example_1',
        'title': 'Peaceful Night',
        'duration': '180',
        'category': 'Sleep',
        'imageUrl': _getUnsplashImage('Sleep', 0),
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      },
      {
        'id': 'example_2',
        'title': 'Calm Waves',
        'duration': '240',
        'category': 'Anxiety',
        'imageUrl': _getUnsplashImage('Anxiety', 1),
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      },
      {
        'id': 'example_3',
        'title': 'Deep Focus',
        'duration': '300',
        'category': 'Focus',
        'imageUrl': _getUnsplashImage('Focus', 2),
        'audioPath': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      },
    ];
  }

  List<Map<String, dynamic>> get _filteredMusicList {
    var filtered = _musicList;
    
    if (_selectedCategory != 'All') {
      filtered = filtered.where((music) => music['category'] == _selectedCategory).toList();
    }
    
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((music) {
        final title = (music['title'] ?? '').toString().toLowerCase();
        final category = (music['category'] ?? '').toString().toLowerCase();
        return title.contains(query) || category.contains(query);
      }).toList();
    }
    
    return filtered;
  }

  @override
  void initState() {
    super.initState();
    // Utilise la catégorie initiale si elle est fournie, sinon 'All'
    _selectedCategory = widget.initialCategory ?? 'All';
    _setupAudioPlayer();
    fetchFreesoundTracks();
}

  void _setupAudioPlayer() {
    _audioPlayer.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _audioPlayer.onPositionChanged.listen((position) {
      setState(() => _position = position);
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      setState(() {
        _isPlaying = false;
        _currentPlayingId = null;
        _position = Duration.zero;
      });
    });
  }

  Future<void> _togglePlayPause(String id, String audioPath) async {
    if (_currentPlayingId == id && _isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
    } else {
      if (_currentPlayingId != id) {
        await _audioPlayer.stop();
        if (audioPath.startsWith('http')) {
          await _audioPlayer.play(UrlSource(audioPath));
        } else {
          await _audioPlayer.play(AssetSource(audioPath.replaceFirst('assets/', '')));
        }
      } else {
        await _audioPlayer.resume();
      }
      setState(() {
        _isPlaying = true;
        _currentPlayingId = id;
      });
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 15,
              child: Icon(Icons.person, size: 20),
            ),
          )
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: "Search for peace, focus, or sleep...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    selectedColor: Colors.deepPurple,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMusicList.isEmpty
                    ? const Center(child: Text('No music found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredMusicList.length,
                        itemBuilder: (context, index) {
                          final music = _filteredMusicList[index];
                          return _buildMusicCard(music);
                        },
                      ),
          ),

          if (_currentPlayingId != null) _buildMiniPlayer(),
        ],
      ),
    );
    
  }

  Widget _buildMusicCard(Map<String, dynamic> data) {
    final bool isCurrentlyPlaying = _currentPlayingId == data['id'] && _isPlaying;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.network(
              data['imageUrl'] ?? 'https://via.placeholder.com/400x200',
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: const Icon(Icons.music_note, size: 50),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['title'] ?? 'Bez tytułu',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_formatDurationString(data['duration'])} • ${data['category'] ?? 'Relaxing'}",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _togglePlayPause(data['id'], data['audioPath']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCurrentlyPlaying
                              ? Colors.deepPurple
                              : Colors.deepPurple[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCurrentlyPlaying ? Icons.pause : Icons.play_arrow,
                          color: isCurrentlyPlaying ? Colors.white : Colors.deepPurple,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          MainNavigationPage.of(context)?.setMeditationMusic(data);
                        },
                        icon: const Icon(Icons.self_improvement),
                        label: const Text('Use for Meditation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.deepPurple,
                          side: const BorderSide(color: Colors.deepPurple),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniPlayer() {
    final currentMusic = _musicList.firstWhere(
      (m) => m['id'] == _currentPlayingId,
      orElse: () => {},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  currentMusic['imageUrl'] ?? '',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.music_note),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentMusic['title'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      currentMusic['category'] ?? '',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                onPressed: () => _togglePlayPause(
                  currentMusic['id'],
                  currentMusic['audioPath'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: _position.inSeconds.toDouble(),
              max: _duration.inSeconds.toDouble(),
              activeColor: Colors.deepPurple,
              onChanged: (value) async {
                await _audioPlayer.seek(Duration(seconds: value.toInt()));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(_position),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  _formatDuration(_duration),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}