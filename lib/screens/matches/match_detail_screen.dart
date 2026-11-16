import 'dart:convert';
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
  late List<RosterPlayer> _roster;
  late int _spotsNeeded;

  @override
  void initState() {
    super.initState();
    _roster = List<RosterPlayer>.from(widget.match.roster);
    _spotsNeeded = widget.match.spotsNeeded;
  }

  // Controlla se l'utente attualmente loggato fa già parte del roster (come Host o Player)
  bool get _isAlreadyInRoster =>
      _roster.any((p) => p.idUser == UserSession.currentUserId);

  Future<void> _joinMatch() async {
    if (_isAlreadyInRoster || _spotsNeeded <= 0) return;

    setState(() => _isJoining = true);

    try {
      final url = Uri.parse(
        '${UserSession.apiUrl}?action=join_match&id_match=${widget.match.id ?? 0}&id_user=${UserSession.currentUserId}',
      );
      final response = await http.post(url);
      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (decoded['success'] == true) {
        setState(() {
          _isJoining = false;
          _spotsNeeded = (_spotsNeeded - 1).clamp(0, widget.match.totalSpots);
          _roster.add(
            RosterPlayer(
              idUser: UserSession.currentUserId,
              name: UserSession.fullName,
              username: UserSession.username,
              role: 'Player',
              karma: UserSession.karmaScore,
              level: UserSession.abilityLevel,
              bio: 'Joined right now!',
              city: 'Kaunas',
              favoriteSports: UserSession.favoriteSports,
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Joined as ${UserSession.fullName}! Roster updated.')),
        );
      } else {
        setState(() => _isJoining = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((decoded['error'] ?? 'Could not join').toString())),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }

  // Mostra un popup con tutte le informazioni sul giocatore cliccato nel Roster
  void _showPlayerProfileSheet(RosterPlayer player) {
    final initials = player.name.isNotEmpty
        ? player.name
        .trim()
        .split(' ')
        .map((part) => part.isNotEmpty ? part[0] : '')
        .take(2)
        .join()
        .toUpperCase()
        : 'P';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  initials,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                player.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '@${player.username} • ${player.role}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 12),
              if (player.bio.isNotEmpty)
                Text(
                  player.bio,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[800]),
                ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  Chip(
                    avatar: const Icon(Icons.verified_outlined, size: 16, color: Colors.green),
                    label: Text('Karma: ${player.karma}%'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                    label: Text('Skill: ${player.level}'),
                  ),
                  Chip(
                    avatar: const Icon(Icons.location_city, size: 16),
                    label: Text(player.city),
                  ),
                ],
              ),
              if (player.favoriteSports.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Favorite Sports:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: player.favoriteSports
                      .map((s) => Chip(
                    label: Text(s, style: const TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final match = widget.match;

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Confirmed Roster (${_roster.length}/${match.totalSpots})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tap a player for info',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _roster.length + (_spotsNeeded > 0 ? 1 : 0),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  if (index < _roster.length) {
                    final player = _roster[index];
                    final isMe = player.idUser == UserSession.currentUserId;
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
                      onTap: () => _showPlayerProfileSheet(player),
                      leading: CircleAvatar(child: Text(initials)),
                      title: Text(
                        isMe ? '${player.name} (You)' : player.name,
                        style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal),
                      ),
                      subtitle: Text('Reliability: ${player.karma}% • ${player.level} • ${player.city}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(player.role),
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        ],
                      ),
                    );
                  } else {
                    return ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.person_add_alt_1, color: Colors.grey),
                      ),
                      title: Text(
                        '$_spotsNeeded Empty Spot${_spotsNeeded == 1 ? '' : 's'} Remaining',
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
                    : Icon(_isAlreadyInRoster ? Icons.check : Icons.check_circle_outline),
                label: Text(
                  _isAlreadyInRoster
                      ? (match.organizerId == UserSession.currentUserId
                      ? 'You are the Organizer (Host)'
                      : 'Already Joined (${UserSession.fullName})')
                      : 'Join This Game as ${UserSession.fullName}',
                  style: const TextStyle(fontSize: 16),
                ),
                onPressed: (_isJoining || _isAlreadyInRoster || _spotsNeeded <= 0) ? null : _joinMatch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}