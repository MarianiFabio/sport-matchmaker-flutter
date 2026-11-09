import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/match_item.dart';

class MatchDetailScreen extends StatefulWidget {
  final MatchItem match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  bool _isJoining = false;
  bool _hasJoined = false;

  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  // Invia la richiesta di partecipazione al backend XAMPP
  Future<void> _joinMatch() async {
    setState(() => _isJoining = true);

    try {
      final url = Uri.parse(
        '$_apiUrl?action=join_match&id_match=${widget.match.id ?? 0}',
      );
      await http.post(url);
    } catch (e) {
      // Anche se XAMPP avesse un intoppo, aggiorniamo comunque la UI per la demo
      debugPrint('Join request fallback: $e');
    }

    if (!mounted) return;

    setState(() {
      _isJoining = false;
      _hasJoined = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have joined the match! Roster updated.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

    return Scaffold(
      appBar: AppBar(title: Text(match.sport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              match.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(match.venue, style: const TextStyle(fontSize: 14))),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_month_outlined, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(match.time, style: const TextStyle(fontSize: 14)),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Confirmed Roster',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Lista giocatori confermati + slot libero che si aggiorna al click
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  ListTile(
                    leading: CircleAvatar(
                      child: Text(
                        (match.organizerName != null && match.organizerName!.isNotEmpty)
                            ? match.organizerName!.substring(0, 1).toUpperCase()
                            : 'FM',
                      ),
                    ),
                    title: Text('${match.organizerName ?? 'Fabio Mariani'} (Organizer)'),
                    subtitle: const Text('Reliability: 100%'),
                    trailing: const Chip(label: Text('Host'), visualDensity: VisualDensity.compact),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: CircleAvatar(child: Text('AP')),
                    title: Text('Andrea'),
                    subtitle: Text('Reliability: 95%'),
                  ),
                  const Divider(height: 1),
                  if (_hasJoined)
                    const ListTile(
                      leading: CircleAvatar(child: Text('LB')),
                      title: Text('Luca Bianchi (You)', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Reliability: 100% • Just joined'),
                      trailing: Icon(Icons.check_circle, color: Colors.green),
                    )
                  else
                    const ListTile(
                      leading: CircleAvatar(child: Icon(Icons.person_add_alt_1, color: Colors.grey)),
                      title: Text('Empty Spot', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                      subtitle: Text('Waiting for player'),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: _isJoining
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : Icon(_hasJoined ? Icons.check : Icons.check_circle_outline),
                label: Text(
                  _hasJoined ? 'Joined' : 'Join This Game',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: (_isJoining || _hasJoined) ? null : _joinMatch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}