import 'package:flutter/material.dart';

// Modello dati della partita con supporto per categoria/tag dello sport
class MatchItem {
  final int? id;
  final String sport;
  final String category; // Tag per raggruppare sport simili (es. 'Football', 'Racket')
  final String title;
  final String venue;
  final String time;
  final int spotsNeeded;
  final int totalSpots;
  final IconData icon;
  final String? organizerName;

  const MatchItem({
    this.id,
    required this.sport,
    required this.category,
    required this.title,
    required this.venue,
    required this.time,
    required this.spotsNeeded,
    required this.totalSpots,
    required this.icon,
    this.organizerName,
  });

  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final int? sportId = json['id_sport'] != null || json['ID_Sport'] != null
        ? _parseInt(json['id_sport'] ?? json['ID_Sport'])
        : null;

    final String sportName = (json['sport_name'] ??
        json['Sport_Name'] ??
        json['sport'] ??
        _sportNameFromId(sportId))
        .toString();

    final String sportCategory = (json['sport_category'] ??
        json['Sport_Category'] ??
        _inferCategory(sportName))
        .toString();

    final String datePart =
    (json['match_date'] ?? json['Date'] ?? json['date'] ?? '').toString();
    final String timePart =
    (json['match_time'] ?? json['Start_Time'] ?? json['time'] ?? '')
        .toString();
    final String formattedTime = timePart.isNotEmpty && datePart.isNotEmpty
        ? '$datePart, $timePart'
        : (datePart.isNotEmpty ? datePart : timePart);

    final int needed = _parseInt(
      json['spots_needed'] ?? json['Remaining_Slots'] ?? json['spotsNeeded'],
      defaultValue: 1,
    );
    final int total = _parseInt(
      json['total_spots'] ?? json['Total_Slots'] ?? json['totalSpots'],
      defaultValue: 10,
    );

    final dynamic rawVenueId = json['id_venue'] ?? json['ID_Venue'];
    final String venueName = (json['venue_name'] ??
        json['Venue_Name'] ??
        json['venue'] ??
        (rawVenueId != null ? 'Venue #$rawVenueId' : 'Sports Center'))
        .toString();

    final String matchTitle = (json['title'] ??
        json['description'] ??
        'Looking for $needed player${needed == 1 ? '' : 's'} for $sportName')
        .toString();

    return MatchItem(
      id: _parseInt(json['id_match'] ?? json['ID_Match'] ?? json['id'], defaultValue: 0),
      sport: sportName,
      category: sportCategory,
      title: matchTitle,
      venue: venueName,
      time: formattedTime.isNotEmpty ? formattedTime : 'Time TBD',
      spotsNeeded: needed,
      totalSpots: total,
      icon: _iconForCategory(sportCategory, sportName),
      organizerName:
      (json['organizer_name'] ?? json['Organizer_Name'] ?? json['organizer'])?.toString(),
    );
  }

  static String _sportNameFromId(int? id) {
    return switch (id) {
      1 => 'Football 5v5',
      2 => 'Football 7v7',
      3 => 'Football 8v8',
      4 => 'Basketball 3v3',
      5 => 'Basketball 5v5',
      6 => 'Padel 2v2',
      7 => 'Tennis Singles 1v1',
      8 => 'Tennis Doubles 2v2',
      9 => 'Volleyball 6v6',
      10 => 'Beach Volley 2v2',
      _ => 'Sport Match',
    };
  }

  // Deduce la categoria se non viene passata esplicitamente dal JSON
  static String _inferCategory(String sportName) {
    final s = sportName.toLowerCase();
    if (s.contains('foot') || s.contains('soccer')) return 'Football';
    if (s.contains('bask')) return 'Basketball';
    if (s.contains('padel') || s.contains('tenn')) return 'Racket';
    if (s.contains('voll')) return 'Volleyball';
    return 'Other';
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static IconData _iconForCategory(String category, String sportName) {
    final c = category.toLowerCase();
    final s = sportName.toLowerCase();
    if (c == 'football' || s.contains('foot')) {
      return Icons.sports_soccer;
    } else if (c == 'basketball' || s.contains('bask')) {
      return Icons.sports_basketball;
    } else if (c == 'racket' || s.contains('padel') || s.contains('tenn')) {
      return Icons.sports_tennis;
    } else if (c == 'volleyball' || s.contains('voll')) {
      return Icons.sports_volleyball;
    }
    return Icons.sports;
  }
}