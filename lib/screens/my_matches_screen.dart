import 'package:flutter/material.dart';

class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Matches'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.check_circle_outline), text: 'Joined (2)'),
              Tab(icon: Icon(Icons.sports), text: 'Organized (1)'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Partite a cui sono iscritto
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMatchCard(
                  title: 'Evening 5-a-side Football',
                  sport: 'Football',
                  date: 'Tomorrow, 20:30',
                  location: 'San Siro Sports Center',
                  status: 'Spot Confirmed',
                  statusColor: Colors.green,
                ),
                _buildMatchCard(
                  title: 'Mid-Level Doubles Padel',
                  sport: 'Padel',
                  date: 'Saturday, 18:00',
                  location: 'Padel Club Arena',
                  status: 'Waiting for players',
                  statusColor: Colors.orange,
                ),
              ],
            ),
            // Tab 2: Organizzate da me
            ListView(
              padding: const EdgeInsets.all(12),
              children: [
                _buildMatchCard(
                  title: '3v3 Playground Basketball',
                  sport: 'Basketball',
                  date: 'Sunday, 17:00',
                  location: 'North Park Playground',
                  status: 'You are the organizer',
                  statusColor: Colors.teal,
                  isHost: true,
                ),
              ],
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
                    color: statusColor.withOpacity(0.15),
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
                Text(location, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            if (isHost) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}