import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/settings/settings_screen.dart';
import 'package:nekoflow/widgets/spotlight_card.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nekoflow/data/models/anime_model.dart';
import 'package:nekoflow/data/services/anime_service.dart';
import 'package:nekoflow/widgets/anime_card.dart';
import 'package:nekoflow/widgets/snapping_scroll.dart';

import '../details/details_screen.dart';

class HomeScreen extends StatefulWidget {
  static const double _horizontalPadding = 20.0;
  static const double _sectionSpacing = 50.0;

  final String name;

  const HomeScreen({super.key, this.name = 'Guest'});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AnimeService _animeService = AnimeService();

  List<TopAiringAnime> _topAiring = [];
  List<LatestCompletedAnime> _completed = [];
  List<MostPopularAnime> _popular = [];
  List<SpotlightAnime> _spotlight = [];
  List<LatestEpisodeAnime> _latestEpisodes = [];
  List<UpcomingAnime> _upcomingAnimes = [];
  TopAnimeList _top10Animes = TopAnimeList(today: [], week: [], month: []);
  bool _isLoading = true;
  // String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      // _error = null;
    });

    try {
      final results = await _animeService.fetchHome();
      if (!mounted) return;

      setState(() {
        _spotlight = results.data.spotlightAnimes;
        _topAiring = results.data.topAiringAnimes;
        _popular = results.data.mostPopularAnimes;
        _completed = results.data.latestCompletedAnimes;
        _completed = results.data.latestCompletedAnimes;
        _latestEpisodes = results.data.latestEpisodeAnimes;
        _upcomingAnimes = results.data.topUpcomingAnimes;
        _top10Animes = results.data.top10Animes;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // _error = 'Something went wrong';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _animeService.dispose();
    super.dispose();
  }

  Widget _buildAppBarTitle(ThemeData theme) {
    return Row(
      children: [
        Container(
          height: 35,
          width: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.primary.withOpacity(0.1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(6.0),
            child: Image.asset(
              'assets/images/IconApp.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Welcome back,",
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            Text(
              widget.name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Widget _buildHeaderSection(ThemeData theme) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text(
  //               "Welcome back,",
  //               style: theme.textTheme.bodyLarge?.copyWith(
  //                 color: theme.colorScheme.secondary,
  //               ),
  //             ),
  //             Text(
  //               widget.name,
  //               style: theme.textTheme.headlineSmall?.copyWith(
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //           ],
  //         ),
  //         Container(
  //           height: 40,
  //           width: 40,
  //           decoration: BoxDecoration(
  //             shape: BoxShape.circle,
  //             color: theme.colorScheme.primary.withOpacity(0.1),
  //           ),
  //           child: Padding(
  //             padding: const EdgeInsets.all(8.0),
  //             child: Image.asset(
  //               'assets/images/IconApp.png',
  //               fit: BoxFit.contain,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }


  Widget? _buildLatestEpisodesSection({
    required String title,
    required List<LatestEpisodeAnime> animeList,
    required String tag,
    required ThemeData theme,
  }) {
    if (animeList.isEmpty && !_isLoading) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading(theme, 0.4)
            : SnappingScroller(
          showIndicators: false,
          widthFactor: 0.48,
          children: animeList
              .map((anime) =>
              AnimeCard(
                anime: _LatestEpisodeAdapter(anime),
                tag: tag,
              ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildShimmerLoading(ThemeData theme, double factor) {
    final screenSize = MediaQuery.of(context).size;

    return Shimmer.fromColors(
      baseColor: theme.colorScheme.primary.withOpacity(0.5),
      highlightColor: theme.colorScheme.secondary,
      child: Padding(
        padding: EdgeInsets.only(bottom: factor > 0.8 ? 20 : 0),
        child: SizedBox(
          height: screenSize.width * 0.6,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            padding: EdgeInsets.zero,
            itemBuilder: (_, __) => Container(
              height: double.infinity,
              width: screenSize.width * factor,
              margin: const EdgeInsets.only(right: 5),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Widget? _buildSpotlightSection({
  //   required String title,
  //   required List<SpotlightAnime> animeList,
  //   required String tag,
  //   required ThemeData theme,
  // }) {
  //   if (animeList.isEmpty && !_isLoading) return null;
  //
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       if (title.isNotEmpty) ...[
  //         Text(
  //           title,
  //           style: theme.textTheme.headlineMedium,
  //         ),
  //         const SizedBox(height: 10),
  //       ],
  //       _isLoading
  //           ? _buildShimmerLoading(theme, 0.9)
  //           : SnappingScroller(
  //               autoScroll: true,
  //               widthFactor: 1,
  //               children: animeList
  //                   .map((anime) => SpotlightCard(
  //                         anime: anime,
  //                         tag: tag,
  //                       ))
  //                   .toList(),
  //             ),
  //     ],
  //   );
  // }


  Widget? _buildContentSection({
    required String title,
    required List<BaseAnimeCard> animeList,
    required String tag,
    required ThemeData theme,
  }) {
    if (animeList.isEmpty && !_isLoading) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading(theme, 0.41)
            : SnappingScroller(
                showIndicators: false,
                widthFactor: 0.48,
                children: animeList
                    .map((anime) => AnimeCard(anime: anime, tag: tag))
                    .toList(),
              ),
      ],
    );
  }

  List<Widget> _buildContentSections(ThemeData theme) {
    final sections = <Widget>[];
    Widget? section;

    // Top 10 Section
    sections.add(_buildTop10Section(theme));
    sections.add(const SizedBox(height: HomeScreen._sectionSpacing));

    // Latest Episodes Section
    section = _buildLatestEpisodesSection(
      title: "Latest Episodes",
      animeList: _latestEpisodes,
      tag: "latest",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Popular Section
    section = _buildContentSection(
      title: "Popular",
      animeList: _popular,
      tag: "popular",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Top Airing Section
    section = _buildContentSection(
      title: "Top Airing",
      animeList: _topAiring,
      tag: "topairing",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Upcoming Anime Section
    section = _buildUpcomingSection(
      title: "Upcoming Anime",
      animeList: _upcomingAnimes,
      tag: "upcoming",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
      sections.add(const SizedBox(height: HomeScreen._sectionSpacing));
    }

    // Latest Completed Section
    section = _buildContentSection(
      title: "Latest Completed",
      animeList: _completed,
      tag: "latestcompleted",
      theme: theme,
    );
    if (section != null) {
      sections.add(section);
    }

    // Remove last spacing if it exists
    if (sections.isNotEmpty && sections.last is SizedBox) {
      sections.removeLast();
    }

    return sections;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final spotlightHeight = mediaQuery.size.height * 0.5;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: spotlightHeight,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            title: _buildAppBarTitle(theme),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () => Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (context) => SettingsScreen()),
                ),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSettings01,
                  color: theme.colorScheme.onSurface,
                ),
              )
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: _isLoading
                  ? _buildShimmerLoading(theme, 1.0)
                  : _spotlight.isNotEmpty
                  ? SnappingScroller(
                autoScroll: true,
                widthFactor: 1,
                children: _spotlight
                    .map((anime) => SpotlightCard(
                  anime: anime,
                  tag: "spotlight",
                ))
                    .toList(),
              )
                  : Container(),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: HomeScreen._horizontalPadding,
              ),
              child: Column(
                children: _buildContentSections(theme),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTop10List(List<TopAnime> animes, ThemeData theme) {
    if (animes.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: theme.textTheme.bodyLarge,
        ),
      );
    }

    return ListView.builder(
      itemCount: animes.length,
      padding: const EdgeInsets.only(top: 10),
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final anime = animes[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DetailsScreen(
                      name: anime.name,
                      id: anime.id,
                      image: anime.poster,
                      tag: 'top10',
                      //type: anime.,
                    ),
              ),
            );
          },
          child: Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '#${index + 1}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      anime.poster,
                      width: 50,
                      height: 70,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 50,
                          height: 70,
                          color: theme.colorScheme.surface,
                          child: Icon(
                            Icons.broken_image,
                            color: theme.colorScheme.onSurface,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anime.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          anime.jname,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.subtitles,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Sub: ${anime.episodes.sub}',
                              style: theme.textTheme.bodySmall,
                            ),
                            const SizedBox(width: 12),
                            Icon(
                              Icons.record_voice_over,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Dub: ${anime.episodes.dub}',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget? _buildUpcomingSection({
    required String title,
    required List<UpcomingAnime> animeList,
    required String tag,
    required ThemeData theme,
  }) {
    if (animeList.isEmpty && !_isLoading) return null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 10),
        _isLoading
            ? _buildShimmerLoading(theme, 0.4)
            : SnappingScroller(
          showIndicators: false,
          widthFactor: 0.48,
          children: animeList
              .map((anime) =>
              AnimeCard(
                anime: _UpcomingAnimeAdapter(anime),
                tag: tag,
              ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTop10Section(ThemeData theme) {
    if (_top10Animes.today.isEmpty && _top10Animes.week.isEmpty &&
        _top10Animes.month.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Top 10",
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal),
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: "Today"),
                  Tab(text: "Week"),
                  Tab(text: "Month"),
                ],
              ),
              SizedBox(
                height: 300,
                child: TabBarView(
                  children: [
                    _buildTop10List(_top10Animes.today, theme),
                    _buildTop10List(_top10Animes.week, theme),
                    _buildTop10List(_top10Animes.month, theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _UpcomingAnimeAdapter implements BaseAnimeCard {
  final UpcomingAnime anime;

  _UpcomingAnimeAdapter(this.anime);

  @override
  String get id => anime.id;

  @override
  String get name => anime.name;

  @override
  String get poster => anime.poster;

  @override
  String get type => anime.type;
}

class _LatestEpisodeAdapter implements BaseAnimeCard {
  final LatestEpisodeAnime anime;

  _LatestEpisodeAdapter(this.anime);

  @override
  String get id => anime.id;

  @override
  String get name => anime.name;

  @override
  String get poster => anime.poster;

  @override
  String get type => anime.type;
}
