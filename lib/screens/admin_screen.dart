import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _videos = [];
  bool _isLoading = true;

  // Controllers para o formulário
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _coverUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _durationController = TextEditingController();

  // Variável para edição
  int? _editandoId;

  @override
  void initState() {
    super.initState();
    _carregarVideos();
  }

  Future<void> _carregarVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select('*')
          .order('created_at', ascending: false);
      
      setState(() {
        _videos = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _mostrarMensagem('Erro ao carregar vídeos: $e', isError: true);
    }
  }

  Future<void> _salvarVideo() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final dados = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'cover_url': _coverUrlController.text.isEmpty 
            ? 'https://picsum.photos/id/${DateTime.now().millisecondsSinceEpoch % 200}/300/200'
            : _coverUrlController.text,
        'video_url': _videoUrlController.text.isEmpty
            ? 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
            : _videoUrlController.text,
        'category': _categoryController.text,
        'duration': int.parse(_durationController.text),
        'views': 0,
      };
      
      if (_editandoId != null) {
        // Update
        await _supabase
            .from('videos')
            .update(dados)
            .eq('id', _editandoId);
        _mostrarMensagem('Vídeo atualizado com sucesso!');
      } else {
        // Create
        await _supabase.from('videos').insert(dados);
        _mostrarMensagem('Vídeo adicionado com sucesso!');
      }
      
      _limparFormulario();
      await _carregarVideos();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _mostrarMensagem('Erro: ${e.toString()}', isError: true);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _excluirVideo(int id, String titulo) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Vídeo'),
        content: Text('Tem certeza que deseja excluir "$titulo"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmar == true) {
      setState(() => _isLoading = true);
      try {
        await _supabase.from('favorites').delete().eq('video_id', id);
        await _supabase.from('history').delete().eq('video_id', id);
        await _supabase.from('videos').delete().eq('id', id);
        
        await _carregarVideos();
        _mostrarMensagem('Vídeo excluído com sucesso!');
      } catch (e) {
        _mostrarMensagem('Erro ao excluir: ${e.toString()}', isError: true);
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _editarVideo(Map<String, dynamic> video) {
    _editandoId = video['id'];
    _titleController.text = video['title'];
    _descriptionController.text = video['description'] ?? '';
    _coverUrlController.text = video['cover_url'];
    _videoUrlController.text = video['video_url'];
    _categoryController.text = video['category'];
    _durationController.text = video['duration'].toString();
    
    _mostrarModal(titulo: 'Editar Vídeo');
  }

  void _limparFormulario() {
    _editandoId = null;
    _titleController.clear();
    _descriptionController.clear();
    _coverUrlController.clear();
    _videoUrlController.clear();
    _categoryController.clear();
    _durationController.clear();
  }

  void _mostrarModal({String titulo = 'Adicionar Vídeo'}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Color(0xFF1E1E1E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF2D2D2D),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_library, color: Color(0xFF6C63FF)),
                    const SizedBox(width: 12),
                    Text(
                      titulo,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _campoTexto(
                          controller: _titleController,
                          label: 'Título do Vídeo *',
                          icone: Icons.title,
                        ),
                        const SizedBox(height: 16),
                        _campoTexto(
                          controller: _descriptionController,
                          label: 'Descrição *',
                          icone: Icons.description,
                          linhas: 3,
                        ),
                        const SizedBox(height: 16),
                        _campoTexto(
                          controller: _categoryController,
                          label: 'Categoria *',
                          icone: Icons.category,
                          dica: 'Ex: Matemática, Física, Programação',
                        ),
                        const SizedBox(height: 16),
                        _campoTexto(
                          controller: _durationController,
                          label: 'Duração (segundos) *',
                          icone: Icons.timer,
                          dica: '3600 = 1 hora',
                          teclado: TextInputType.number,
                        ),
                        const SizedBox(height: 16),
                        _campoTexto(
                          controller: _coverUrlController,
                          label: 'URL da Capa',
                          icone: Icons.image,
                          dica: 'Deixe em branco para imagem aleatória',
                        ),
                        const SizedBox(height: 16),
                        _campoTexto(
                          controller: _videoUrlController,
                          label: 'URL do Vídeo',
                          icone: Icons.video_library,
                          dica: 'Deixe em branco para vídeo padrão',
                        ),
                        const SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _salvarVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF6C63FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _editandoId != null ? 'ATUALIZAR VÍDEO' : 'ADICIONAR VÍDEO',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ).then((_) => _limparFormulario());
  }

  Widget _campoTexto({
    required TextEditingController controller,
    required String label,
    required IconData icone,
    String? dica,
    int linhas = 1,
    TextInputType? teclado,
  }) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      maxLines: linhas,
      keyboardType: teclado,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        hintText: dica,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icone, color: Colors.white70),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF6C63FF)),
        ),
      ),
      validator: (valor) {
        if (controller == _titleController || 
            controller == _descriptionController || 
            controller == _categoryController || 
            controller == _durationController) {
          if (valor == null || valor.isEmpty) {
            return 'Campo obrigatório';
          }
        }
        return null;
      },
    );
  }

  void _mostrarMensagem(String mensagem, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensagem),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatarDuracao(int segundos) {
    int horas = segundos ~/ 3600;
    int minutos = (segundos % 3600) ~/ 60;
    if (horas > 0) {
      return '$horas h $minutos min';
    }
    return '$minutos min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Gerenciar Vídeos Acadêmicos',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF6C63FF)),
            onPressed: () => _mostrarModal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            )
          : _videos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.video_library, size: 80, color: Colors.white54),
                      const SizedBox(height: 16),
                      Text(
                        'Nenhum vídeo adicionado ainda',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.white54,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Clique no + para adicionar seu primeiro vídeo',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white38,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _videos.length,
                  itemBuilder: (context, index) {
                    final video = _videos[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                video['cover_url'],
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(Icons.video_library, size: 30),
                                ),
                              ),
                            ),
                            title: Text(
                              video['title'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              '${video['category']} • ${_formatarDuracao(video['duration'])} • ${video['views']} views',
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            trailing: PopupMenuButton(
                              icon: const Icon(Icons.more_vert, color: Colors.white70),
                              onSelected: (value) {
                                if (value == 'edit') {
                                  _editarVideo(video);
                                } else if (value == 'delete') {
                                  _excluirVideo(video['id'], video['title']);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Excluir'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _editarVideo(video),
                                    icon: const Icon(Icons.edit, size: 18),
                                    label: const Text('Editar'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue,
                                      side: const BorderSide(color: Colors.blue),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _excluirVideo(video['id'], video['title']),
                                    icon: const Icon(Icons.delete, size: 18),
                                    label: const Text('Excluir'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}