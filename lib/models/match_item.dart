import 'package:flutter/material.dart';

// classe per i dati delle partite, niente roba complessa
// cosi mi basta passare sto oggetto tra le varie view
class MatchItem {
  final String sport;
  final String title;
  final String venue;
  final String time;
  final int spotsNeeded;
  final int totalSpots;
  final IconData icon;

  const MatchItem({
    required this.sport,
    required this.title,
    required this.venue,
    required this.time,
    required this.spotsNeeded,
    required this.totalSpots,
    required this.icon,
  });
}
