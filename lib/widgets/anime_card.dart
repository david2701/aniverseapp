import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/details/details_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:nekoflow/utils/converter.dart';

class AnimeCard extends StatelessWidget {
  final BaseAnimeCard anime;
  final dynamic tag;
  final VoidCallback? onLongPress; // Callback for long press (for multi-select)
  final bool isListLayout; // New parameter to switch between layouts

  const AnimeCard({
    super.key,
    required this.anime,
    required this.tag,
    this.onLongPress,
    this.isListLayout = false, // Default to grid layout
  });

  void _navigateToDetails(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => DetailsScreen(
          id: anime.id,
          image: getHighResImage(anime.poster),
          name: anime.name,
          tag: tag,
          type: anime.type,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isListLayout ? _buildListLayout(context) : _buildGridLayout(context);
  }

  Widget _buildGridLayout(BuildContext context) {
    return AspectRatio(
      aspectRatio:
          2 / 3, // Adjust the aspect ratio as needed (e.g., 600x800 is 2:3)
      child: _buildCardContent(context, isGrid: true),
    );
  }

  Widget _buildListLayout(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: _buildCardContent(context, isGrid: false),
    );
  }

  Widget _buildCardContent(BuildContext context, {required bool isGrid}) {
    return GestureDetector(
      // onTap: () => _navigateToDetails(context),
      onTap: () => context.pushTransparentRoute(
        DetailsScreen(
          id: anime.id,
          image: getHighResImage(anime.poster),
          name: anime.name,
          tag: tag,
          type: anime.type,
        ),
      ),
      onLongPress: onLongPress,
      child: isGrid
          ? _buildGridCardContent(context)
          : _buildListCardContent(context),
    );
  }

  Widget _buildGridCardContent(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Full-width and height image
          Hero(
            tag: 'poster-${anime.id}-$tag',
            child: CachedNetworkImage(
              imageUrl: getHighResImage(anime.poster),
              fit: BoxFit
                  .cover, // Ensures the image fills the card area proportionally
              width: double.infinity, // Take full width
              height: double.infinity, // Take full height
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
          // Gradient overlay
          _buildGradientOverlay(),
          // Title positioned at the bottom
          _buildTitle(context),
          // Type chip in the top right corner
          if (anime.type != null) _buildTypeChip(context),
        ],
      ),
    );
  }

  Widget _buildListCardContent(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 180,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Poster
          Hero(
            tag: 'poster-${anime.id}-$tag',
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: CachedNetworkImage(
                imageUrl: getHighResImage(anime.poster),
                width: 120,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Hero(
                    tag: 'title-${anime.id}-$tag',
                    child: Text(
                      anime.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Type Chip (if available)
                  if (anime.type != null)
                    Chip(
                      label: Text(
                        anime.type!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.5),
                    ),

                  const Spacer(),

                  // Additional info can be added here
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedInformationSquare,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        onPressed: () => _navigateToDetails(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Color(0xCC000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(BuildContext context) {
    return Positioned(
      top: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          anime.type!,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Hero(
        tag: 'title-${anime.id}-$tag',
        child: Text(
          anime.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
