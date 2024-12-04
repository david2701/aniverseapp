import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/episodes_model.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';
import 'package:shimmer/shimmer.dart';
import 'package:dismissible_page/dismissible_page.dart';

class EpisodesList extends StatefulWidget {
  final String id;
  final String name;
  final String poster;
  final String type;
  final ValueNotifier<List<Episode>> episodes;
  final ValueNotifier<bool> isLoading;
  final int rangeSize;
  final List<String?>? watchedEpisodes;
  final Function(String) onToggleWatched;

  const EpisodesList({
    super.key,
    required this.id,
    required this.poster,
    required this.name,
    required this.type,
    required this.episodes,
    required this.isLoading,
    required this.onToggleWatched,
    this.rangeSize = 50,
    this.watchedEpisodes = const [],
  });

  @override
  State<EpisodesList> createState() => _EpisodesListState();
}

class _EpisodesListState extends State<EpisodesList> {
  bool _isGridLayout = false;
  int _selectedRangeIndex = 0;

  void _navigateToStreamScreen(BuildContext context, Episode episode) {
    context.pushTransparentRoute(
      StreamScreen(
        id: widget.id,
        name: widget.name,
        episodeId: episode.episodeId,
        poster: widget.poster,
        episode: episode.number,
        title: episode.title,
      ),
    );
  }

  List<Map<String, List<Episode>>> _getGroupedEpisodes(List<Episode> episodes) {
    if (episodes.isEmpty) return [];
    return List.generate(
      (episodes.length / widget.rangeSize).ceil(),
          (index) {
        final start = index * widget.rangeSize + 1;
        final end = (start + widget.rangeSize - 1).clamp(1, episodes.length);
        return {
          '$start - $end': episodes.sublist(
            index * widget.rangeSize,
            (index + 1) * widget.rangeSize > episodes.length
                ? episodes.length
                : (index + 1) * widget.rangeSize,
          )
        };
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isLoading,
      builder: (context, isLoading, _) {
        return ValueListenableBuilder<List<Episode>>(
          valueListenable: widget.episodes,
          builder: (context, episodes, _) {
            final groupedEpisodes = _getGroupedEpisodes(episodes);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EpisodesHeader(
                  episodes: episodes,
                  rangeSize: widget.rangeSize,
                  groupedEpisodes: groupedEpisodes,
                  isGridLayout: _isGridLayout,
                  selectedRangeIndex: _selectedRangeIndex,
                  onLayoutChanged: (isGrid) {
                    setState(() => _isGridLayout = isGrid);
                  },
                  onRangeChanged: (index) {
                    setState(() => _selectedRangeIndex = index);
                  },
                ),
                isLoading
                    ? _buildShimmerList(context)
                    : _EpisodesView(
                  episodes: episodes,
                  watchedEpisodes: widget.watchedEpisodes,
                  groupedEpisodes: groupedEpisodes,
                  rangeSize: widget.rangeSize,
                  isGridLayout: _isGridLayout,
                  selectedRangeIndex: _selectedRangeIndex,
                  onEpisodeSelected: (episode) =>
                      _navigateToStreamScreen(context, episode),
                  onToggleWatched: widget.onToggleWatched,
                ),
                const SizedBox(height: 25),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerList(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.primary.withOpacity(0.5),
      highlightColor: Theme.of(context).colorScheme.secondary,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 4,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.only(bottom: 15.0),
          child: Container(
            height: 70.0,
            decoration: BoxDecoration(
              color: Colors.grey[800]!,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }
}

class _EpisodesHeader extends StatelessWidget {
  final List<Episode> episodes;
  final List<Map<String, List<Episode>>> groupedEpisodes;
  final int rangeSize;
  final bool isGridLayout;
  final int selectedRangeIndex;
  final ValueChanged<bool> onLayoutChanged;
  final ValueChanged<int> onRangeChanged;

  const _EpisodesHeader({
    required this.episodes,
    required this.groupedEpisodes,
    required this.rangeSize,
    required this.isGridLayout,
    required this.selectedRangeIndex,
    required this.onLayoutChanged,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              "Episodes",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "${episodes.length}",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ),
          ],
        ),
        Row(
          children: [
            if (groupedEpisodes.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<int>(
                  value: selectedRangeIndex,
                  underline: SizedBox(),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  onChanged: (newIndex) {
                    if (newIndex != null) {
                      onRangeChanged(newIndex);
                    }
                  },
                  items: groupedEpisodes.asMap().entries.map((entry) {
                    return DropdownMenuItem<int>(
                      value: entry.key,
                      child: Text(
                        entry.value.keys.first,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    );
                  }).toList(),
                ),
              ),
            IconButton(
              icon: Icon(
                isGridLayout ? Icons.view_list : Icons.grid_view,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => onLayoutChanged(!isGridLayout),
            ),
          ],
        ),
      ],
    );
  }
}

class _EpisodesView extends StatelessWidget {
  final List<Episode> episodes;
  final List<String?>? watchedEpisodes;
  final List<Map<String, List<Episode>>> groupedEpisodes;
  final int rangeSize;
  final bool isGridLayout;
  final int selectedRangeIndex;
  final ValueChanged<Episode> onEpisodeSelected;
  final Function(String) onToggleWatched;

  const _EpisodesView({
    required this.episodes,
    required this.groupedEpisodes,
    required this.rangeSize,
    required this.isGridLayout,
    required this.selectedRangeIndex,
    required this.onEpisodeSelected,
    required this.watchedEpisodes,
    required this.onToggleWatched,
  });

  @override
  Widget build(BuildContext context) {
    if (groupedEpisodes.isEmpty) {
      return const Center(child: Text('No episodes available'));
    }

    final currentEpisodes = groupedEpisodes[selectedRangeIndex].values.first;

    return isGridLayout
        ? _buildGridView(context, currentEpisodes)
        : _buildListView(context, currentEpisodes);
  }

  Widget _buildListView(BuildContext context, List<Episode> episodes) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isWatched = watchedEpisodes?.contains(episode.episodeId) ?? false;

        return _EpisodeTile(
          episode: episode,
          onTap: () => onEpisodeSelected(episode),
          isWatched: isWatched,
          onToggleWatched: () => onToggleWatched(episode.episodeId),
        );
      },
    );
  }

  Widget _buildGridView(BuildContext context, List<Episode> episodes) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: episodes.length,
      itemBuilder: (context, index) {
        final episode = episodes[index];
        final isWatched = watchedEpisodes?.contains(episode.episodeId) ?? false;

        return _EpisodeGridTile(
          episode: episode,
          onTap: () => onEpisodeSelected(episode),
          isWatched: isWatched,
          onToggleWatched: () => onToggleWatched(episode.episodeId),
        );
      },
    );
  }
}

class _EpisodeGridTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final bool isWatched;
  final VoidCallback onToggleWatched;

  const _EpisodeGridTile({
    required this.episode,
    required this.onTap,
    required this.isWatched,
    required this.onToggleWatched,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
              border: !episode.isFiller
                  ? null
                  : Border.all(color: themeData.colorScheme.secondary, width: 2),
              gradient: LinearGradient(
                colors: isWatched
                    ? [
                  themeData.colorScheme.surface,
                  themeData.colorScheme.primary.withOpacity(0.2),
                ]
                    : [
                  !episode.isFiller
                      ? themeData.colorScheme.primary.withOpacity(0.4)
                      : themeData.colorScheme.surface,
                  !episode.isFiller
                      ? themeData.colorScheme.secondary.withOpacity(0.7)
                      : themeData.colorScheme.surface,
                ],
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${episode.number}",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (episode.isFiller)
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeData.colorScheme.secondary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        "FILLER",
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: themeData.colorScheme.secondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Watch status indicator
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onToggleWatched,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isWatched
                      ? Colors.green.withOpacity(0.9)
                      : themeData.colorScheme.surface.withOpacity(0.9),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isWatched
                        ? Colors.green
                        : themeData.colorScheme.onSurface.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  isWatched ? Icons.check : Icons.remove_red_eye_outlined,
                  size: 16,
                  color: isWatched
                      ? Colors.white
                      : themeData.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  final Episode episode;
  final VoidCallback onTap;
  final bool isWatched;
  final VoidCallback onToggleWatched;

  const _EpisodeTile({
    required this.episode,
    required this.onTap,
    required this.isWatched,
    required this.onToggleWatched,
  });

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 15.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        border: !episode.isFiller
            ? null
            : Border.all(color: themeData.colorScheme.secondary, width: 2),
        gradient: LinearGradient(
          colors: isWatched
              ? [
            themeData.colorScheme.surface,
            themeData.colorScheme.primary.withOpacity(0.2),
          ]
              : [
            !episode.isFiller
                ? themeData.colorScheme.primary.withOpacity(0.4)
                : themeData.colorScheme.surface,
            !episode.isFiller
                ? themeData.colorScheme.secondary.withOpacity(0.7)
                : themeData.colorScheme.surface,
          ],
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Container(
          width: 45,
          height: 45,
          decoration: BoxDecoration(
            color: themeData.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: themeData.colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              "${episode.number}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                episode.title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (episode.isFiller)
              Container(
                margin: EdgeInsets.only(left: 8),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: themeData.colorScheme.secondary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "FILLER",
                  style: TextStyle(
                    fontSize: 12,
                    color: themeData.colorScheme.secondary,
                  ),
                ),
              ),
          ],
        ),
        // Removemos la referencia a duration ya que no existe en el modelo
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Watch status toggle
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onToggleWatched,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isWatched
                        ? Colors.green.withOpacity(0.9)
                        : themeData.colorScheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWatched
                          ? Colors.green
                          : themeData.colorScheme.onSurface.withOpacity(0.2),
                    ),
                  ),
                  child: Icon(
                    isWatched ? Icons.check : Icons.remove_red_eye_outlined,
                    size: 18,
                    color: isWatched
                        ? Colors.white
                        : themeData.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            // Play button
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: themeData.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedPlay,
                    size: 20,
                    color: themeData.colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}