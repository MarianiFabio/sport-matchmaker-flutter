import 'package:flutter/material.dart';

class CreateMatchScreen extends StatelessWidget {
  const CreateMatchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // tendina per scegliere lo sport
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Select Sport', border: OutlineInputBorder()),
              value: 'Football 5v5',
              items: const [
                DropdownMenuItem(value: 'Football 5v5', child: Text('Football 5v5')),
                DropdownMenuItem(value: 'Basketball 3v3', child: Text('Basketball 3v3')),
                DropdownMenuItem(value: 'Padel / Tennis', child: Text('Padel / Tennis')),
                DropdownMenuItem(value: 'Volleyball', child: Text('Volleyball')),
              ],
              onChanged: (_) {},
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Match Description / Urgency Note',
                hintText: 'e.g., Need 2 players for 8 PM friendly match',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Venue Address',
                hintText: 'e.g., KTU Arena, Radvilėnų pl. 19',
                prefixIcon: Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
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
            const TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Missing Players Needed',
                hintText: 'e.g., 2',
                prefixIcon: Icon(Icons.group_add_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  // finto invio del form
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Match published to the feed!')),
                  );
                },
                child: const Text('Publish Match', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
