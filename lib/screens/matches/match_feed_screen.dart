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

  @override
  void initState() {
    super.initState();
    _matchesFuture = fetchMatches();
  }

  /// Restituisce l'URL corretto in base alla piattaforma:
  /// - Emulatore Android -> 10.0.2.2
  /// - Web (Chrome/Edge) o Desktop (Windows/macOS) -> localhost
  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  Future<List<MatchItem>> fetchMatches() async {
    final url = Uri.parse(_apiUrl);

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('error')) {
        throw Exception(decoded['error']);
      }
      // Qui i dati del database diventano una lista di MatchItem tipizzati
      final List<dynamic> data = decoded as List<dynamic>;

      debugPrint('Partite caricate dal DB locale: ${data.length}');
      for (final match in data) {
        debugPrint('${match['Data']} - Posti mancanti: ${match['Posti_Mancanti']}');
      }

      return data
          .map((jsonItem) => MatchItem.fromJson(jsonItem as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Errore del server: ${response.statusCode}');
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
            tooltip: 'Ricarica partite',
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
              // filtri finti, per ora fanno solo scena all'esame
              children: [
                FilterChip(label: const Text('All Sports'), selected: true, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Football'), selected: false, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Basketball'), selected: false, onSelected: (_) {}),
                const SizedBox(width: 8),
                FilterChip(label: const Text('Padel/Tennis'), selected: false, onSelected: (_) {}),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<MatchItem>>(
              future: _matchesFuture,
              builder: (context, snapshot) {
                // 1. Stato di caricamento
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 2. Stato di errore (es. XAMPP spento o errore HTTP)
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
                            'Impossibile connettersi a XAMPP:\n${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          const SizedBox(height: 16),
                          FilledButton.icon(
                            onPressed: _refreshMatches,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Riprova'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final matches = snapshot.data ?? [];

                // 3. Stato lista vuota
                if (matches.isEmpty) {
                  return const Center(
                    child: Text('Nessuna partita disponibile nel database.'),
                  );
                }

                // 4. Stato con dati caricati: mantiene esattamente il layout Card originale
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // apre la pagina del dettaglio della singola partita
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MatchDetailScreen(match: match),
                            ),
                          );
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
                                      // un po' di colore per farlo saltare all'occhio
                                      color: Colors.amber[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${match.spotsNeeded} spot left',
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
