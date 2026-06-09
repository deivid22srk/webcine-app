import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../models/media.dart';
import 'details_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentTabIndex = 0; // 0 = Home, 1 = Movies, 2 = Series, 3 = Animes, 4 = Search
  final _searchController = TextEditingController();
  
  // Filtros do catálogo
  String _selectedGenre = '';
  String _selectedYear = '';
  String _selectedSort = 'recent';
  int _catalogPage = 1;
  int _catalogLastPage = 1;
  
  // Listas de filtros carregadas da API
  List<dynamic> _genres = [];
  List<dynamic> _years = [];
  
  bool _isCatalogLoading = false;
  List<MediaItem> _catalogItems = [];
  List<MediaItem> _searchResults = [];
  bool _isSearchLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFilters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Carrega opções de gêneros e anos
  Future<void> _loadFilters() async {
    final api = Provider.of<ApiService>(context, listen: false);
    final filters = await api.fetchFilters();
    setState(() {
      _genres = filters['genres'] ?? [];
      _years = filters['years'] ?? [];
    });
  }

  // Carrega catálogo filtrado
  Future<void> _loadCatalogItems() async {
    setState(() {
      _isCatalogLoading = true;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    String type = 'movies';
    if (_currentTabIndex == 2) type = 'series';
    if (_currentTabIndex == 3) type = 'animes';

    try {
      final res = await api.fetchCatalog(
        type,
        page: _catalogPage,
        genreId: _selectedGenre,
        year: _selectedYear,
        sort: _selectedSort,
      );
      
      setState(() {
        _catalogItems = res['items'] ?? [];
        _catalogLastPage = res['last_page'] ?? 1;
        _isCatalogLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCatalogLoading = false;
      });
    }
  }

  // Executa pesquisa
  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _currentTabIndex = 4; // Abre aba de busca
      _isSearchLoading = true;
    });

    final api = Provider.of<ApiService>(context, listen: false);
    try {
      final results = await api.search(query);
      setState(() {
        _searchResults = results;
        _isSearchLoading = false;
      });
    } catch (e) {
      setState(() {
        _isSearchLoading = false;
      });
    }
  }

  // Alterna abas
  void _onTabChanged(int index) {
    setState(() {
      _currentTabIndex = index;
      _catalogPage = 1;
      _selectedGenre = '';
      _selectedYear = '';
      _selectedSort = 'recent';
      _searchController.clear();
    });

    if (index >= 1 && index <= 3) {
      _loadCatalogItems();
    }
  }

  // Menu do Perfil no topo
  void _showProfileMenu(BuildContext context) {
    final api = Provider.of<ApiService>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF151833),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(api.activeProfile?['avatar_url'] ?? ''),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          api.activeProfile?['name'] ?? 'Perfil',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const Text('Perfil ativo', style: TextStyle(fontSize: 12, color: Colors.white58)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 32, color: Colors.white10),
                ListTile(
                  leading: const Icon(LucideIcons.users, color: Colors.white70),
                  title: const Text('Trocar de Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    // Reseta seleção de perfil localmente no state
                    api.selectProfile(api.activeProfile!); // re-triggers routing
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.logOut, color: Colors.redAccent),
                  title: const Text('Sair do Token', style: TextStyle(color: Colors.redAccent)),
                  onTap: () async {
                    Navigator.pop(context);
                    await api.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final api = Provider.of<ApiService>(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF070913),
        elevation: 0,
        title: Row(
          children: [
            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: const Row(
                children: [
                  CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Proxy OK',
                    style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Profile Widget
          GestureDetector(
            onTap: () => _showProfileMenu(context),
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                  Text(
                    api.activeProfile?['name'] ?? '',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: NetworkImage(api.activeProfile?['avatar_url'] ?? ''),
                  ),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.white38),
                hintText: 'Pesquisar filmes, séries, animes...',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF151833).withOpacity(0.5),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: const BorderSide(color: Color(0xFF6366F1), width: 1.5),
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
        ),
      ),
      body: _buildCurrentView(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex == 4 ? 0 : _currentTabIndex,
          onTap: _onTabChanged,
          backgroundColor: const Color(0xFF070913),
          selectedItemColor: const Color(0xFF6366F1),
          unselectedItemColor: Colors.white38,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(LucideIcons.home, size: 20), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.film, size: 20), label: 'Filmes'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.tv, size: 20), label: 'Séries'),
            BottomNavigationBarItem(icon: Icon(LucideIcons.sparkles, size: 20), label: 'Animes'),
          ],
        ),
      ),
    );
  }

  // Retorna a view correta baseado no índice
  Widget _buildCurrentView() {
    if (_currentTabIndex == 0) {
      return _buildHomeView();
    } else if (_currentTabIndex >= 1 && _currentTabIndex <= 3) {
      return _buildCatalogView();
    } else {
      return _buildSearchView();
    }
  }

  // 1. HOME VIEW
  Widget _buildHomeView() {
    final api = Provider.of<ApiService>(context, listen: false);
    
    return FutureBuilder<Map<String, List<MediaItem>>>(
      future: api.fetchFeed(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(LucideIcons.alertTriangle, size: 48, color: Colors.orangeAccent),
                const SizedBox(height: 16),
                const Text('Erro ao conectar ao proxy.', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Tentar Novamente', style: TextStyle(color: Color(0xFF6366F1))),
                ),
              ],
            ),
          );
        }

        final data = snapshot.data!;
        final movies = data['recent_movies'] ?? [];
        final series = data['recent_series'] ?? [];
        
        // Featured Hero Item (Primeiro filme/série com backdrop)
        final allMedia = [...movies, ...series];
        MediaItem? heroItem;
        if (allMedia.isNotEmpty) {
          heroItem = allMedia.firstWhere(
            (item) => item.backdrop != null,
            orElse: () => allMedia.first,
          );
        }

        return ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // Hero Banner
            if (heroItem != null) ...[
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => DetailsScreen(item: heroItem!)),
                ),
                child: Container(
                  height: 240,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: DecorationImage(
                      image: NetworkImage(heroItem.backdrop ?? heroItem.poster ?? ''),
                      fit: BoxFit.cover,
                    ),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Stack(
                    children: [
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(23),
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.85),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366F1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'DESTAQUE',
                                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              heroItem.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 24,
                                fontWeight: FontWeight.black,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${heroItem.year ?? ''}  •  ${heroItem.genres.take(2).join(', ')}',
                              style: const TextStyle(fontSize: 12, color: Colors.white58),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Recent Movies List
            if (movies.isNotEmpty) ...[
              _buildHomeCarousel('Filmes Recentes', movies),
            ],
            
            // Recent Series List
            if (series.isNotEmpty) ...[
              _buildHomeCarousel('Séries Recentes', series),
            ],
          ],
        );
      },
    );
  }

  Widget _buildHomeCarousel(String title, List<MediaItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: 'Outfit',
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 20),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Container(
                width: 110,
                margin: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailsScreen(item: item)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Poster
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          item.poster ?? '',
                          height: 150,
                          width: 110,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 150,
                            color: const Color(0xFF151833),
                            child: const Icon(LucideIcons.film, color: Colors.white30),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        item.year?.toString() ?? '',
                        style: const TextStyle(fontSize: 10, color: Colors.white38),
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

  // 2. CATALOG VIEW (Filmes, Séries, Animes)
  Widget _buildCatalogView() {
    if (_isCatalogLoading && _catalogItems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      children: [
        // Filter dropdowns row
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Gênero
                _buildDropdownFilter(
                  label: 'Gênero',
                  value: _selectedGenre,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos')),
                    ..._genres.map((g) => DropdownMenuItem(
                      value: g['id'].toString(),
                      child: Text(g['name'] ?? ''),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedGenre = val ?? '';
                      _catalogPage = 1;
                    });
                    _loadCatalogItems();
                  },
                ),
                const SizedBox(width: 8),
                
                // Ano
                _buildDropdownFilter(
                  label: 'Ano',
                  value: _selectedYear,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('Todos')),
                    ..._years.map((y) => DropdownMenuItem(
                      value: y['year'].toString(),
                      child: Text(y['year'].toString()),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedYear = val ?? '';
                      _catalogPage = 1;
                    });
                    _loadCatalogItems();
                  },
                ),
                const SizedBox(width: 8),
                
                // Ordenação
                _buildDropdownFilter(
                  label: 'Ordem',
                  value: _selectedSort,
                  items: const [
                    DropdownMenuItem(value: 'recent', child: Text('Recentes')),
                    DropdownMenuItem(value: 'views', child: Text('Mais Vistos')),
                    DropdownMenuItem(value: 'rating', child: Text('Melhores')),
                    DropdownMenuItem(value: 'year', child: Text('Lançamento')),
                    DropdownMenuItem(value: 'alphabetical', child: Text('A - Z')),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedSort = val ?? 'recent';
                      _catalogPage = 1;
                    });
                    _loadCatalogItems();
                  },
                ),
              ],
            ),
          ),
        ),
        
        // Grid view
        Expanded(
          child: _isCatalogLoading
              ? const Center(child: CircularProgressIndicator())
              : _catalogItems.isEmpty
                  ? const Center(child: Text('Nenhum item correspondente.'))
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: _catalogItems.length,
                      itemBuilder: (context, index) {
                        final item = _catalogItems[index];
                        return _buildMediaCard(item);
                      },
                    ),
        ),
        
        // Pagination Bar
        if (_catalogItems.isNotEmpty) _buildPaginationBox(),
      ],
    );
  }

  Widget _buildDropdownFilter({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF151833).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(label),
          onChanged: onChanged,
          items: items,
          style: const TextStyle(fontSize: 12, color: Colors.white),
          dropdownColor: const Color(0xFF151833),
          icon: const Icon(LucideIcons.chevronDown, size: 14),
        ),
      ),
    );
  }

  Widget _buildPaginationBox() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: _catalogPage <= 1 ? null : () {
              setState(() {
                _catalogPage--;
              });
              _loadCatalogItems();
            },
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          const SizedBox(width: 16),
          Text(
            'Página $_catalogPage de $_catalogLastPage',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: _catalogPage >= _catalogLastPage ? null : () {
              setState(() {
                _catalogPage++;
              });
              _loadCatalogItems();
            },
            icon: const Icon(LucideIcons.chevronRight),
          ),
        ],
      ),
    );
  }

  // 3. SEARCH VIEW
  Widget _buildSearchView() {
    if (_isSearchLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Resultados para: "${_searchController.text}"',
            style: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
        ),
        Expanded(
          child: _searchResults.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.info, size: 48, color: Colors.white24),
                      SizedBox(height: 12),
                      Text('Nenhum resultado encontrado.', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.62,
                  ),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return _buildMediaCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMediaCard(MediaItem item) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailsScreen(item: item)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                item.poster ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF151833),
                  child: const Center(
                    child: Icon(LucideIcons.film, color: Colors.white30),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item.year?.toString() ?? '',
                style: const TextStyle(fontSize: 9, color: Colors.white38),
              ),
              if (item.ratingAvg != null) ...[
                Row(
                  children: [
                    const Icon(LucideIcons.star, size: 8, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      item.ratingAvg!.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 9, color: Colors.amber, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ]
            ],
          )
        ],
      ),
    );
  }
}
