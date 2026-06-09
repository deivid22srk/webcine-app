import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/media.dart';

class ApiService extends ChangeNotifier {
  String _proxyUrl = 'http://10.0.2.2:3000'; // Default para Emulador Android
  String? _sessionToken;
  String? _deviceId;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _activeProfile;
  
  bool _isLoading = false;
  String? _errorMessage;

  String get proxyUrl => _proxyUrl;
  String? get sessionToken => _sessionToken;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get activeProfile => _activeProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ApiService() {
    _loadSettings();
  }

  // Carrega configurações salvas no dispositivo
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _proxyUrl = prefs.getString('proxy_url') ?? 'http://10.0.2.2:3000';
    _sessionToken = prefs.getString('session_token');
    _deviceId = prefs.getString('device_id');
    
    final savedUser = prefs.getString('user_data');
    if (savedUser != null) {
      _user = jsonDecode(savedUser);
    }

    final savedProfile = prefs.getString('active_profile');
    if (savedProfile != null) {
      _activeProfile = jsonDecode(savedProfile);
    }

    if (_deviceId == null) {
      _deviceId = 'flutter-device-${DateTime.now().millisecondsSinceEpoch}-${_proxyUrl.hashCode.toRadixString(16)}';
      await prefs.setString('device_id', _deviceId!);
    }

    notifyListeners();
  }

  // Atualiza e salva a URL do Proxy
  Future<void> setProxyUrl(String url) async {
    // Normaliza URL removendo barra no final
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    _proxyUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('proxy_url', url);
    notifyListeners();
  }

  // Desconecta a sessão atual
  Future<void> logout() async {
    _sessionToken = null;
    _user = null;
    _activeProfile = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('session_token');
    await prefs.remove('user_data');
    await prefs.remove('active_profile');
    
    notifyListeners();
  }

  // Troca de perfil atual
  Future<void> selectProfile(Map<String, dynamic> profile) async {
    _activeProfile = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('active_profile', jsonEncode(profile));
    notifyListeners();
  }

  // Cabeçalhos HTTP padrão com autorização do token do proxy
  Map<String, String> get _headers {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Device-Id': _deviceId ?? 'flutter-device-1234',
    };
    if (_sessionToken != null) {
      headers['Authorization'] = 'Bearer $_sessionToken';
    }
    if (_activeProfile != null) {
      headers['X-Profile-Id'] = _activeProfile!['id'].toString();
    }
    return headers;
  }

  // Autenticar com o Token do CineVS
  Future<List<dynamic>> loginWithToken(String tokenCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.post(
        Uri.parse('$_proxyUrl/api/auth/token'),
        headers: _headers,
        body: jsonEncode({
          'access_token': tokenCode,
          'device_id': _deviceId,
          'device_name': 'Dispositivo Flutter',
          'device_type': 'browser',
          'platform': 'web'
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        _sessionToken = data['token'];
        _user = data['user'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('session_token', _sessionToken!);
        await prefs.setString('user_data', jsonEncode(_user));
        
        _isLoading = false;
        notifyListeners();
        return _user?['profiles'] ?? [];
      } else {
        throw Exception(data['message'] ?? 'Token inválido ou recusado pelo proxy.');
      }
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  // Carrega itens da página inicial (Recomendações e Destaques)
  Future<Map<String, List<MediaItem>>> fetchFeed() async {
    try {
      final feedFuture = http.get(Uri.parse('$_proxyUrl/api/feed?page=1'), headers: _headers);
      final moviesFuture = http.get(Uri.parse('$_proxyUrl/api/catalog/movies?page=1&per_page=12&sort=recent'), headers: _headers);
      final seriesFuture = http.get(Uri.parse('$_proxyUrl/api/catalog/series?page=1&per_page=12&sort=recent'), headers: _headers);

      final results = await Future.wait([feedFuture, moviesFuture, seriesFuture]);

      List<MediaItem> movies = [];
      List<MediaItem> series = [];

      if (results[1].statusCode == 200) {
        final body = jsonDecode(results[1].body);
        movies = (body['data'] as List).map((i) => MediaItem.fromJson(i)).toList();
      }
      
      if (results[2].statusCode == 200) {
        final body = jsonDecode(results[2].body);
        series = (body['data'] as List).map((i) => MediaItem.fromJson(i)).toList();
      }

      return {
        'recent_movies': movies,
        'recent_series': series,
      };
    } catch (e) {
      print('Erro ao buscar feed do proxy: $e');
      rethrow;
    }
  }

  // Buscar itens no catálogo
  Future<Map<String, dynamic>> fetchCatalog(String type, {int page = 1, String genreId = '', String year = '', String sort = 'recent'}) async {
    final queryParams = {
      'page': page.toString(),
      'per_page': '18',
      'sort': sort,
    };
    if (genreId.isNotEmpty) queryParams['genre_id'] = genreId;
    if (year.isNotEmpty) queryParams['year'] = year;

    final uri = Uri.parse('$_proxyUrl/api/catalog/$type').replace(queryParameters: queryParams);
    
    try {
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List itemsJson = body['data'] ?? [];
        final List<MediaItem> items = itemsJson.map((i) => MediaItem.fromJson(i)).toList();
        return {
          'items': items,
          'last_page': body['last_page'] ?? 1,
        };
      }
      throw Exception('Falha ao buscar catálogo');
    } catch (e) {
      print('Erro ao carregar catálogo: $e');
      rethrow;
    }
  }

  // Buscar filtros disponíveis (Gêneros e Anos)
  Future<Map<String, dynamic>> fetchFilters() async {
    try {
      final response = await http.get(Uri.parse('$_proxyUrl/api/catalog/filters'), headers: _headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {'genres': [], 'years': []};
    } catch (e) {
      print('Erro ao carregar filtros: $e');
      return {'genres': [], 'years': []};
    }
  }

  // Pesquisar
  Future<List<MediaItem>> search(String query) async {
    try {
      final response = await http.get(Uri.parse('$_proxyUrl/api/search?q=${Uri.encodeComponent(query)}'), headers: _headers);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['data'] ?? body ?? [];
        return list.map((i) => MediaItem.fromJson(i)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao buscar conteúdos: $e');
      return [];
    }
  }

  // Detalhes de um filme ou série específico
  Future<Map<String, dynamic>> fetchMediaDetails(int id, String type) async {
    final route = type == 'movie' ? 'movies' : 'series';
    try {
      final response = await http.get(Uri.parse('$_proxyUrl/api/$route/$id'), headers: _headers);
      if (response.statusCode == 200) {
        final details = jsonDecode(response.body);
        
        List<Season> seasons = [];
        if (details['seasons'] != null) {
          seasons = (details['seasons'] as List).map((s) => Season.fromJson(s)).toList();
        }

        return {
          'media': MediaItem.fromJson(details),
          'seasons': seasons,
        };
      }
      throw Exception('Erro ao carregar detalhes');
    } catch (e) {
      print('Erro ao obter detalhes da mídia: $e');
      rethrow;
    }
  }

  // Obter opções de reprodução (players) do episódio
  Future<List<VideoChannel>> fetchEpisodeChannels(int episodeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_proxyUrl/api/streaming/episodes/$episodeId/videos?platform=web&device_type=web'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['videos'] ?? [];
        return list.map((v) => VideoChannel.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao obter canais do episódio: $e');
      return [];
    }
  }

  // Obter opções de reprodução (players) do filme
  Future<List<VideoChannel>> fetchMovieChannels(int movieId) async {
    try {
      final response = await http.get(
        Uri.parse('$_proxyUrl/api/streaming/movies/$movieId/videos?platform=web&device_type=web'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List list = body['videos'] ?? [];
        return list.map((v) => VideoChannel.fromJson(v)).toList();
      }
      return [];
    } catch (e) {
      print('Erro ao obter canais do filme: $e');
      return [];
    }
  }

  // Resolve a URL final descriptografada pelo proxy para jogar no player nativo
  Future<String> resolveStreamUrl(String type, int mediaId, int videoId) async {
    try {
      final profileId = _activeProfile?['id']?.toString() ?? '';
      final response = await http.get(
        Uri.parse('$_proxyUrl/api/stream/$type/$mediaId/$videoId?profile_id=$profileId'),
        headers: _headers,
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['url'] != null) {
          return body['url'];
        }
      }
      throw Exception('Link de streaming inválido ou bloqueado.');
    } catch (e) {
      print('Erro ao resolver streaming: $e');
      rethrow;
    }
  }
}
