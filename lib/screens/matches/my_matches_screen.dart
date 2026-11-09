import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MyMatchesScreen extends StatefulWidget {
  const MyMatchesScreen({super.key});

  @override
  State<MyMatchesScreen> createState() => _MyMatchesScreenState();
}

class _MyMatchesScreenState extends State<MyMatchesScreen> {
  List<dynamic> _joinedMatches = [];
  List<dynamic> _organizedMatches = [];
  bool _isLoading = true;
  String? _errorMessage;

  // String get _apiUrl {
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2/sportmatch/api.php';
  //   }
  //   return 'http://localhost/sportmatch/api.php';
  // }

  String get _apiUrl {
    // URL pubblico così funziona sia sul mio PC che su quello del professore!
    return 'http://sportmatch-fabio.atwebpages.com/api.php';
  }

  @override
  void initState() {
    super.initState();
    _loadMyMatches();
  }

  // Scarica le partite Joined e Organized dal JSON del server
  Future<void> _loadMyMatches() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('$_apiUrl?action=get_my_matches&id_user=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final joinedList = (decoded['joined'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();
        final organizedList = (decoded['organized'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        if (mounted) {
          setState(() {
            _joinedMatches = joinedList;
            _organizedMatches = organizedList;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Abbandona una partita a cui si era iscritti
  Future<void> _leaveMatch(int matchId) async {
    try {
      await http.post(
        Uri.parse('$_apiUrl?action=leave_match&id_match=$matchId&id_user=1'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You left the match. Spot released!')),
      );
      _loadMyMatches();
    } catch (e) {
      debugPrint('Error leaving match: $e');
    }
  }

  // Cancella una partita organizzata dall'utente
  Future<void> _deleteOrganizedMatch(int matchId) async {
    try {
      await http.post(
        Uri.parse('$_apiUrl?action=delete_match&id_match=$matchId'),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Match cancelled and removed from database.')),
      );
      _loadMyMatches();
    } catch (e) {
      debugPrint('Error deleting match: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Matches', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh My Matches',
              onPressed: _loadMyMatches,
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.check_circle_outline),
                text: 'Joined (${_joinedMatches.length})',
              ),
              Tab(
                icon: const Icon(Icons.sports),
                text: 'Organized (${_organizedMatches.length})',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your matches from server.'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _loadMyMatches,
                child: const Text('Retry'),
              ),
            ],
          ),
        )
            : TabBarView(
          children: [
            // Tab 1: Partite a cui sono iscritto (lette dal DB)
            _joinedMatches.isEmpty
                ? const Center(
              child: Text('You have not joined any matches yet.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _joinedMatches.length,
              itemBuilder: (context, index) {
                final m = _joinedMatches[index];
                final int idMatch =
                    int.tryParse((m['id_match'] ?? '0').toString()) ?? 0;
                final String sportTag =
                    '${m['sport_category'] ?? 'Sport'} • ${m['sport_format'] ?? ''}';
                final String reqStatus =
                (m['request_status'] ?? 'ACCEPTED').toString();

                return _buildMatchCard(
                  title: (m['title'] ?? 'Sport Match').toString(),
                  sport: sportTag,
                  date: '${m['match_date'] ?? ''}, ${m['match_time'] ?? ''}',
                  location: (m['venue_name'] ?? 'Sports Center').toString(),
                  status: reqStatus == 'ACCEPTED'
                      ? 'Spot Confirmed'
                      : 'Waiting Approval',
                  statusColor:
                  reqStatus == 'ACCEPTED' ? Colors.green : Colors.orange,
                  isHost: false,
                  onActionPressed: () => _leaveMatch(idMatch),
                );
              },
            ),

            // Tab 2: Partite organizzate da me (lette dal DB)
            _organizedMatches.isEmpty
                ? const Center(
              child: Text('You have not organized any matches yet.'),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _organizedMatches.length,
              itemBuilder: (context, index) {
                final m = _organizedMatches[index];
                final int idMatch =
                    int.tryParse((m['id_match'] ?? '0').toString()) ?? 0;
                final int needed =
                    int.tryParse((m['spots_needed'] ?? '0').toString()) ?? 0;
                final int total =
                    int.tryParse((m['total_spots'] ?? '10').toString()) ?? 10;
                final String sportTag =
                    '${m['sport_category'] ?? 'Sport'} • ${m['sport_format'] ?? ''}';

                return _buildMatchCard(
                  title: (m['title'] ?? 'Sport Match').toString(),
                  sport: sportTag,
                  date: '${m['match_date'] ?? ''}, ${m['match_time'] ?? ''}',
                  location: (m['venue_name'] ?? 'Sports Center').toString(),
                  status:
                  'Host • ${total - needed}/$total Players ($needed left)',
                  statusColor: Colors.teal,
                  isHost: true,
                  onActionPressed: () => _deleteOrganizedMatch(idMatch),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard({
    required String title,
    required String sport,
    required String date,
    required String location,
    required String status,
    required Color statusColor,
    required VoidCallback onActionPressed,
    bool isHost = false,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(sport),
                  visualDensity: VisualDensity.compact,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(location, style: const TextStyle(color: Colors.grey))),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHost)
                  OutlinedButton.icon(
                    onPressed: onActionPressed,
                    icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    label: const Text('Cancel Match', style: TextStyle(color: Colors.red)),
                  )
                else
                  OutlinedButton.icon(
                    onPressed: onActionPressed,
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: const Text('Leave Match'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}