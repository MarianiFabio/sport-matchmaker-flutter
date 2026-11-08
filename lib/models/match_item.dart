import 'package:flutter/material.dart';

// classe per i dati delle partite, niente roba complessa
// cosi mi basta passare sto oggetto tra le varie view
class MatchItem {
  final int? id;
  final String sport;
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
    required this.title,
    required this.venue,
    required this.time,
    required this.spotsNeeded,
    required this.totalSpots,
    required this.icon,
    this.organizerName,
  });

  /// Factory constructor per mappare il JSON restituito dall'API PHP (XAMPP)
  /// sia con SELECT * FROM `MATCH` sia con eventuale JOIN su SPORT, VENUE e USER.
  factory MatchItem.fromJson(Map<String, dynamic> json) {
    final int? sportId = json['ID_Sport'] != null || json['id_sport'] != null
        ? _parseInt(json['ID_Sport'] ?? json['id_sport'])
        : null;

    final String sportName = (json['Sport'] ??
            json['Nome_Sport'] ??
            json['sport_name'] ??
            json['sport'] ??
            _sportNameFromId(sportId))
        .toString();

    final String datePart =
        (json['Data'] ?? json['match_date'] ?? json['date'] ?? '').toString();
    final String timePart =
        (json['Ora'] ?? json['Orario'] ?? json['match_time'] ?? json['time'] ?? '')
            .toString();
    final String formattedTime = timePart.isNotEmpty && datePart.isNotEmpty
        ? '$datePart, $timePart'
        : (datePart.isNotEmpty ? datePart : timePart);

    final int needed = _parseInt(
      json['Posti_Mancanti'] ?? json['spots_needed'] ?? json['spotsNeeded'],
      defaultValue: 1,
    );
    final int total = _parseInt(
      json['Posti_Totali'] ??
          json['Max_Giocatori'] ??
          json['total_spots'] ??
          json['max_players'],
      defaultValue: 10,
    );

    final dynamic rawVenueId = json['ID_Venue'] ?? json['ID_Campo'] ?? json['id_venue'];
    final String venueName = (json['Campo'] ??
            json['Nome_Campo'] ??
            json['Luogo'] ??
            json['venue_name'] ??
            json['venue'] ??
            (rawVenueId != null ? 'Campo #$rawVenueId' : 'Campo Sportivo'))
        .toString();

    final String matchTitle = (json['Titolo'] ??
            json['Descrizione'] ??
            json['Note'] ??
            json['title'] ??
            json['description'] ??
            'Cercasi $needed giocator${needed == 1 ? 'e' : 'i'} per $sportName')
        .toString();

    return MatchItem(
      id: _parseInt(json['ID_Match'] ?? json['id_match'] ?? json['id'], defaultValue: 0),
      sport: sportName,
      title: matchTitle,
      venue: venueName,
      time: formattedTime.isNotEmpty ? formattedTime : 'Orario da definire',
      spotsNeeded: needed,
      totalSpots: total,
      icon: _iconForSport(sportName),
      organizerName:
          (json['Organizzatore'] ?? json['organizer_name'] ?? json['organizer'])?.toString(),
    );
  }

  static String _sportNameFromId(int? id) {
    return switch (id) {
      1 => 'Football 5v5',
      2 => 'Basketball 3v3',
      3 => 'Padel / Tennis',
      4 => 'Volleyball',
      _ => 'Sport Match',
    };
  }

  static int _parseInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? defaultValue;
  }

  static IconData _iconForSport(String sport) {
    final s = sport.toLowerCase();
    if (s.contains('calc') || s.contains('foot') || s.contains('soccer')) {
      return Icons.sports_soccer;
    } else if (s.contains('bask') || s.contains('pallacanestro')) {
      return Icons.sports_basketball;
    } else if (s.contains('padel') || s.contains('tenn')) {
      return Icons.sports_tennis;
    } else if (s.contains('voll') || s.contains('pallavolo')) {
      return Icons.sports_volleyball;
    }
    return Icons.sports;
  }
}
