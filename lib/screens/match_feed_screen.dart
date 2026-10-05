import 'package:flutter/material.dart';
import '../models/match_item.dart';
import 'match_detail_screen.dart';

class MatchFeedScreen extends StatelessWidget {
  const MatchFeedScreen({super.key});

  final List<MatchItem> dummyMatches = const [
    MatchItem(
      sport: 'Football 5v5',
      title: 'Missing a goalkeeper!',
      venue: 'KTU Sports Arena, Court 2',
      time: 'Today, 19:30',
      spotsNeeded: 1,
      totalSpots: 10,
      icon: Icons.sports_soccer,
    ),
    MatchItem(
      sport: 'Basketball 3v3',
      title: 'Friendly outdoor match',
      venue: 'Santakos Park Courts',
      time: 'Tomorrow, 18:00',
      spotsNeeded: 2,
      totalSpots: 6,
      icon: Icons.sports_basketball,
    ),
    MatchItem(
      sport: 'Padel / Tennis',
      title: 'Intermediate doubles game',
      venue: 'Padel Club Kaunas',
      time: 'Thu 8 Oct, 20:00',
      spotsNeeded: 1,
      totalSpots: 4,
      icon: Icons.sports_tennis,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Available Matches', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
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
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: dummyMatches.length,
              itemBuilder: (context, index) {
                final match = dummyMatches[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
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
            ),
          ),
        ],
      ),
    );
  }
}
