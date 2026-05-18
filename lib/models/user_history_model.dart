class UserHistoryModel {
  final int id;
  final String userId;
  final int videoId;
  final DateTime watchedAt;
  final String? title;
  final String? coverUrl;

  UserHistoryModel({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.watchedAt,
    this.title,
    this.coverUrl,
  });

  factory UserHistoryModel.fromJson(Map<String, dynamic> json) {
    return UserHistoryModel(
      id: json['id'],
      userId: json['user_id'],
      videoId: json['video_id'],
      watchedAt: DateTime.parse(json['watched_at']),
      title: json['videos'] != null ? json['videos']['title'] : null,
      coverUrl: json['videos'] != null ? json['videos']['cover_url'] : null,
    );
  }
}

class UserFavoriteModel {
  final int id;
  final String userId;
  final int videoId;
  final DateTime favoritedAt;
  final String? title;
  final String? coverUrl;

  UserFavoriteModel({
    required this.id,
    required this.userId,
    required this.videoId,
    required this.favoritedAt,
    this.title,
    this.coverUrl,
  });

  factory UserFavoriteModel.fromJson(Map<String, dynamic> json) {
    return UserFavoriteModel(
      id: json['id'],
      userId: json['user_id'],
      videoId: json['video_id'],
      favoritedAt: DateTime.parse(json['favorited_at']),
      title: json['videos'] != null ? json['videos']['title'] : null,
      coverUrl: json['videos'] != null ? json['videos']['cover_url'] : null,
    );
  }
}