import 'package:flutter/material.dart';
import '../models/match_item.dart';

class MatchDetailScreen extends StatelessWidget {
  final MatchItem match;
  const MatchDetailScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(match.sport)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(match.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
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
            Text('Confirmed Roster', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Card(
              child: ListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  ListTile(
                    leading: CircleAvatar(child: Text('FM')),
                    title: Text('Fabio (Organizer)'),
                    subtitle: Text('Reliability: 100%'),
                    trailing: Chip(label: Text('Host'), visualDensity: VisualDensity.compact),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(child: Text('AP')),
                    title: Text('Andrius'),
                    subtitle: Text('Reliability: 95%'),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: CircleAvatar(child: Icon(Icons.person_add_alt_1, color: Colors.grey)),
                    title: Text('Empty Spot', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                    subtitle: Text('Waiting for request'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Join This Game', style: TextStyle(fontSize: 16)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Request sent to organizer!')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
