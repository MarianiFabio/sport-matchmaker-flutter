import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  // Mappa degli sport con il relativo numero di giocatori totali di default
  static const Map<String, int> _sportCapacities = {
    'Football 5v5': 10,
    'Football 7v7': 14,
    'Football 8v8': 16,
    'Basketball 3v3': 6,
    'Basketball 5v5': 10,
    'Padel 2v2': 4,
    'Tennis Singles 1v1': 2,
    'Tennis Doubles 2v2': 4,
    'Volleyball 6v6': 12,
    'Beach Volley 2v2': 4,
  };

  String _selectedSport = 'Football 5v5';
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _spotsController = TextEditingController();
  bool _isSubmitting = false;

  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  int get _currentTotalPlayers => _sportCapacities[_selectedSport] ?? 10;

  @override
  void dispose() {
    _descriptionController.dispose();
    _venueController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _spotsController.dispose();
    super.dispose();
  }

  Future<void> _publishMatch() async {
    setState(() => _isSubmitting = true);

    final String venue = _venueController.text.trim().isNotEmpty
        ? _venueController.text.trim()
        : 'KTU Sports Center, Radvilėnų pl. 19';
    final String date = _dateController.text.trim().isNotEmpty
        ? _dateController.text.trim()
        : '15/11/2026';
    final String time = _timeController.text.trim().isNotEmpty
        ? _timeController.text.trim()
        : '20:00';
    final String spots = _spotsController.text.trim().isNotEmpty
        ? _spotsController.text.trim()
        : '2';

    try {
      final url = Uri.parse('$_apiUrl?action=create_match');
      await http.post(
        url,
        body: {
          'sport_name': _selectedSport,
          'venue_name': venue,
          'match_date': date,
          'match_time': time,
          'spots_needed': spots,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$_selectedSport match published ($_currentTotalPlayers total slots)!'),
        ),
      );

      _descriptionController.clear();
      _venueController.clear();
      _dateController.clear();
      _timeController.clear();
      _spotsController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish match: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tendina con tutte le varianti di sport e capienza automatica
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Sport & Format',
                helperText: 'Default match capacity: $_currentTotalPlayers total players',
                border: const OutlineInputBorder(),
              ),
              value: _selectedSport,
              items: _sportCapacities.keys
                  .map((sport) => DropdownMenuItem(
                value: sport,
                child: Text('$sport (${_sportCapacities[sport]} players)'),
              ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSport = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Match Description / Urgency Note',
                hintText: 'e.g., Need 2 players for 8 PM friendly match',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue Address',
                hintText: 'e.g., KTU Arena, Radvilėnų pl. 19',
                prefixIcon: Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Kickoff Time',
                      hintText: 'HH:MM',
                      prefixIcon: Icon(Icons.access_time),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _spotsController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Missing Players Needed (out of $_currentTotalPlayers)',
                hintText: 'e.g., 2',
                prefixIcon: const Icon(Icons.group_add_outlined),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isSubmitting ? null : _publishMatch,
                child: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Publish Match', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}