class AnimeSchedule {
  final bool success;
  final ScheduleData data;

  AnimeSchedule({
    required this.success,
    required this.data,
  });

  factory AnimeSchedule.fromJson(Map<String, dynamic> json) {
    return AnimeSchedule(
      success: json['success'],
      data: ScheduleData.fromJson(json['data']),
    );
  }
}

class ScheduleData {
  final List<ScheduledAnime> scheduledAnimes;

  ScheduleData({required this.scheduledAnimes});

  factory ScheduleData.fromJson(Map<String, dynamic> json) {
    return ScheduleData(
      scheduledAnimes: (json['scheduledAnimes'] as List)
          .map((e) => ScheduledAnime.fromJson(e))
          .toList(),
    );
  }
}

class ScheduledAnime {
  final String id;
  final String time;
  final String name;
  final String jname;
  final int airingTimestamp;
  final int secondsUntilAiring;
  final String? poster;

  ScheduledAnime({
    required this.id,
    required this.time,
    required this.name,
    required this.jname,
    required this.airingTimestamp,
    required this.secondsUntilAiring,
    this.poster,
  });

  factory ScheduledAnime.fromJson(Map<String, dynamic> json) {
    return ScheduledAnime(
      id: json['id'],
      time: json['time'],
      name: json['name'],
      jname: json['jname'],
      airingTimestamp: json['airingTimestamp'],
      secondsUntilAiring: json['secondsUntilAiring'],
      poster: json['poster'],
    );
  }
}
