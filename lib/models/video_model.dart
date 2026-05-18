import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/supabase_service.dart';
import '../screens/video_player_screen.dart';

class VideoModel {
  final int id;
  final String title;
  final String description;
  final String coverUrl;
  final String videoUrl;
  final String category;
  final int duration;
  final int views;

  VideoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.videoUrl,
    required this.category,
    required this.duration,
    required this.views,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'],
      title: json['title'] ?? 'Título não disponível',
      description: json['description'] ?? 'Descrição não disponível',
      coverUrl: json['cover_url'] ?? '',
      videoUrl: json['video_url'] ?? '',
      category: json['category'] ?? 'Geral',
      duration: json['duration'] ?? 0,
      views: json['views'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'cover_url': coverUrl,
      'video_url': videoUrl,
      'category': category,
      'duration': duration,
      'views': views,
    };
  }
}

class VideoPlayerScreen extends StatefulWidget {
  final VideoModel video;
  
  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final SupabaseService _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _addToHistory();
  }

  Future<void> _addToHistory() async {
    await _supabaseService.addToHistory(widget.video.id);
  }

  Future<void> _initializeVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.video.videoUrl),
      );
      
      await _controller.initialize();
      
      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _position = _controller.value.position;
            _duration = _controller.value.duration;
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Erro ao inicializar vídeo: $e');
    }
  }

  void _togglePlayPause() {
    if (_controller.value.isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
    setState(() {});
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0 
        ? '$hours:$minutes:$seconds' 
        : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.9),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.video.title,
          style: GoogleFonts.poppins(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Player de vídeo
          AspectRatio(
            aspectRatio: _isInitialized ? _controller.value.aspectRatio : 16 / 9,
            child: _isInitialized
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      VideoPlayer(_controller),
                      // Controles sobrepostos
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            color: Colors.transparent,
                            child: Center(
                              child: AnimatedOpacity(
                                opacity: _isPlaying ? 0.0 : 0.7,
                                duration: const Duration(milliseconds: 300),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // Barra de progresso
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Slider(
                                value: _position.inSeconds.toDouble(),
                                min: 0,
                                max: _duration.inSeconds.toDouble(),
                                activeColor: const Color(0xFF6C63FF),
                                inactiveColor: Colors.white30,
                                onChanged: (value) {
                                  _seekTo(Duration(seconds: value.toInt()));
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _formatDuration(_position),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                    Text(
                                      _formatDuration(_duration),
                                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF6C63FF)),
                          SizedBox(height: 20),
                          Text('Carregando vídeo...', style: TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ),
          ),
          // Informações do vídeo
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.video.title,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF6C63FF)),
                        ),
                        child: Text(
                          widget.video.category,
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.video.views} visualizações',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const Icon(Icons.schedule, size: 16, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(Duration(seconds: widget.video.duration)),
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '📖 Sinopse',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.video.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6C63FF).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.school, color: Color(0xFF6C63FF), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Conteúdo Acadêmico',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Material educativo de alta qualidade',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
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
        ],
      ),
    );
  }
}