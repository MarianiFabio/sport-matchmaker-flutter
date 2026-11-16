import 'dart:convert';
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

  // Di default parte filtrando automaticamente sugli Sport Preferiti dell'utente loggato!
  String _selectedCategory = 'Favorites';
  String _selectedFormat = 'All';
  String _searchQuery = '';
  DateTime? _selectedDate;
  String _selectedTimeSlot = 'Any';
  bool _onlyFreeMatches = false;

  final List<String> _sportCategories = const [
    'Favorites',
    'All',
    'Football',
    'Basketball',
    'Padel',
    'Tennis',
    'Volleyball',
    'Badminton',
    'Table Tennis',
    'Rugby',
  ];

  @override
  void initState() {
    super.initState();
    _matchesFuture = fetchMatches();
  }

  Future<List<MatchItem>> fetchMatches() async {
    final url = Uri.parse('${UserSession.apiUrl}?action=get_matches');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      if (decoded is Map && decoded.containsKey('error')) {
        throw Exception(decoded['error']);
      }

      final List<dynamic> data = decoded as List<dynamic>;
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

  void _resetAllFilters() {
    setState(() {
      _selectedCategory = 'All';
      _selectedFormat = 'All';
      _searchQuery = '';
      _selectedDate = null;
      _selectedTimeSlot = 'Any';
      _onlyFreeMatches = false;
    });
  }

  Future<void> _pickFilterDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2026, 11, 18),
      firstDate: DateTime(2025),
      lastDate: DateTime(2028),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _openAdvancedFiltersSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Advanced Filters',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () {
                          _resetAllFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Time of Day', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Any', 'Morning', 'Afternoon', 'Evening'].map((slot) {
                      return ChoiceChip(
                        label: Text(slot),
                        selected: _selectedTimeSlot == slot,
                        onSelected: (_) {
                          setModalState(() => _selectedTimeSlot = slot);
                          setState(() => _selectedTimeSlot = slot);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Free Matches Only (€0.00)'),
                    value: _onlyFreeMatches,
                    onChanged: (val) {
                      setModalState(() => _onlyFreeMatches = val);
                      setState(() => _onlyFreeMatches = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<MatchItem> _applyFilters(List<MatchItem> allMatches) {
    final favLower = UserSession.favoriteSports.map((s) => s.toLowerCase()).toSet();

    return allMatches.where((m) {
      // 1. Filtro Sport Preferiti (attivo di default!) oppure Sport specifico
      if (_selectedCategory == 'Favorites') {
        if (favLower.isNotEmpty && !favLower.contains(m.category.toLowerCase())) {
          return false;
        }
      } else if (_selectedCategory != 'All' &&
          m.category.toLowerCase() != _selectedCategory.toLowerCase()) {
        return false;
      }

      // 2. Filtro Formato
      if (_selectedFormat != 'All' &&
          m.format.toLowerCase() != _selectedFormat.toLowerCase()) {
        return false;
      }

      // 3. Filtro Ricerca Testuale
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesText = m.title.toLowerCase().contains(q) ||
            m.venue.toLowerCase().contains(q) ||
            m.sport.toLowerCase().contains(q) ||
            (m.organizerName?.toLowerCase().contains(q) ?? false);
        if (!matchesText) return false;
      }

      // 4. Filtro Data
      if (_selectedDate != null) {
        final y = _selectedDate!.year.toString();
        final mo = _selectedDate!.month.toString().padLeft(2, '0');
        final d = _selectedDate!.day.toString().padLeft(2, '0');
        final targetIso = '$y-$mo-$d';
        final targetEu = '$d/$mo/$y';
        if (m.rawDate != targetIso && m.date != targetEu) {
          return false;
        }
      }

      // 5. Filtro Fascia Oraria
      if (_selectedTimeSlot != 'Any' && m.kickOffTime.contains(':')) {
        final hour = int.tryParse(m.kickOffTime.split(':').first) ?? 20;
        if (_selectedTimeSlot == 'Morning' && hour >= 12) return false;
        if (_selectedTimeSlot == 'Afternoon' && (hour < 12 || hour >= 18)) return false;
        if (_selectedTimeSlot == 'Evening' && hour < 18) return false;
      }

      // 6. Filtro Partite Gratuite
      if (_onlyFreeMatches && m.feePerPerson > 0) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Available Matches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(
              'Logged in as ${UserSession.fullName}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Filter by Date',
            onPressed: _pickFilterDate,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh matches',
            onPressed: _refreshMatches,
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Advanced Filters',
            onPressed: _openAdvancedFiltersSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search by venue, title, sport or host...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _searchQuery = ''),
                )
                    : null,
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          // Riga 1: Chip di filtro con "My Favorites" al primo posto
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: _sportCategories.map((category) {
                final String label = category == 'Favorites'
                    ? 'My Favorites'
                    : (category == 'All' ? 'All Sports' : category);
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(label),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                        _selectedFormat = 'All';
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),

          if (_selectedDate != null || _selectedTimeSlot != 'Any' || _onlyFreeMatches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_selectedDate != null)
                    InputChip(
                      label: Text(
                        'Date: ${_selectedDate!.day.toString().padLeft(2, '0')}/${_selectedDate!.month.toString().padLeft(2, '0')}/${_selectedDate!.year}',
                      ),
                      onDeleted: () => setState(() => _selectedDate = null),
                    ),
                  if (_selectedTimeSlot != 'Any')
                    InputChip(
                      label: Text('Time: $_selectedTimeSlot'),
                      onDeleted: () => setState(() => _selectedTimeSlot = 'Any'),
                    ),
                  if (_onlyFreeMatches)
                    InputChip(
                      label: const Text('Free Only'),
                      onDeleted: () => setState(() => _onlyFreeMatches = false),
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

                final availableFormats = (_selectedCategory == 'All' || _selectedCategory == 'Favorites')
                    ? <String>[]
                    : allMatches
                    .where((m) => m.category.toLowerCase() == _selectedCategory.toLowerCase())
                    .map((m) => m.format)
                    .where((f) => f.isNotEmpty)
                    .toSet()
                    .toList();

                final matches = _applyFilters(allMatches);

                return Column(
                  children: [
                    if (availableFormats.length > 1)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        child: Row(
                          children: [
                            const Text('Format: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('All Formats'),
                              selected: _selectedFormat == 'All',
                              onSelected: (_) => setState(() => _selectedFormat = 'All'),
                            ),
                            const SizedBox(width: 6),
                            ...availableFormats.map((fmt) => Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(fmt),
                                selected: _selectedFormat == fmt,
                                onSelected: (_) => setState(() => _selectedFormat = fmt),
                              ),
                            )),
                          ],
                        ),
                      ),

                    Expanded(
                      child: matches.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('No matches found for the selected filter.'),
                            const SizedBox(height: 8),
                            FilledButton.tonal(
                              onPressed: _resetAllFilters,
                              child: const Text('Show All Sports'),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
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
                                              Text(
                                                '${match.category} • ${match.format}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              ),
                                              Text(
                                                match.title,
                                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                              ),
                                              Text(
                                                '${match.venue} • Host: ${match.organizerName ?? "Organizer"}',
                                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                              ),
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
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.amber[900],
                                              fontSize: 12,
                                            ),
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
                                            Text(
                                              match.time,
                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '${match.roster.length}/${match.totalSpots} Joined • ${match.feePerPerson == 0 ? 'Free' : '€${match.feePerPerson.toStringAsFixed(2)}'}',
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}