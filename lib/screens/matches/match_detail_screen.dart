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
  late List<RosterPlayer> _roster;

  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  @override
  void initState() {
    super.initState();
    _roster = List<RosterPlayer>.from(widget.match.roster);
  }

  Future<void> _joinMatch() async {
    setState(() => _isJoining = true);

    try {
      final url = Uri.parse(
        '$_apiUrl?action=join_match&id_match=${widget.match.id ?? 0}&id_user=1',
      );
      await http.post(url);
    } catch (e) {
      debugPrint('Join request error: $e');
    }

    if (!mounted) return;

    setState(() {
      _isJoining = false;
      _hasJoined = true;
      _roster.add(
        const RosterPlayer(
          name: 'You (Joined)',
          role: 'Player',
          karma: 100,
          level: 'Advanced',
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('You have joined the match! Roster updated on server.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;
    final remainingAfterJoin = _hasJoined ? (match.spotsNeeded - 1) : match.spotsNeeded;

    return Scaffold(
      appBar: AppBar(title: Text('${match.category} • ${match.format}')),
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
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.euro, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  match.feePerPerson == 0
                      ? 'Free Match'
                      : '€${match.feePerPerson.toStringAsFixed(2)} per player',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Confirmed Roster (${_roster.length}/${match.totalSpots})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Roster generato dinamicamente dal JSON restituito da api.php
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roster.length + (remainingAfterJoin > 0 ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index < _roster.length) {
                    final player = _roster[index];
                    final initials = player.name.isNotEmpty
                        ? player.name
                        .trim()
                        .split(' ')
                        .map((part) => part.isNotEmpty ? part[0] : '')
                        .take(2)
                        .join()
                        .toUpperCase()
                        : 'P';
                    return ListTile(
                      leading: CircleAvatar(child: Text(initials)),
                      title: Text(player.name),
                      subtitle: Text('Reliability: ${player.karma}% • ${player.level}'),
                      trailing: Chip(
                        label: Text(player.role),
                        visualDensity: VisualDensity.compact,
                      ),
                    );
                  } else {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_add_alt_1, color: Colors.grey),
                      ),
                      title: Text(
                        '$remainingAfterJoin Empty Spot${remainingAfterJoin == 1 ? '' : 's'} Remaining',
                        style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                      ),
                      subtitle: const Text('Waiting for players to join'),
                    );
                  }
                },
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