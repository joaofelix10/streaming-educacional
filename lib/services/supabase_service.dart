import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/video_model.dart';
import '../models/user_history_model.dart';

class SupabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Auth Methods - CORRIGIDO
  Future<AuthResponse> signUp(String email, String password) async {
    return await _supabase.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<Session> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session!;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  User? get currentUser => _supabase.auth.currentUser;

  // Video Methods
  Future<List<VideoModel>> getVideos() async {
    try {
      final response = await _supabase
          .from('videos')
          .select('*')
          .order('views', ascending: false);
      
      return response.map((json) => VideoModel.fromJson(json)).toList();
    } catch (e) {
      print('Erro ao buscar vídeos: $e');
      return [];
    }
  }

  Future<List<VideoModel>> getVideosByCategory(String category) async {
    try {
      final response = await _supabase
          .from('videos')
          .select('*')
          .eq('category', category)
          .limit(10);
      
      return response.map((json) => VideoModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<VideoModel?> getVideoById(int id) async {
    try {
      final response = await _supabase
          .from('videos')
          .select('*')
          .eq('id', id)
          .single();
      
      return VideoModel.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Favorites Methods
  Future<void> addFavorite(int videoId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase.from('favorites').insert({
      'user_id': userId,
      'video_id': videoId,
      'favorited_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> removeFavorite(int videoId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase
        .from('favorites')
        .delete()
        .match({'user_id': userId, 'video_id': videoId});
  }

  Future<bool> isFavorite(int videoId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    final response = await _supabase
        .from('favorites')
        .select('id')
        .match({'user_id': userId, 'video_id': videoId});
    
    return response.isNotEmpty;
  }

  Stream<List<UserFavoriteModel>> getFavoritesStream() {
    final userId = _supabase.auth.currentUser!.id;
    
    return _supabase
        .from('favorites')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('favorited_at', ascending: false)
        .execute()
        .map((data) {
          return data.map((json) => UserFavoriteModel.fromJson(json)).toList();
        });
  }

  // History Methods
  Future<void> addToHistory(int videoId) async {
    final userId = _supabase.auth.currentUser!.id;
    
    try {
      await _supabase.from('history').insert({
        'user_id': userId,
        'video_id': videoId,
        'watched_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Se já existe, apenas atualiza
      await _supabase
          .from('history')
          .update({'watched_at': DateTime.now().toIso8601String()})
          .match({'user_id': userId, 'video_id': videoId});
    }
  }

  Future<void> clearHistory() async {
    final userId = _supabase.auth.currentUser!.id;
    
    await _supabase
        .from('history')
        .delete()
        .eq('user_id', userId);
  }

  Future<void> removeFromHistory(int historyId) async {
    await _supabase
        .from('history')
        .delete()
        .eq('id', historyId);
  }

  Stream<List<UserHistoryModel>> getHistoryStream() {
    final userId = _supabase.auth.currentUser!.id;
    
    return _supabase
        .from('history')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('watched_at', ascending: false)
        .execute()
        .map((data) {
          return data.map((json) => UserHistoryModel.fromJson(json)).toList();
        });
  }
}