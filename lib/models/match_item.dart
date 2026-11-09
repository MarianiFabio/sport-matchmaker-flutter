import 'package:flutter/material.dart';

// Modello per ogni giocatore nel roster della partita (caricato dal JSON del server)
class RosterPlayer {
  final String name;
  final String role;
  final int karma;
  final String level;

  const RosterPlayer({
    required this.name,
    required this.role,
    required this.karma,
    required this.level,
  });

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    return RosterPlayer(
      name: (json['name'] ?? 'Player').toString(),
      role: (json['role'] ?? 'Player').toString(),
      karma: int.tryParse((json['karma'] ?? '100').toString()) ?? 100,
      level: (json['level'] ?? 'Intermediate').toString(),
    );
  }
}

// Modello per ogni opzione di Sport + Formato restituita da api.php?action=get_sports
class SportFormatOption {
  final int idSport;
  final String sportName;
  final String category;
  final String format;
  final int defaultPlayers;

  const SportFormatOption({
    required this.idSport,
    required this.sportName,
    required this.category,
    required this.format,
    required this.defaultPlayers,
  });

  factory SportFormatOption.fromJson(Map<String, dynamic> json) {
    return SportFormatOption(
      idSport: int.tryParse((json['id_sport'] ?? '0').toString()) ?? 0,
      sportName: (json['sport_name'] ?? '').toString(),
      category: (json['sport_category'] ?? '').toString(),
      format: (json['sport_format'] ?? '').toString(),
      defaultPlayers: int.tryParse((json['default_players'] ?? '10').toString()) ?? 10,
    );
  }
}

class MatchItem {
  final int? id;
  final String sport;
  final String category;
  final String format;
  final String title;
  final String venue;
  final String date;
  final String rawDate; // YYYY-MM-DD per filtrare per data
  final String kickOffTime;
  final String time;
  final int spotsNeeded;
  final int totalSpots;
  final double feePerPerson;
  final IconData icon;
  final String? organizerName;
  final List<RosterPlayer> roster;

  const MatchItem({
    this.id,
    required this.sport,
    required this.category,
    required this.format,
    required this.title,
    required this.venue,
    required this.date,
    required this.rawDate,
    required this.kickOffTime,
    required this.time,
    required this.spotsNeeded,
    required this.totalSpots,
    required this.feePerPerson,
    required this.icon,
    this.organizerName,
    this.roster = const [],
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final String sportName = (json['sport_name'] ?? 'Sport Match').toString();
    final String sportCategory = (json['sport_category'] ?? 'Other').toString();
    final String sportFormat = (json['sport_format'] ?? '').toString();

    final String datePart = (json['match_date'] ?? '').toString();
    final String rawDatePart = (json['raw_date'] ?? '').toString();
    final String timePart = (json['match_time'] ?? '').toString();
    final String formattedTime = timePart.isNotEmpty && datePart.isNotEmpty
        ? '$datePart, $timePart'
        : (datePart.isNotEmpty ? datePart : timePart);

    final int needed = _parseInt(json['spots_needed'], defaultValue: 1);
    final int total = _parseInt(json['total_spots'], defaultValue: 10);
    final double fee = double.tryParse((json['fee_per_person'] ?? '0').toString()) ?? 0.0;

    final String venueName = (json['venue_name'] ?? 'Sports Center').toString();
    final String matchTitle = (json['title'] ??
        'Looking for $needed player${needed == 1 ? '' : 's'} for $sportName')
        .toString();

    final List<RosterPlayer> parsedRoster = [];
    if (json['roster'] is List) {
      for (final item in (json['roster'] as List)) {
        if (item is Map<String, dynamic>) {
          parsedRoster.add(RosterPlayer.fromJson(item));
        }
      }
    }

    return MatchItem(
      id: _parseInt(json['id_match'], defaultValue: 0),
      sport: sportName,
      category: sportCategory,
      format: sportFormat,
      title: matchTitle,
      venue: venueName,
      date: datePart,
      rawDate: rawDatePart,
      kickOffTime: timePart,
      time: formattedTime.isNotEmpty ? formattedTime : 'Time TBD',
      spotsNeeded: needed,
      totalSpots: total,
      feePerPerson: fee,
      icon: iconForCategory(sportCategory),
      organizerName: json['organizer_name']?.toString(),
      roster: parsedRoster,
    );
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static IconData iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'football':
        return Icons.sports_soccer;
      case 'basketball':
        return Icons.sports_basketball;
      case 'padel':
      case 'tennis':
      case 'badminton':
      case 'table tennis':
        return Icons.sports_tennis;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'rugby':
        return Icons.sports_rugby;
      default:
        return Icons.sports;
    }
  }
}