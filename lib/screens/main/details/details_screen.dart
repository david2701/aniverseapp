import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:nekoflow/data/boxes/watchlist_box.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/data/models/info_model.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/utils/converter.dart';
import 'package:nekoflow/widgets/bottom_player_bar.dart';
import 'package:nekoflow/widgets/episodes_list.dart';
import 'package:nekoflow/widgets/favorite_button.dart';
import 'package:shimmer/shimmer.dart';

class DetailsScreen extends StatefulWidget {
  final String name;
  final String id;
  final String image;
  final dynamic tag;
  final String? type;

  const DetailsScreen({
    super.key,
    required this.name,
    required this.id,
    required this.image,
    required this.tag,
    this.type,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  final ValueNotifier<bool> _isDescriptionExpanded = ValueNotifier(false);
  final ValueNotifier<List<Episode>> _episodes =
      ValueNotifier<List<Episode>>([]);
  final ValueNotifier<bool> _isLoadingEpisodes = ValueNotifier<bool>(true);
  late final AnimeService _animeService;
  late final WatchlistBox? _watchlistBox;
  final ScrollController _scrollController = ScrollController();
  ContinueWatchingItem? continueWatchingItem;
  String? _nextEpisodeId;
  String? _nextEpisodeTitle;
  AnimeData? info;
  String? error;

  @override
  void initState() {
    super.initState();
    _animeService = AnimeService();
    _initWatchlistBox();
    _fetchEpisodes();
  }

  Future<AnimeInfo?> fetchData() async {
    try {
      return await _animeService.fetchAnimeInfoById(id: widget.id);
    } catch (_) {
      setState(() => error = 'Network error occurred');
      return null;
    }
  }

  Future<void> _fetchEpisodes() async {
    try {
      final episodes = await _animeService.fetchEpisodes(id: widget.id);
      if (!mounted) return;
      _episodes.value = episodes;
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) {
        _isLoadingEpisodes.value = false;
        final Episode? nextEpisode = _getNextEpisode();
        _nextEpisodeId = nextEpisode?.episodeId;
        _nextEpisodeTitle = nextEpisode?.title;
        setState(() {});
      }
    }
  }

  Future<void> _initWatchlistBox() async {
    _watchlistBox = WatchlistBox();
    await _watchlistBox!.init();
    _loadContinueWatching();
  }

  void _loadContinueWatching() {
    continueWatchingItem = _watchlistBox!.getContinueWatchingById(widget.id);
    setState(() {});
  }

  Episode? _getNextEpisode() {
    int continueItemindex = _episodes.value.indexWhere(
        (item) => item.episodeId == continueWatchingItem?.episodeId);
    if (continueItemindex < _episodes.value.length) {
      return _episodes.value[continueItemindex + 1];
    }
    return null;
  }

  Widget _buildStatChip(IconData icon, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return GridView.count(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: (constraints.maxWidth / 2) / 70, // Adjusted ratio
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          children: [
            _buildInfoItem('Status', info?.anime?.moreInfo?.status ?? 'N/A'),
            _buildInfoItem('Aired', info?.anime?.moreInfo?.aired ?? 'N/A'),
            _buildInfoItem('Season', info?.anime?.moreInfo?.premiered ?? 'N/A'),
            _buildInfoItem(
              'Episodes',
              '${info?.anime?.info?.stats?.episodesSub ?? "N/A"} (Sub) / ${info?.anime?.info?.stats?.episodesDub ?? "N/A"} (Dub)',
            ),
          ],
        );
      },
    );
  }


// Agregar esta función para los contadores de episodios
  Widget _buildEpisodeCounter(String label, int? count, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.playlist_play, color: color, size: 20),
          SizedBox(width: 4),
          Text(
            '$count $label',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

// Agregar esta función para los géneros con colores
  Widget _buildGenreChips() {
    final colors = [
      Color(0xFFFF6B6B), // Rojo
      Color(0xFF4ECDC4), // Turquesa
      Color(0xFFFFBE0B), // Amarillo
      Color(0xFF845EC2), // Púrpura
      Color(0xFF008F7A), // Verde
      Color(0xFFFF9671), // Coral
      Color(0xFF4B4453), // Gris oscuro
      Color(0xFF59B0FF), // Azul claro
    ];

    return SizedBox(
      height: 35,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: info?.anime?.moreInfo?.genres?.length ?? 0,
        itemBuilder: (context, index) {
          final genre = info!.anime!.moreInfo!.genres![index];
          final color = colors[index % colors.length];

          return Container(
            margin: EdgeInsets.only(right: 8),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(
              genre,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Changed to min
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandableDescription() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isDescriptionExpanded,
      builder: (context, isExpanded, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedCrossFade(
              firstChild: Text(
                info?.anime?.info?.description ?? 'No description available',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              secondChild: Text(
                info?.anime?.info?.description ?? 'No description available',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: Duration(milliseconds: 300),
            ),
            TextButton(
              onPressed: () =>
                  _isDescriptionExpanded.value = !_isDescriptionExpanded.value,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size(60, 30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isExpanded ? 'Show Less' : 'Show More',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _isDescriptionExpanded.dispose();
    _animeService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DismissiblePage(
      onDismissed: () => Navigator.of(context).pop(),
      direction: DismissiblePageDismissDirection.horizontal,
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.background,
        body: FutureBuilder<AnimeInfo?>(
          future: fetchData(),
          builder: (context, snapshot) {
            final bool isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            info = snapshot.data?.data;

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  expandedHeight: MediaQuery.of(context).size.height * 0.5,
                  pinned: true,
                  actions: [
                    FavoriteButton(
                      animeId: widget.id,
                      title: widget.name,
                      image: widget.image,
                      type: widget.type,
                    ),
                    SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background image with blur
                        Hero(
                          tag: 'bg-${widget.id}',
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: CachedNetworkImage(
                              imageUrl: getHighResImage(widget.image),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Theme.of(context)
                                    .colorScheme
                                    .background
                                    .withOpacity(0.8),
                              ],
                            ),
                          ),
                        ),
                        // Content
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Género chips
                              if (info?.anime?.moreInfo?.genres != null)
                                _buildGenreChips(),
                              SizedBox(height: 12),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Poster
                                  Hero(
                                    tag: 'poster-${widget.id}',
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: CachedNetworkImage(
                                        imageUrl: getHighResImage(widget.image),
                                        width: 120,
                                        height: 180,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16),

                                  // Info básica
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.name,
                                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (info?.anime?.moreInfo?.japanese != null)
                                          Text(
                                            info!.anime!.moreInfo!.japanese!,
                                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                              color: Colors.white70,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        SizedBox(height: 8),

                                        // Episodios
                                        Row(
                                          children: [
                                            _buildEpisodeCounter(
                                              'Sub',
                                              info?.anime?.info?.stats?.episodesSub,
                                              Colors.blue,
                                            ),
                                            SizedBox(width: 8),
                                            _buildEpisodeCounter(
                                              'Dub',
                                              info?.anime?.info?.stats?.episodesDub,
                                              Colors.green,
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 8),

                                        // Stats
                                        SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: [
                                              _buildStatChip(Icons.star, info?.anime?.moreInfo?.malscore?.toString() ?? 'N/A'),
                                              SizedBox(width: 8),
                                              _buildStatChip(Icons.schedule, info?.anime?.info?.stats?.duration ?? 'N/A'),
                                              SizedBox(width: 8),
                                              _buildStatChip(Icons.movie, info?.anime?.info?.stats?.type ?? 'N/A'),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main content
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(32)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info Grid
                        _buildInfoGrid(),
                        SizedBox(height: 24),

                        // Studios
                        if (info?.anime?.moreInfo?.studios != null) ...[
                          Text(
                            'Studios',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Text(
                            info!.anime!.moreInfo!.studios ?? 'N/A',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          SizedBox(height: 24),
                        ],

                        // Producers
                        if (info?.anime?.moreInfo?.producers != null &&
                            info!.anime!.moreInfo!.producers!.isNotEmpty) ...[
                          Text(
                            'Producers',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: info!.anime!.moreInfo!.producers!
                                .map((producer) => Chip(
                                      label: Text(producer),
                                      backgroundColor: Theme.of(context)
                                          .colorScheme
                                          .secondary
                                          .withOpacity(0.1),
                                    ))
                                .toList(),
                          ),
                          SizedBox(height: 24),
                        ],

                        // Synopsis
                        Text(
                          'Synopsis',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 8),
                        _buildExpandableDescription(),
                        SizedBox(height: 24),

                        // Rating and Quality
                        if (info?.anime?.info?.stats != null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoBox(
                                  'Rating',
                                  info?.anime?.info?.stats?.rating ?? 'N/A',
                                  Icons.star_border,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoBox(
                                  'Quality',
                                  info?.anime?.info?.stats?.quality ?? 'N/A',
                                  Icons.high_quality,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                        ],

                        // Episodes List
                        SizedBox(height: 16),
                        ValueListenableBuilder<Box<WatchlistModel>>(
                          valueListenable: _watchlistBox!.listenable(),
                          builder: (context, value, child) {
                            continueWatchingItem = _watchlistBox!.getContinueWatchingById(widget.id);
                            return EpisodesList(
                              id: widget.id,
                              name: widget.name,
                              poster: info?.anime?.info?.poster ?? widget.image,
                              type: info?.anime?.info?.stats?.type ?? 'N/A',
                              watchedEpisodes: continueWatchingItem?.watchedEpisodes,
                              episodes: _episodes,
                              isLoading: _isLoadingEpisodes,
                              onToggleWatched: (episodeId) {
                                final currentEpisode = _episodes.value.firstWhere(
                                      (ep) => ep.episodeId == episodeId,
                                );

                                final item = continueWatchingItem ?? ContinueWatchingItem(
                                  id: widget.id,
                                  name: widget.name,
                                  poster: widget.image,
                                  episode: currentEpisode.number,
                                  episodeId: currentEpisode.episodeId,
                                  title: currentEpisode.title,
                                  type: widget.type,
                                  watchedEpisodes: [],
                                );

                                // Actualizar la lista de episodios vistos
                                final List<String> watchedList = List<String>.from(item.watchedEpisodes ?? []);
                                if (watchedList.contains(episodeId)) {
                                  watchedList.remove(episodeId);
                                } else {
                                  watchedList.add(episodeId);
                                }

                                // Crear nuevo item con la lista actualizada
                                final updatedItem = ContinueWatchingItem(
                                  id: item.id,
                                  name: item.name,
                                  poster: item.poster,
                                  episode: item.episode,
                                  episodeId: item.episodeId,
                                  title: item.title,
                                  type: item.type,
                                  watchedEpisodes: watchedList,
                                  isCompleted: item.isCompleted,
                                  timestamp: item.timestamp,
                                  duration: item.duration,
                                );

                                _watchlistBox!.updateContinueWatching(updatedItem);
                              },
                            );
                          },
                        ),
                        SizedBox(height: 80), // Space for bottom bar
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
        bottomNavigationBar: ValueListenableBuilder<Box<WatchlistModel>>(
          valueListenable: _watchlistBox!.listenable(),
          builder: (context, box, _) {
            continueWatchingItem =
                _watchlistBox!.getContinueWatchingById(widget.id);

            if (continueWatchingItem == null) {
              return const SizedBox.shrink();
            }

            return BottomPlayerBar(
              item: continueWatchingItem!,
              title: continueWatchingItem!.title,
              id: widget.id,
              image: widget.image,
              type: widget.type,
              nextEpisode: _nextEpisodeId,
              nextEpisodeTitle: _nextEpisodeTitle,
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.1),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}
