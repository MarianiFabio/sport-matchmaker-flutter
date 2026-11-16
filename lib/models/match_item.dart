import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Gestisce la sessione dell'utente loggato, le preferenze e le coordinate di ricerca geografica
class UserSession {
  static int currentUserId = 1;
  static String name = 'Fabio';
  static String surname = 'Mariani';
  static String email = 'fabio@email.com';
  static String username = 'fabio_m';
  static String city = 'Kaunas';
  static String abilityLevel = 'Advanced';
  static int karmaScore = 98;
  static List<String> favoriteSports = ['Football', 'Padel', 'Basketball'];

  // Punto geografico di riferimento scelto dall'utente (Default: Kaunas KTU Campus)
  static double searchLat = 54.9027;
  static double searchLng = 23.9575;
  static String searchLocationLabel = 'KTU Campus, Kaunas';

  static String get fullName => '$name $surname'.trim();

  static String get apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  static void updateFromJson(Map<String, dynamic> json) {
    if (json['id_user'] != null) {
      currentUserId = int.tryParse(json['id_user'].toString()) ?? currentUserId;
    }
    if (json['name'] != null) name = json['name'].toString();
    if (json['surname'] != null) surname = json['surname'].toString();
    if (json['email'] != null) email = json['email'].toString();
    if (json['username'] != null) username = json['username'].toString();
    if (json['city'] != null) {
      city = json['city'].toString();
      if (city.toLowerCase().contains('milan')) {
        searchLat = 45.4773;
        searchLng = 9.1895;
        searchLocationLabel = 'Milano Center';
      } else {
        searchLat = 54.9027;
        searchLng = 23.9575;
        searchLocationLabel = 'KTU Campus, Kaunas';
      }
    }
    if (json['ability_level'] != null) abilityLevel = json['ability_level'].toString();
    if (json['karma_score'] != null) {
      karmaScore = int.tryParse(json['karma_score'].toString()) ?? karmaScore;
    }
    if (json['favorite_sports'] is List) {
      favoriteSports = (json['favorite_sports'] as List)
          .map((e) => e.toString())
          .toList();
    }
  }
}

class RosterPlayer {
  final int idUser;
  final String name;
  final String username;
  final String role;
  final int karma;
  final String level;
  final String bio;
  final String city;
  final List<String> favoriteSports;

  const RosterPlayer({
    required this.idUser,
    required this.name,
    required this.username,
    required this.role,
    required this.karma,
    required this.level,
    this.bio = '',
    this.city = 'Kaunas',
    this.favoriteSports = const [],
  });

  factory RosterPlayer.fromJson(Map<String, dynamic> json) {
    final String favRaw = (json['favorite_sports'] ?? '').toString();
    final List<String> favs = favRaw.isEmpty
        ? []
        : favRaw.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

    return RosterPlayer(
      idUser: int.tryParse((json['id_user'] ?? '0').toString()) ?? 0,
      name: (json['name'] ?? 'Player').toString(),
      username: (json['username'] ?? 'player').toString(),
      role: (json['role'] ?? 'Player').toString(),
      karma: int.tryParse((json['karma'] ?? '100').toString()) ?? 100,
      level: (json['level'] ?? 'Intermediate').toString(),
      bio: (json['bio'] ?? 'Sport enthusiast ready to play!').toString(),
      city: (json['city'] ?? 'Kaunas').toString(),
      favoriteSports: favs,
    );
  }
}

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
  final int organizerId;
  final String sport;
  final String category;
  final String format;
  final String title;
  final String venue;
  final double latitude;
  final double longitude;
  final String date;
  final String rawDate;
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
    required this.organizerId,
    required this.sport,
    required this.category,
    required this.format,
    required this.title,
    required this.venue,
    required this.latitude,
    required this.longitude,
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

  // Calcola la distanza in linea d'aria (in km) tra il punto scelto dall'utente e il campo della partita (Formula di Haversine)
  double distanceFromUserKm() {
    return calculateDistanceKm(
      UserSession.searchLat,
      UserSession.searchLng,
      latitude,
      longitude,
    );
  }

  static double calculateDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final double dLat = _degToRad(lat2 - lat1);
    final double dLon = _degToRad(lon2 - lon1);
    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

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
    final double lat = double.tryParse((json['venue_lat'] ?? '54.9027').toString()) ?? 54.9027;
    final double lng = double.tryParse((json['venue_lng'] ?? '23.9575').toString()) ?? 23.9575;

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
      organizerId: _parseInt(json['id_organizer'], defaultValue: 1),
      sport: sportName,
      category: sportCategory,
      format: sportFormat,
      title: matchTitle,
      venue: venueName,
      latitude: lat,
      longitude: lng,
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