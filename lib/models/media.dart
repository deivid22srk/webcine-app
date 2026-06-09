class MediaItem {
  final int id;
  final String title;
  final String? originalTitle;
  final String? description;
  final String? poster;
  final String? backdrop;
  final int? year;
  final double? ratingAvg;
  final String type; // 'movie', 'series', 'anime'
  final List<String> genres;
  final String? ageRating;

  MediaItem({
    required this.id,
    required this.title,
    this.originalTitle,
    this.description,
    this.poster,
    this.backdrop,
    this.year,
    this.ratingAvg,
    required this.type,
    this.genres = const [],
    this.ageRating,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    var genreList = json['genres'] as List?;
    List<String> parsedGenres = [];
    if (genreList != null) {
      parsedGenres = genreList.map((g) => g['name']?.toString() ?? '').where((n) => n.isNotEmpty).toList();
    }

    String? age;
    if (json['age_rating'] != null) {
      age = json['age_rating']['name']?.toString();
    }

    return MediaItem(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Sem título',
      originalTitle: json['original_title'],
      description: json['description'],
      poster: json['poster'],
      backdrop: json['backdrop'] ?? json['backdrop_titled'],
      year: json['year'] is int ? json['year'] : (json['year'] != null ? int.tryParse(json['year'].toString()) : null),
      ratingAvg: json['rating_avg'] != null ? double.tryParse(json['rating_avg'].toString()) : null,
      type: json['type'] ?? 'movie',
      genres: parsedGenres,
      ageRating: age,
    );
  }
}

class Season {
  final int id;
  final String title;
  final int number;
  final List<Episode> episodes;

  Season({
    required this.id,
    required this.title,
    required this.number,
    required this.episodes,
  });

  factory Season.fromJson(Map<String, dynamic> json) {
    var epList = json['episodes'] as List?;
    List<Episode> parsedEpisodes = [];
    if (epList != null) {
      parsedEpisodes = epList.map((e) => Episode.fromJson(e)).toList();
    }

    return Season(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Temporada ${json['number']}',
      number: json['number'] is int ? json['number'] : int.parse(json['number'].toString()),
      episodes: parsedEpisodes,
    );
  }
}

class Episode {
  final int id;
  final String title;
  final int number;
  final String? thumbnail;
  final int? duration;

  Episode({
    required this.id,
    required this.title,
    required this.number,
    this.thumbnail,
    this.duration,
  });

  factory Episode.fromJson(Map<String, dynamic> json) {
    return Episode(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'Episódio ${json['number']}',
      number: json['number'] is int ? json['number'] : int.parse(json['number'].toString()),
      thumbnail: json['thumbnail'],
      duration: json['duration'] is int ? json['duration'] : (json['duration'] != null ? int.tryParse(json['duration'].toString()) : null),
    );
  }
}

class VideoChannel {
  final int id;
  final String title;
  final String audioType; // 'dubbed', 'subtitled', etc
  final int sortOrder;
  final bool locked;

  VideoChannel({
    required this.id,
    required this.title,
    required this.audioType,
    required this.sortOrder,
    required this.locked,
  });

  factory VideoChannel.fromJson(Map<String, dynamic> json) {
    return VideoChannel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? 'HD',
      audioType: json['audio_type'] ?? 'dubbed',
      sortOrder: json['sort_order'] is int ? json['sort_order'] : (json['sort_order'] != null ? int.parse(json['sort_order'].toString()) : 0),
      locked: json['locked'] == true,
    );
  }

  String get audioLabel => audioType == 'dubbed' ? 'Dublado' : (audioType == 'subtitled' ? 'Legendado' : audioType);
}
