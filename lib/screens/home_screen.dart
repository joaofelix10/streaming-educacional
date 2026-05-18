import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../models/video_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  List<VideoModel> _allVideos = [];
  List<VideoModel> _mostViewed = [];
  List<VideoModel> _recentlyAdded = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    try {
      final videos = await _supabaseService.getVideos();
      setState(() {
        _allVideos = videos;
        _mostViewed = videos.take(10).toList();
        _recentlyAdded = videos.reversed.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao carregar vídeos: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCategorySection(String title, List<VideoModel> videos, {String icon = '🎬'}) {
    if (videos.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Text(
                '$icon ',
                style: const TextStyle(fontSize: 24),
              ),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'Ver todos',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 260,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: videos.length,
            itemBuilder: (context, index) {
              final video = videos[index];
              return GestureDetector(
                onTap: () {
                  context.push('/detail/${video.id}');
                },
                child: Container(
                  width: 160,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: CachedNetworkImage(
                              imageUrl: video.coverUrl,
                              height: 200,
                              width: 160,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                height: 200,
                                color: Colors.grey[800],
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: Color(0xFF6C63FF),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                height: 200,
                                color: Colors.grey[800],
                                child: const Icon(Icons.error, color: Colors.white54),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.play_arrow, size: 14, color: Colors.white),
                                  const SizedBox(width: 2),
                                  Text(
                                    _formatDuration(video.duration),
                                    style: const TextStyle(color: Colors.white, fontSize: 10),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.visibility, size: 12, color: Colors.white54),
                          const SizedBox(width: 4),
                          Text(
                            '${video.views}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6C63FF).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              video.category,
                              style: const TextStyle(
                                color: Color(0xFF6C63FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds % 3600) ~/ 60;
    return '${minutes.toString().padLeft(2, '0')}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'EduStream',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.favorite_border, size: 22),
            ),
            onPressed: () => context.push('/favorites'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.history, size: 22),
            ),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.person, size: 22),
            ),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 16),
                  Text('Carregando catálogo...', style: TextStyle(color: Colors.white70)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Banner destaque
                  Container(
                    height: 200,
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C63FF), Color(0xFF3F3D9E)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0.1,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                image: const DecorationImage(
                                  image: NetworkImage('https://picsum.photos/id/20/800/400'),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '📚 Bem-vindo ao\nEduStream!',
                                style: GoogleFonts.poppins(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Educação e Entretenimento\nao seu alcance',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildCategorySection('🔥 Mais Assistidos', _mostViewed, icon: '🔥'),
                  const SizedBox(height: 16),
                  _buildCategorySection('🆕 Adicionados Recentemente', _recentlyAdded, icon: '🆕'),
                  const SizedBox(height: 16),
                  _buildCategorySection('📚 Para Você', _allVideos.take(10).toList(), icon: '📚'),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }
}