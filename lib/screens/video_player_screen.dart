import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../models/video_model.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeVideo();
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
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });
      
      setState(() {
        _isInitialized = true;
      });
      
      _controller.play();
    } catch (e) {
      print('Erro ao carregar vídeo: $e');
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          widget.video.title,
          style: GoogleFonts.poppins(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: _isInitialized
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                    label: Text(_isPlaying ? 'Pausar' : 'Reproduzir'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6C63FF),
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 20),
                  Text('Carregando vídeo...', style: TextStyle(color: Colors.white70)),
                ],
              ),
      ),
    );
  }
}