import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../data/models/anime_shedule.dart';
import '../../../data/services/anime_notification_service.dart';
import '../../../data/services/anime_service.dart';
import '../details/details_screen.dart';

class CachedSchedule {
  final List<ScheduledAnime> animes;
  final DateTime cacheTime;

  CachedSchedule(this.animes, this.cacheTime);

  bool isExpired() {
    final now = DateTime.now();
    return now.difference(cacheTime).inHours >= 24;
  }
}

class AnimeScheduleScreen extends StatefulWidget {
  const AnimeScheduleScreen({super.key});

  @override
  _AnimeScheduleScreenState createState() => _AnimeScheduleScreenState();
}

class _AnimeScheduleScreenState extends State<AnimeScheduleScreen> {
  final AnimeService _animeService = AnimeService();
  final AnimeNotificationService _notificationService =
      AnimeNotificationService();
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  final Map<String, CachedSchedule> _scheduleCache = {};
  final Map<String, bool> _loadingDays = {};
  Map<String, bool> _notificationStatus = {};
  bool _isLoadingMore = false;
  final ScrollController _dateScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  String _getCacheKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateWeekDates();
    _setupScrollListeners();
    _initNotifications();
    _loadSelectedDaySchedule();
    _loadNextDays();
  }

  Future<void> _initNotifications() async {
    await _notificationService.init();
    await _notificationService.requestPermissions();
    await _loadNotificationStatus();
  }

  Future<void> _loadNotificationStatus() async {
    final notifications =
        await _notificationService.getScheduledNotifications();
    setState(() {
      for (var notification in notifications) {
        _notificationStatus[notification['animeId']] = true;
      }
    });
  }

  void _setupScrollListeners() {
    _listScrollController.addListener(() {
      if (_listScrollController.position.pixels >=
          _listScrollController.position.maxScrollExtent - 200) {
        _loadMoreContent();
      }
    });
  }

  Future<void> _loadMoreContent() async {
    if (!_isLoadingMore) {
      setState(() => _isLoadingMore = true);
      await _loadNextDays();
      setState(() => _isLoadingMore = false);
    }
  }

  void _generateWeekDates() {
    final now = DateTime.now();
    _weekDates = List.generate(14, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }

  Future<void> _loadSelectedDaySchedule() async {
    final key = _getCacheKey(_selectedDate);
    if (_scheduleCache[key]?.isExpired() == false) return;

    setState(() => _loadingDays[key] = true);

    try {
      final schedule = await _animeService.fetchSchedule(_selectedDate);
      if (schedule.success && mounted) {
        // Programar notificaciones solo si es el día actual
        if (DateUtils.isSameDay(_selectedDate, DateTime.now())) {
          for (var anime in schedule.data.scheduledAnimes) {
            final timeComponents = anime.time.split(':');
            final scheduleTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              int.parse(timeComponents[0]),
              int.parse(timeComponents[1]),
            );

            // Solo programar si la hora aún no ha pasado
            if (scheduleTime.isAfter(DateTime.now())) {
              debugPrint('Programando notificación para ${anime.name} a las ${anime.time}');

              await _notificationService.scheduleAnimeNotification(
                id: anime.id.hashCode,
                title: 'New Episode Alert!',
                body: '${anime.name} will air in 5 minutes!',
                scheduledDate: scheduleTime,
                animeId: anime.id,
                imageUrl: anime.poster,
              );
            } else {
              debugPrint('Hora pasada para ${anime.name}, omitiendo notificación');
            }
          }
        }

        setState(() {
          _scheduleCache[key] = CachedSchedule(
            schedule.data.scheduledAnimes,
            DateTime.now(),
          );
          _loadingDays[key] = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading schedule: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
        setState(() => _loadingDays[key] = false);
      }
    }
  }

  Future<void> _loadNextDays() async {
    for (var date in _weekDates) {
      final key = _getCacheKey(date);
      if (_loadingDays[key] == true ||
          _scheduleCache[key]?.isExpired() == false) continue;

      try {
        _loadingDays[key] = true;
        final schedule = await _animeService.fetchSchedule(date);
        if (schedule.success && mounted) {
          setState(() {
            _scheduleCache[key] = CachedSchedule(
              schedule.data.scheduledAnimes,
              DateTime.now(),
            );
            _loadingDays[key] = false;
          });
        }
      } catch (e) {
        print('Error loading schedule for $date: $e');
        if (mounted) {
          setState(() => _loadingDays[key] = false);
        }
      }
    }
  }

  Future<void> _toggleNotification(ScheduledAnime anime) async {
    final isCurrentlyScheduled = _notificationStatus[anime.id] ?? false;
    final notificationId = anime.id.hashCode;

    if (isCurrentlyScheduled) {
      await _notificationService.cancelNotification(notificationId);
      setState(() => _notificationStatus[anime.id] = false);
    } else {
      final now = DateTime.now();
      final timeComponents = anime.time.split(':');
      final scheduleTime = DateTime(
        now.year,
        now.month,
        now.day,
        int.parse(timeComponents[0]),
        int.parse(timeComponents[1]),
      );

      await _notificationService.scheduleAnimeNotification(
        id: notificationId,
        title: 'New Episode Alert!',
        body: '${anime.name} will air in 5 minutes!',
        scheduledDate: scheduleTime,
        animeId: anime.id,
        imageUrl: anime.poster,
      );
      setState(() => _notificationStatus[anime.id] = true);
    }
  }

  void _updateWeekDates(bool next) {
    setState(() {
      if (next) {
        final lastDate = _weekDates.last;
        _weekDates = List.generate(14, (index) {
          return lastDate.add(Duration(days: index + 1));
        });
      } else {
        final firstDate = _weekDates.first;
        _weekDates = List.generate(14, (index) {
          return firstDate.subtract(Duration(days: 14 - index));
        });
      }
      _loadSelectedDaySchedule();
      _loadNextDays();
    });
  }

  Future<void> _refreshSchedule() async {
    final key = _getCacheKey(_selectedDate);
    _scheduleCache.remove(key);
    await _loadSelectedDaySchedule();
  }

  Widget _buildDateChip(DateTime date, ThemeData theme) {
    final key = _getCacheKey(date);
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isLoading = _loadingDays[key] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _selectedDate = date);
          _loadSelectedDaySchedule();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday && !isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              Text(
                DateFormat('E').format(date).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      height: 120,
      width: 85,
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(ScheduledAnime anime, ThemeData theme) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(
                name: anime.name,
                id: anime.id,
                image: anime.poster ?? '',
                tag: 'schedule-${anime.id}',
                type: 'TV',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: 'schedule-${anime.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: anime.poster != null
                      ? CachedNetworkImage(
                          imageUrl: anime.poster!,
                          height: 120,
                          width: 85,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            highlightColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            child: Container(
                              height: 120,
                              width: 85,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildImageError(theme),
                        )
                      : _buildImageError(theme),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anime.jname,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                anime.time,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = _getCacheKey(_selectedDate);
    final selectedDayAnimes = _scheduleCache[key]?.animes ?? [];
    final isLoadingSelected = _loadingDays[key] ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSchedule,
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _updateWeekDates(false),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _dateScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _weekDates
                                .map((date) => _buildDateChip(date, theme))
                                .toList(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _updateWeekDates(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoadingSelected
                  ? const Center(child: CircularProgressIndicator())
                  : selectedDayAnimes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 48,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No releases scheduled for this day',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _listScrollController,
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 100),
                              itemCount: selectedDayAnimes.length,
                              itemBuilder: (context, index) => _buildAnimeCard(
                                  selectedDayAnimes[index], theme),
                            ),
                            if (_isLoadingMore)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 80,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.scaffoldBackgroundColor
                                            .withOpacity(0),
                                        theme.scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _listScrollController.dispose();
    _animeService.dispose();
    super.dispose();
  }
}

/*



import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:collection';
import '../../../data/models/anime_shedule.dart';
import '../../../data/services/anime_service.dart';
import '../details/details_screen.dart';

// Clase para manejar el caché con expiración
class CachedSchedule {
  final List<ScheduledAnime> animes;
  final DateTime cacheTime;

  CachedSchedule(this.animes, this.cacheTime);

  bool isExpired() {
    final now = DateTime.now();
    return now.difference(cacheTime).inHours >= 24;
  }
}

class AnimeScheduleScreen extends StatefulWidget {
  const AnimeScheduleScreen({super.key});

  @override
  _AnimeScheduleScreenState createState() => _AnimeScheduleScreenState();
}

class _AnimeScheduleScreenState extends State<AnimeScheduleScreen> {
  final AnimeService _animeService = AnimeService();
  late DateTime _selectedDate;
  late List<DateTime> _weekDates;
  final Map<String, CachedSchedule> _scheduleCache = {};
  final Map<String, bool> _loadingDays = {};
  bool _isLoadingMore = false;
  final ScrollController _dateScrollController = ScrollController();
  final ScrollController _listScrollController = ScrollController();

  // Getter para obtener la key del caché basada en la fecha
  String _getCacheKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _generateWeekDates();
    _loadSelectedDaySchedule();
    _setupScrollListeners();
    _loadNextDays();
  }

  void _setupScrollListeners() {
    _listScrollController.addListener(() {
      if (_listScrollController.position.pixels >=
          _listScrollController.position.maxScrollExtent - 200) {
        _loadMoreContent();
      }
    });
  }

  Future<void> _loadMoreContent() async {
    if (!_isLoadingMore) {
      setState(() => _isLoadingMore = true);
      await _loadNextDays();
      setState(() => _isLoadingMore = false);
    }
  }

  void _generateWeekDates() {
    final now = DateTime.now();
    _weekDates = List.generate(14, (index) {
      return DateTime(now.year, now.month, now.day).add(Duration(days: index));
    });
  }

  List<ScheduledAnime>? _getCachedSchedule(DateTime date) {
    final key = _getCacheKey(date);
    final cached = _scheduleCache[key];
    if (cached != null && !cached.isExpired()) {
      return cached.animes;
    }
    // Si está expirado, eliminamos la entrada
    if (cached != null) {
      _scheduleCache.remove(key);
    }
    return null;
  }

  void _cacheSchedule(DateTime date, List<ScheduledAnime> animes) {
    final key = _getCacheKey(date);
    _scheduleCache[key] = CachedSchedule(animes, DateTime.now());
  }

  Future<void> _loadSelectedDaySchedule() async {
    final cached = _getCachedSchedule(_selectedDate);
    if (cached != null) return;

    final key = _getCacheKey(_selectedDate);
    setState(() => _loadingDays[key] = true);

    try {
      final schedule = await _animeService.fetchSchedule(_selectedDate);
      if (schedule.success && mounted) {
        setState(() {
          _cacheSchedule(_selectedDate, schedule.data.scheduledAnimes);
          _loadingDays[key] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading schedule: $e')),
        );
        setState(() => _loadingDays[key] = false);
      }
    }
  }

  Future<void> _loadNextDays() async {
    for (var date in _weekDates) {
      final key = _getCacheKey(date);
      if (_loadingDays[key] == true || _getCachedSchedule(date) != null)
        continue;

      try {
        _loadingDays[key] = true;
        final schedule = await _animeService.fetchSchedule(date);
        if (schedule.success && mounted) {
          setState(() {
            _cacheSchedule(date, schedule.data.scheduledAnimes);
            _loadingDays[key] = false;
          });
        }
      } catch (e) {
        print('Error loading schedule for $date: $e');
        if (mounted) {
          setState(() => _loadingDays[key] = false);
        }
      }
    }
  }

  void _updateWeekDates(bool next) {
    setState(() {
      if (next) {
        final lastDate = _weekDates.last;
        _weekDates = List.generate(14, (index) {
          return lastDate.add(Duration(days: index + 1));
        });
      } else {
        final firstDate = _weekDates.first;
        _weekDates = List.generate(14, (index) {
          return firstDate.subtract(Duration(days: 14 - index));
        });
      }
      _loadSelectedDaySchedule();
      _loadNextDays();
    });
  }

  Future<void> _refreshSchedule() async {
    final key = _getCacheKey(_selectedDate);
    _scheduleCache.remove(key);
    await _loadSelectedDaySchedule();
  }

  Widget _buildDateChip(DateTime date, ThemeData theme) {
    final key = _getCacheKey(date);
    final isSelected = DateUtils.isSameDay(date, _selectedDate);
    final isToday = DateUtils.isSameDay(date, DateTime.now());
    final isLoading = _loadingDays[key] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() => _selectedDate = date);
          _loadSelectedDaySchedule();
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                    ? theme.colorScheme.primary.withOpacity(0.1)
                    : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isToday && !isSelected
                  ? theme.colorScheme.primary
                  : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
              Text(
                DateFormat('E').format(date).toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date.day.toString(),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: isSelected
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isToday)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageError(ThemeData theme) {
    return Container(
      height: 120,
      width: 85,
      color: theme.colorScheme.primary.withOpacity(0.1),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 4),
          Text(
            'No Image',
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimeCard(ScheduledAnime anime, ThemeData theme) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailsScreen(
                name: anime.name,
                id: anime.id,
                image: anime.poster ?? '',
                tag: 'schedule-${anime.id}',
                type: 'TV',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Hero(
                tag: 'schedule-${anime.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: anime.poster != null
                      ? CachedNetworkImage(
                          imageUrl: anime.poster!,
                          height: 120,
                          width: 85,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Shimmer.fromColors(
                            baseColor:
                                theme.colorScheme.primary.withOpacity(0.1),
                            highlightColor:
                                theme.colorScheme.primary.withOpacity(0.2),
                            child: Container(
                              height: 120,
                              width: 85,
                              color: Colors.white,
                            ),
                          ),
                          errorWidget: (context, url, error) =>
                              _buildImageError(theme),
                        )
                      : _buildImageError(theme),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      anime.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      anime.jname,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                anime.time,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final key = _getCacheKey(_selectedDate);
    final selectedDayAnimes = _getCachedSchedule(_selectedDate) ?? [];
    final isLoadingSelected = _loadingDays[key] ?? false;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshSchedule,
        child: Column(
          children: [
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () => _updateWeekDates(false),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: _dateScrollController,
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _weekDates
                                .map((date) => _buildDateChip(date, theme))
                                .toList(),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _updateWeekDates(true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: isLoadingSelected
                  ? const Center(child: CircularProgressIndicator())
                  : selectedDayAnimes.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 48,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No releases scheduled for this day',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : Stack(
                          children: [
                            ListView.builder(
                              controller: _listScrollController,
                              padding:
                                  const EdgeInsets.only(top: 16, bottom: 100),
                              itemCount: selectedDayAnimes.length,
                              itemBuilder: (context, index) => _buildAnimeCard(
                                  selectedDayAnimes[index], theme),
                            ),
                            if (_isLoadingMore)
                              Positioned(
                                bottom: 0,
                                left: 0,
                                right: 0,
                                child: Container(
                                  height: 80,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        theme.scaffoldBackgroundColor
                                            .withOpacity(0),
                                        theme.scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                              ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    _listScrollController.dispose();
    _animeService.dispose();
    super.dispose();
  }
}
*/
