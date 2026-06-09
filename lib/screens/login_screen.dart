import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import 'profile_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _tokenController = TextEditingController(text: 'AMECL7FZ');
  final _proxyController = TextEditingController();
  bool _showProxySettings = false;

  @override
  void initState() {
    super.initState();
    // Inicializa o controller do proxy com o valor atual do service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final api = Provider.of<ApiService>(context, listen: false);
      _proxyController.text = api.proxyUrl;
    });
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _proxyController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final token = _tokenController.text.trim();
    final proxy = _proxyController.text.trim();

    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o Token de Acesso.')),
      );
      return;
    }

    try {
      // Salva URL do proxy antes de autenticar
      if (proxy.isNotEmpty) {
        await api.setProxyUrl(proxy);
      }

      final profiles = await api.loginWithToken(token);
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFF151833),
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                const SizedBox(width: 10),
                const Text('Falha de Conexão'),
              ],
            ),
            content: Text(
              'Não foi possível conectar ao Proxy em "$proxy".\n\nErro: ${api.errorMessage ?? e.toString()}',
              style: const TextStyle(color: Colors.white70),
            ),
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
    final api = Provider.of<ApiService>(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Background Glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.15),
                restoreSystemFullScreenMap: null,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFA855F7).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA855F7).withOpacity(0.15),
                    blurRadius: 100,
                    spreadRadius: 50,
                  )
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header settings button
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: Icon(
                        _showProxySettings ? LucideIcons.x : LucideIcons.settings,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() {
                          _showProxySettings = !_showProxySettings;
                        });
                      },
                    ),
                  ),
                  
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'CineVS',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 36,
                                      fontWeight: FontWeight.black,
                                      color: Colors.white,
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Proxy',
                                    style: TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 36,
                                      fontWeight: FontWeight.black,
                                      color: Color(0xFF6366F1),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Assista a filmes e séries sem anúncios.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 36),
                            
                            // Form Box (Glassmorphic look)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.08),
                                ),
                              ),
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_showProxySettings) ...[
                                    const Text(
                                      'CONFIGURAÇÃO DO PROXY',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1,
                                        color: Colors.white38,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    TextField(
                                      controller: _proxyController,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(LucideIcons.globe, size: 18),
                                        hintText: 'http://192.168.1.5:3000',
                                        labelText: 'Endereço do Servidor Proxy',
                                        filled: true,
                                        fillColor: Colors.black26,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                    const Divider(height: 32, color: Colors.white10),
                                  ],
                                  
                                  const Text(
                                    'ACESSAR CONTA',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: Colors.white38,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Token Input
                                  TextField(
                                    controller: _tokenController,
                                    textCapitalization: TextCapitalization.characters,
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(LucideIcons.key, size: 18),
                                      hintText: 'Ex: AMECL7FZ',
                                      labelText: 'Token de Acesso',
                                      filled: true,
                                      fillColor: Colors.black26,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  
                                  // Login Button
                                  ElevatedButton(
                                    onPressed: api.isLoading ? null : _handleLogin,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6366F1),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ).copyWith(
                                      overlayColor: MaterialStateProperty.all(
                                        Colors.white.withOpacity(0.1),
                                      ),
                                    ),
                                    child: api.isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'Verificar Token',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(LucideIcons.arrowRight, size: 18),
                                            ],
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
