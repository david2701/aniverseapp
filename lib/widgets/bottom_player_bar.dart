import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:nekoflow/data/models/watchlist/watchlist_model.dart';
import 'package:nekoflow/screens/main/stream/stream_screen.dart';
import 'package:dismissible_page/dismissible_page.dart';

class BottomPlayerBar extends StatelessWidget {
  final ContinueWatchingItem item;
  final String title;
  final String id;
  final String image;
  final String? type;
  final String? nextEpisode;
  final String? nextEpisodeTitle;

  const BottomPlayerBar(
      {super.key,
      required this.item,
      required this.title,
      required this.id,
      required this.image,
      required this.type,
      this.nextEpisode,
      this.nextEpisodeTitle});

  // Refactored method for more robust timestamp parsing
  double _calculateProgress() {
    try {
      final timestampSeconds = _parseTimeToSeconds(item.timestamp);
      final durationSeconds = _parseTimeToSeconds(item.duration);

      if (durationSeconds > 0) {
        return (timestampSeconds / durationSeconds).clamp(0.0, 1.0);
      }

      return 0.0;
    } catch (e) {
      debugPrint('Error calculating progress: $e');
      return 0.0;
    }
  }

  // Helper method to parse time strings consistently
  int _parseTimeToSeconds(String timeString) {
    final parts = timeString.split(':');
    switch (parts.length) {
      case 3: // HH:mm:ss format
        return int.parse(parts[0]) * 3600 +
            int.parse(parts[1]) * 60 +
            int.parse(parts[2].split('.')[0]);
      case 2: // mm:ss format
        return int.parse(parts[0]) * 60 + int.parse(parts[1].split('.')[0]);
      default:
        throw FormatException('Invalid time format: $timeString');
    }
  }

  // Extracted navigation logic for better separation of concerns
  void _navigateToPlayer(
      BuildContext context, String episodeId, String episodeTitle) {
    context.pushTransparentRoute(StreamScreen(
      name: item.name,
      title: episodeTitle,
      id: id,
      episodeId: episodeId,
      poster: image,
      episode: item.episode,
      type: type,
    ));
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => StreamScreen(
    //       name: item.name,
    //       title: episodeTitle,
    //       id: id,
    //       episodeId: episodeId,
    //       poster: image,
    //       episode: item.episode,
    //       type: type,
    //     ),
    //   ),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = _calculateProgress();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 90,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: theme.colorScheme.surface.withOpacity(0.7),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
          child: Stack(
            children: [
              // Progress Indicator as Background
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary.withOpacity(0.5),
                  ),
                  minHeight: 4,
                ),
              ),

              // Content
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: CachedNetworkImageProvider(image),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),

                    // Episode Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Episode ${item.episode} • ${item.timestamp.split(':').length > 2 ? item.timestamp.split(':')[1] : '00'}:${item.timestamp.split(':').length > 2 ? double.parse(item.timestamp.split(':')[2]).floor() : '00'}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Action Buttons
                    Row(
                      children: [
                        IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            color: theme.colorScheme.onSurface,
                            size: 28,
                          ),
                          onPressed: () => _navigateToPlayer(
                              context, item.episodeId, item.title),
                        ),
                        if (nextEpisode != null && nextEpisodeTitle != null)
                          IconButton(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              color: theme.colorScheme.onSurface,
                              size: 28,
                            ),
                            onPressed: () => _navigateToPlayer(
                                context, nextEpisode!, nextEpisodeTitle!),
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
    );
  }
}
