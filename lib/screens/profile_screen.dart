import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Abre o modal de verificação de PIN
  void _showPinDialog(Map<String, dynamic> profile) {
    final expectedPin = profile['pin']?.toString() ?? '0000';
    final List<TextEditingController> controllers = List.generate(4, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(4, (_) => FocusNode());
    String errorMessage = '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void checkPin() {
              final pinEntered = controllers.map((c) => c.text).join();
              if (pinEntered.length == 4) {
                if (pinEntered == expectedPin) {
                  // PIN correto
                  final api = Provider.of<ApiService>(context, listen: false);
                  api.selectProfile(profile);
                  Navigator.pop(context); // Fecha diálogo
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const DashboardScreen()),
                  );
                } else {
                  // PIN incorreto
                  setState(() {
                    errorMessage = 'PIN incorreto. Tente novamente.';
                    for (var controller in controllers) {
                      controller.clear();
                    }
                  });
                  focusNodes[0].requestFocus();
                }
              }
            }

            return Dialog(
              backgroundColor: const Color(0xFF151833),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withOpacity(0.08)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF6366F1).withOpacity(0.1),
                      backgroundImage: NetworkImage(
                        profile['avatar_url'] ?? 'https://via.placeholder.com/150',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      profile['name'] ?? 'Perfil',
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Insira o PIN de 4 dígitos para acessar este perfil.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.white58),
                    ),
                    const SizedBox(height: 24),
                    
                    // PIN inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(4, (index) {
                        return SizedBox(
                          width: 50,
                          child: TextField(
                            controller: controllers[index],
                            focusNode: focusNodes[index],
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            maxLength: 1,
                            obscureText: true,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.black26,
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                if (index < 3) {
                                  focusNodes[index + 1].requestFocus();
                                } else {
                                  focusNodes[index].unfocus();
                                  checkPin();
                                }
                              } else {
                                if (index > 0) {
                                  focusNodes[index - 1].requestFocus();
                                }
                              }
                            },
                          ),
                        );
                      }),
                    ),
                    
                    if (errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Helpers and Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Helper PIN shortcut
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              for (int i = 0; i < 4; i++) {
                                controllers[i].text = expectedPin[i];
                              }
                              errorMessage = '';
                            });
                            // Aguarda breve delay para submissão do PIN
                            Future.delayed(const Duration(milliseconds: 200), checkPin);
                          },
                          icon: const Icon(LucideIcons.keyRound, size: 16, color: Color(0xFF6366F1)),
                          label: Text(
                            'Usar PIN ($expectedPin)',
                            style: const TextStyle(
                              color: Color(0xFF6366F1),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        
                        TextButton(
                          onPressed: () {
                            for (var c in controllers) {
                              c.dispose();
                            }
                            for (var f in focusNodes) {
                              f.dispose();
                            }
                            Navigator.pop(context);
                          },
                          child: const Text('Cancelar', style: TextStyle(color: Colors.white38)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    final profiles = api.user?['profiles'] as List? ?? [];

    return Scaffold(
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF6366F1).withOpacity(0.08),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'Quem está assistindo?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Outfit',
                      fontSize: 28,
                      fontWeight: FontWeight.black,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Selecione um perfil para acessar o catálogo.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.white38),
                  ),
                  const SizedBox(height: 48),
                  
                  // Profiles Grid
                  Expanded(
                    child: Center(
                      child: profiles.isEmpty
                          ? const Text('Nenhum perfil disponível.')
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 24,
                                mainAxisSpacing: 24,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: profiles.length,
                              itemBuilder: (context, index) {
                                final p = profiles[index] as Map<String, dynamic>;
                                final avatar = p['avatar_url'] ?? 'https://via.placeholder.com/150';
                                
                                return InkWell(
                                  onTap: () => _showPinDialog(p),
                                  borderRadius: BorderRadius.circular(24),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.02),
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.05),
                                      ),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        // Avatar image
                                        CircleAvatar(
                                          radius: 44,
                                          backgroundColor: Colors.white10,
                                          backgroundImage: NetworkImage(avatar),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          p['name'] ?? 'Perfil',
                                          textAlign: TextAlign.center,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(LucideIcons.lock, size: 11, color: Colors.white38),
                                            const SizedBox(width: 4),
                                            Text(
                                              'PIN: ${p['pin'] ?? '0000'}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Colors.white38,
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
                  ),
                  
                  // Log out from Token button
                  ElevatedButton.icon(
                    onPressed: () async {
                      await api.logout();
                      if (mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      }
                    },
                    icon: const Icon(LucideIcons.logOut, size: 16),
                    label: const Text('Sair do Token', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.05),
                      foregroundColor: Colors.white70,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(color: Colors.white.withOpacity(0.05)),
                      ),
                      elevation: 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
