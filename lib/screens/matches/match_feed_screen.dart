import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/match_item.dart';
import 'match_detail_screen.dart';

class MatchFeedScreen extends StatefulWidget {
  const MatchFeedScreen({super.key});

  @override
  State<MatchFeedScreen> createState() => _MatchFeedScreenState();
}

class _MatchFeedScreenState extends State<MatchFeedScreen> {
  late Future<List<MatchItem>> _matchesFuture;
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _matchesFuture = fetchMatches();
  }

  // Seleziona automaticamente l'indirizzo IP corretto per emulatore Android o Web/Desktop
  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  Future<List<MatchItem>> fetchMatches() async {
    final url = Uri.parse('$_apiUrl?action=get_matches');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('error')) {
        throw Exception(decoded['error']);
      }

      final List<dynamic> data = decoded as List<dynamic>;
      debugPrint('Loaded matches from local DB: ${data.length}');

      return data
          .map((jsonItem) => MatchItem.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  void _refreshMatches() {
    setState(() {
      _matchesFuture = fetchMatches();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh matches',
            onPressed: _refreshMatches,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              // Filtri basati sul tag Sport_Category
              children: [
                FilterChip(
                  label: const Text('All Sports'),
                  selected: _selectedFilter == 'All',
                  onSelected: (_) => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Football'),
                  selected: _selectedFilter == 'Football',
                  onSelected: (_) => setState(() => _selectedFilter = 'Football'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Basketball'),
                  selected: _selectedFilter == 'Basketball',
                  onSelected: (_) => setState(() => _selectedFilter = 'Basketball'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Padel / Tennis'),
                  selected: _selectedFilter == 'Racket',
                  onSelected: (_) => setState(() => _selectedFilter = 'Racket'),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Volleyball'),
                  selected: _selectedFilter == 'Volleyball',
                  onSelected: (_) => setState(() => _selectedFilter = 'Volleyball'),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MatchItem>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 12),
                          Text(
                            'Unable to connect to local server:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _refreshMatches,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final allMatches = snapshot.data ?? [];
                final matches = _selectedFilter == 'All'
                    ? allMatches
                    : allMatches
                    .where((m) => m.category.toLowerCase() == _selectedFilter.toLowerCase())
                    .toList();

                if (matches.isEmpty) {
                  return const Center(
                    child: Text('No matches available for this category.'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          // Apre il dettaglio e, al ritorno, aggiorna la lista dal DB
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchDetailScreen(match: match),
                            ),
                          );
                          _refreshMatches();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(match.icon, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(match.sport, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        Text(match.venue, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${match.spotsNeeded} spot${match.spotsNeeded == 1 ? '' : 's'} left',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[900], fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.schedule, size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(match.time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                    ],
                                  ),
                                  Text(
                                    '${match.totalSpots - match.spotsNeeded}/${match.totalSpots} Players',
                                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}