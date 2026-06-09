import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/media.dart';
import 'player_screen.dart';

class DetailsScreen extends StatefulWidget {
  final MediaItem item;

  const DetailsScreen({super.key, required this.item});

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  bool _isLoadingDetails = true;
  MediaItem? _details;
  List<Season> _seasons = [];
  Season? _selectedSeason;
  
  bool _isLoadingChannels = false;
  List<VideoChannel> _channels = [];
  Episode? _selectedEpisode;

  @override
  void initState() {
    super.initState();
    _loadMediaDetails();
  }

  // Carrega os detalhes completos do filme ou série
  Future<void> _loadMediaDetails() async {
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final detailsRes = await api.fetchMediaDetails(widget.item.id, widget.item.type);
      
      setState(() {
        _details = detailsRes['media'];
        _seasons = detailsRes['seasons'] ?? [];
        _isLoadingDetails = false;
        
        // Se for série e tiver temporadas, seleciona a primeira
        if (_seasons.isNotEmpty) {
          _selectedSeason = _seasons.first;
          if (_selectedSeason!.episodes.isNotEmpty) {
            _selectedEpisode = _selectedSeason!.episodes.first;
            _loadEpisodeChannels(_selectedEpisode!.id);
          }
        } else if (widget.item.type == 'movie') {
          _loadMovieChannels(widget.item.id);
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDetails = false;
      });
    }
  }

  // Carrega canais/players do episódio da série
  Future<void> _loadEpisodeChannels(int episodeId) async {
    setState(() {
      _isLoadingChannels = true;
      _channels = [];
    });
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final channels = await api.fetchEpisodeChannels(episodeId);
      setState(() {
        _channels = channels;
        _isLoadingChannels = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChannels = false;
      });
    }
  }

  // Carrega canais/players do filme
  Future<void> _loadMovieChannels(int movieId) async {
    setState(() {
      _isLoadingChannels = true;
      _channels = [];
    });
    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final channels = await api.fetchMovieChannels(movieId);
      setState(() {
        _channels = channels;
        _isLoadingChannels = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingChannels = false;
      });
    }
  }

  // Abre a tela de Player para reproduzir o vídeo selecionado
  Future<void> _playVideoChannel(VideoChannel channel) async {
    final api = Provider.of<ApiService>(context, listen: false);
    final mediaId = widget.item.type == 'movie' ? widget.item.id : _selectedEpisode!.id;
    final streamType = widget.item.type == 'movie' ? 'movie' : 'episode';

    // Mostra indicador de loading no diálogo
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          color: Color(0xFF151833),
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Resolvendo fluxo via proxy...', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final finalUrl = await api.resolveStreamUrl(streamType, mediaId, channel.id);
      
      if (mounted) {
        Navigator.pop(context); // Fecha diálogo loading
        
        final title = widget.item.type == 'movie'
            ? '${widget.item.title} (${channel.audioLabel})'
            : '${widget.item.title} - S${_selectedSeason?.number}E${_selectedEpisode?.number} - ${_selectedEpisode?.title} (${channel.audioLabel})';

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PlayerScreen(
              videoUrl: finalUrl,
              title: title,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Fecha diálogo loading
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF151833),
            title: const Text('Erro de Streaming'),
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Color(0xFF6366F1))),
              )
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final backdropUrl = widget.item.backdrop ?? widget.item.poster ?? '';
    
    return Scaffold(
      body: _isLoadingDetails
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Scrollable details list
                ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    // Backdrop banner top
                    Stack(
                      children: [
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage(backdropUrl),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Container(
                          height: 320,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                const Color(0xFF070913),
                                const Color(0xFF070913).withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 24,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Type badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white12),
                                ),
                                child: Text(
                                  widget.item.type == 'movie'
                                      ? 'Filme'
                                      : (widget.item.type == 'anime' ? 'Anime' : 'Série'),
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.item.title,
                                style: const TextStyle(
                                  fontFamily: 'Outfit',
                                  fontSize: 28,
                                  fontWeight: FontWeight.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  if (widget.item.ratingAvg != null) ...[
                                    const Icon(LucideIcons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      widget.item.ratingAvg!.toStringAsFixed(1),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.amber,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                  ],
                                  Text(
                                    widget.item.year?.toString() ?? '',
                                    style: const TextStyle(fontSize: 13, color: Colors.white60),
                                  ),
                                  if (_details?.ageRating != null) ...[
                                    const SizedBox(width: 16),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF6366F1).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        _details!.ageRating!,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF6366F1),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    // Main info body
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Synopsis
                          Text(
                            _details?.description ?? widget.item.description ?? 'Nenhuma sinopse disponível.',
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Genres list
                          if (widget.item.genres.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: widget.item.genres.map((g) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withOpacity(0.06)),
                                ),
                                child: Text(g, style: const TextStyle(fontSize: 11, color: Colors.white58)),
                              )).toList(),
                            ),
                            const SizedBox(height: 24),
                          ],
                          
                          // SEASONS AND EPISODES (if series/anime)
                          if (widget.item.type == 'series' || widget.item.type == 'anime') ...[
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 12),
                            _buildSeasonsSection(),
                          ],
                          
                          // VIDEO PLAYERS SECTION
                          const Divider(color: Colors.white10),
                          const SizedBox(height: 12),
                          const Text(
                            'OPÇÕES DE PLAYERS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: Colors.white38,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildChannelsList(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Floating back button top-left
                Positioned(
                  top: 40,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    child: IconButton(
                      icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // 1. Renderizador de Temporadas e Episódios
  Widget _buildSeasonsSection() {
    if (_seasons.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Dropdown temporada
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TEMPORADA',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Colors.white38,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF151833).withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Season>(
                  value: _selectedSeason,
                  onChanged: (Season? s) {
                    if (s != null) {
                      setState(() {
                        _selectedSeason = s;
                        if (s.episodes.isNotEmpty) {
                          _selectedEpisode = s.episodes.first;
                          _loadEpisodeChannels(_selectedEpisode!.id);
                        }
                      });
                    }
                  },
                  items: _seasons.map((Season s) {
                    return DropdownMenuItem<Season>(
                      value: s,
                      child: Text(s.title, style: const TextStyle(fontSize: 13, color: Colors.white)),
                    );
                  }).toList(),
                  dropdownColor: const Color(0xFF151833),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Horizontal list of episodes
        if (_selectedSeason != null) ...[
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedSeason!.episodes.length,
              itemBuilder: (context, index) {
                final ep = _selectedSeason!.episodes[index];
                final isSelected = _selectedEpisode?.id == ep.id;
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedEpisode = ep;
                    });
                    _loadEpisodeChannels(ep.id);
                  },
                  child: Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF6366F1).withOpacity(0.15) : Colors.white.withOpacity(0.02),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Episode thumb
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: ep.thumbnail != null
                              ? Image.network(ep.thumbnail!, height: 60, width: 144, fit: BoxFit.cover)
                              : Container(
                                  height: 60,
                                  color: Colors.white10,
                                  child: const Center(
                                    child: Icon(LucideIcons.tv, size: 16, color: Colors.white24),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ep ${ep.number} - ${ep.title}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        if (ep.duration != null) ...[
                          Text(
                            '${ep.duration} min',
                            style: const TextStyle(fontSize: 9, color: Colors.white38),
                          ),
                        ]
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // 2. Renderizador de players
  Widget _buildChannelsList() {
    if (_isLoadingChannels) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_channels.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'Nenhum player disponível.',
            style: TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ),
      );
    }

    return Column(
      children: _channels.map((c) {
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          color: Colors.white.withOpacity(0.03),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.white.withOpacity(0.04)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              c.locked ? LucideIcons.lock : LucideIcons.playCircle,
              color: c.locked ? Colors.white38 : const Color(0xFF6366F1),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: c.audioType == 'dubbed' ? Colors.blue.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    c.audioLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: c.audioType == 'dubbed' ? Colors.blue : Colors.green,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Opção ${c.sortOrder + 1} (${c.title})',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            trailing: c.locked
                ? const Text('Bloqueado', style: TextStyle(fontSize: 11, color: Colors.white38))
                : const Text('Disponível', style: TextStyle(fontSize: 11, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
            onTap: c.locked ? null : () => _playVideoChannel(c),
          ),
        );
      }).toList(),
    );
  }
}
