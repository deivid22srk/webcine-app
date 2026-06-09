import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const PlayerScreen({super.key, required this.videoUrl, required this.title});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;
  String _errorMsg = '';
  
  bool _showControls = true;
  Timer? _controlsTimer;
  double _playbackSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    
    // Força modo paisagem em tela cheia ao abrir o player
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _initializePlayer();
  }

  // Inicializa o controller de vídeo
  Future<void> _initializePlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    try {
      await _controller.initialize();
      setState(() {
        _initialized = true;
      });
      _controller.play();
      _controller.addListener(_videoListener);
      _startControlsTimer();
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMsg = e.toString();
      });
    }
  }

  void _videoListener() {
    // Escuta mudanças no vídeo (ex: buffer ou fim de reprodução) para atualizar a UI da barra de progresso
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    // Restaura orientação retrato padrão do smartphone ao sair
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    
    _controlsTimer?.cancel();
    _controller.removeListener(_videoListener);
    _controller.dispose();
    super.dispose();
  }

  // Temporizador para esconder controles
  void _startControlsTimer() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // Alterna a visibilidade dos controles
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer();
    }
  }

  // Pula 10 segundos
  Future<void> _skipForward() async {
    final currentPosition = await _controller.position;
    if (currentPosition != null) {
      final target = currentPosition + const Duration(seconds: 10);
      final duration = _controller.value.duration;
      await _controller.seekTo(target > duration ? duration : target);
    }
    _startControlsTimer();
  }

  // Retorna 10 segundos
  Future<void> _skipBackward() async {
    final currentPosition = await _controller.position;
    if (currentPosition != null) {
      final target = currentPosition - const Duration(seconds: 10);
      await _controller.seekTo(target < Duration.zero ? Duration.zero : target);
    }
    _startControlsTimer();
  }

  // Formata duração para string legível
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final hours = duration.inHours;
    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  // Mostra opções de velocidade
  void _showSpeedPicker() {
    _controlsTimer?.cancel();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151833),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final speeds = [0.5, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: speeds.map((speed) {
              return ListTile(
                title: Text(
                  '${speed}x',
                  style: TextStyle(
                    fontWeight: _playbackSpeed == speed ? FontWeight.bold : FontWeight.normal,
                    color: _playbackSpeed == speed ? const Color(0xFF6366F1) : Colors.white,
                  ),
                ),
                trailing: _playbackSpeed == speed ? const Icon(LucideIcons.check, color: Color(0xFF6366F1)) : null,
                onTap: () {
                  setState(() {
                    _playbackSpeed = speed;
                    _controller.setPlaybackSpeed(speed);
                  });
                  Navigator.pop(context);
                  _startControlsTimer();
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Video Layer
            if (_initialized && !_hasError) ...[
              Center(
                child: AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
              ),
            ],

            // Buffering Indicator
            if (_initialized && _controller.value.isBuffering && !_hasError) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],

            // Initializing Indicator
            if (!_initialized && !_hasError) ...[
              const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Inicializando vídeo...', style: TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ],

            // Error Overlay
            if (_hasError) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      const Text(
                        'Falha na reprodução do vídeo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMsg,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, color: Colors.white38),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _initialized = false;
                          });
                          _initializePlayer();
                        },
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Custom Controls Overlays
            if (_initialized && _showControls && !_hasError) ...[
              _buildControlsOverlay(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildControlsOverlay() {
    final isPlaying = _controller.value.isPlaying;
    final position = _controller.value.position;
    final duration = _controller.value.duration;

    return Container(
      color: Colors.black45, // escurece levemente a tela com os controles abertos
      child: Column(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          // Top Bar (Voltar e Título)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black85, Colors.transparent],
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Central Playback Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Retroceder 10s
              IconButton(
                icon: const Icon(LucideIcons.rotateCcw, color: Colors.white, size: 36),
                onPressed: _skipBackward,
              ),
              const SizedBox(width: 32),
              
              // Play/Pause
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                  _startControlsTimer();
                },
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.white24,
                  child: Icon(
                    isPlaying ? LucideIcons.pause : LucideIcons.play,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
              const SizedBox(width: 32),
              
              // Avançar 10s
              IconButton(
                icon: const Icon(LucideIcons.rotateCw, color: Colors.white, size: 36),
                onPressed: _skipForward,
              ),
            ],
          ),

          // Bottom Bar (Progress, Time and Speed)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black85, Colors.transparent],
              ),
            ),
            child: Column(
              children: [
                // Progress Slider
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    activeTrackColor: const Color(0xFF6366F1),
                    inactiveTrackColor: Colors.white24,
                    thumbColor: const Color(0xFF6366F1),
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    overlayColor: const Color(0xFF6366F1).withOpacity(0.2),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                  ),
                  child: Slider(
                    min: 0.0,
                    max: duration.inMilliseconds.toDouble(),
                    value: position.inMilliseconds.toDouble().clamp(0.0, duration.inMilliseconds.toDouble()),
                    onChanged: (value) {
                      _controller.seekTo(Duration(milliseconds: value.toInt()));
                      _startControlsTimer();
                    },
                  ),
                ),
                
                // Timeline row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_formatDuration(position)} / ${_formatDuration(duration)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    
                    // Speed button
                    TextButton.icon(
                      onPressed: _showSpeedPicker,
                      icon: const Icon(LucideIcons.gauge, color: Colors.white70, size: 14),
                      label: Text(
                        '${_playbackSpeed}x',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
