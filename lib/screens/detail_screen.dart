import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../models/video_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class DetailScreen extends StatefulWidget {
  final int videoId;
  
  const DetailScreen({super.key, required this.videoId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  VideoModel? _video;
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideoDetails();
    _checkFavorite();
  }

  Future<void> _loadVideoDetails() async {
    try {
      final video = await _supabaseService.getVideoById(widget.videoId);
      setState(() {
        _video = video;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao carregar detalhes do vídeo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _checkFavorite() async {
    try {
      final isFav = await _supabaseService.isFavorite(widget.videoId);
      setState(() => _isFavorite = isFav);
    } catch (e) {}
  }

  Future<void> _toggleFavorite() async {
    try {
      if (_isFavorite) {
        await _supabaseService.removeFavorite(widget.videoId);
        setState(() => _isFavorite = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Removido dos favoritos'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        await _supabaseService.addFavorite(widget.videoId);
        setState(() => _isFavorite = true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Adicionado aos favoritos! ⭐'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _watchNow() {
    if (_video != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(video: _video!),
        ),
      );
    }
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF6C63FF)),
              SizedBox(height: 20),
              Text('Carregando...', style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      );
    }

    if (_video == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Erro')),
        body: const Center(child: Text('Vídeo não encontrado')),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Icon(
                _isFavorite ? Icons.favorite : Icons.favorite_border,
                color: _isFavorite ? Colors.red : Colors.white,
              ),
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Image
            Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: _video!.coverUrl,
                  height: 450,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 450,
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 450,
                    color: Colors.grey[900],
                    child: const Icon(Icons.image_not_supported, size: 50, color: Colors.white54),
                  ),
                ),
                Container(
                  height: 450,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                        Colors.black.withOpacity(0.8),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.5, 0.8, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6C63FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _video!.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _video!.title,
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            '${_video!.views} visualizações',
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const SizedBox(width: 12),
                          const Icon(Icons.schedule, size: 16, color: Colors.white70),
                          const SizedBox(width: 4),
                          Text(
                            _formatDuration(_video!.duration),
                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // Conteúdo
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botão Assistir
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C63FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _watchNow,
                      icon: const Icon(Icons.play_arrow, size: 28),
                      label: const Text(
                        'ASSISTIR AGORA',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Sinopse
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.description, color: Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            Text(
                              'Sinopse',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _video!.description,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.white70,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Informações adicionais
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.school, color: Color(0xFF6C63FF), size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'Acadêmico',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Certificado',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.hd, color: Color(0xFF6C63FF), size: 28),
                              const SizedBox(height: 8),
                              Text(
                                'HD 1080p',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Alta qualidade',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: Colors.white24,
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              const Icon(Icons.access_time, color: Color(0xFF6C63FF), size: 28),
                              const SizedBox(height: 8),
                              Text(
                                _formatDuration(_video!.duration),
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Duração',
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
          ],
        ),
      ),
    );
  }
}