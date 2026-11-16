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

  // Modalità filtro sport:
  // 'FAV_ALL' = tutti i miei sport preferiti
  // 'ALL' = tutti gli sport dell'app
  // 'CUSTOM' = insieme personalizzato di sport scelti in _customSelectedSports
  String _sportFilterMode = 'FAV_ALL';
  Set<String> _customSelectedSports = {};
  String _selectedFormat = 'All';
  String _searchQuery = '';

  // Modalità filtro Data: 'UPCOMING' (da oggi in poi), 'SINGLE' (data singola), 'RANGE' (intervallo)
  String _dateMode = 'UPCOMING';
  DateTime? _singleDate;
  DateTimeRange? _dateRange;

  // Modalità filtro Ora: 'ANY' (qualsiasi), 'FROM' (da un'ora in poi), 'RANGE' (intervallo orario)
  String _timeMode = 'ANY';
  int _fromHour = 18;
  RangeValues _hourRange = const RangeValues(17, 22);

  bool _onlyFreeMatches = false;

  static const List<String> _allCatalogSports = [
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
      _sportFilterMode = 'FAV_ALL';
      _customSelectedSports.clear();
      _selectedFormat = 'All';
      _searchQuery = '';
      _dateMode = 'UPCOMING';
      _singleDate = null;
      _dateRange = null;
      _timeMode = 'ANY';
      _onlyFreeMatches = false;
    });
  }

  String _formatDateShort(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  DateTime? _parseRawDate(String raw) {
    try {
      if (raw.contains('-')) return DateTime.parse(raw);
      if (raw.contains('/')) {
        final p = raw.split('/');
        if (p.length == 3) {
          return DateTime(int.parse(p[2]), int.parse(p[1]), int.parse(p[0]));
        }
      }
    } catch (_) {}
    return null;
  }

  // PANNELLO FILTRI COMPLETO: Ricerca Sport Multipli, Date (Upcoming/Single/Range) e Orari (Any/From/Range)
  void _openAdvancedFiltersSheet() {
    String sportSearchText = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final favs = UserSession.favoriteSports;
            final otherSports = _allCatalogSports
                .where((s) =>
            !favs.contains(s) &&
                s.toLowerCase().contains(sportSearchText.toLowerCase()))
                .toList();
            final matchingFavs = favs
                .where((s) => s.toLowerCase().contains(sportSearchText.toLowerCase()))
                .toList();

            void toggleSportInFilter(String sport) {
              setModalState(() {
                if (_sportFilterMode != 'CUSTOM') {
                  _sportFilterMode = 'CUSTOM';
                  _customSelectedSports = {sport};
                } else {
                  if (_customSelectedSports.contains(sport)) {
                    _customSelectedSports.remove(sport);
                    if (_customSelectedSports.isEmpty) {
                      _sportFilterMode = 'FAV_ALL';
                    }
                  } else {
                    _customSelectedSports.add(sport);
                  }
                }
              });
              setState(() {});
            }

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              maxChildSize: 0.92,
              minChildSize: 0.5,
              builder: (_, scrollController) {
                return Padding(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: ListView(
                    controller: scrollController,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Search & Filters',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              _resetAllFilters();
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.restart_alt, size: 18),
                            label: const Text('Reset All'),
                          ),
                        ],
                      ),
                      const Divider(),

                      // SEZIONE 1: SPORT (Multi-selezione + Barra di ricerca + Preferiti in evidenza)
                      const SizedBox(height: 8),
                      const Text(
                        '1. Sports (Select one or multiple sports)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('⭐ All My Favorites'),
                            selected: _sportFilterMode == 'FAV_ALL',
                            onSelected: (_) {
                              setModalState(() {
                                _sportFilterMode = 'FAV_ALL';
                                _customSelectedSports.clear();
                              });
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: const Text('🌍 All Sports'),
                            selected: _sportFilterMode == 'ALL',
                            onSelected: (_) {
                              setModalState(() {
                                _sportFilterMode = 'ALL';
                                _customSelectedSports.clear();
                              });
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        onChanged: (val) => setModalState(() => sportSearchText = val),
                        decoration: InputDecoration(
                          hintText: 'Search sport (e.g., Volleyball, Tennis, Rugby...)',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (matchingFavs.isNotEmpty) ...[
                        Text(
                          'Your Favorite Sports (Tap to combine):',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: matchingFavs.map((sport) {
                            final isSelected =
                                _sportFilterMode == 'CUSTOM' && _customSelectedSports.contains(sport);
                            return FilterChip(
                              avatar: const Icon(Icons.star, size: 15, color: Colors.amber),
                              label: Text(sport),
                              selected: isSelected,
                              onSelected: (_) => toggleSportInFilter(sport),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                      ],
                      if (otherSports.isNotEmpty) ...[
                        Text(
                          'Other Sports:',
                          style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: otherSports.map((sport) {
                            final isSelected =
                                _sportFilterMode == 'CUSTOM' && _customSelectedSports.contains(sport);
                            return FilterChip(
                              label: Text(sport),
                              selected: isSelected,
                              onSelected: (_) => toggleSportInFilter(sport),
                            );
                          }).toList(),
                        ),
                      ],

                      const Divider(height: 28),

                      // SEZIONE 2: DATA (Da adesso in poi, Data Singola, Intervallo di Date)
                      const Text(
                        '2. Date Filter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any Upcoming'),
                            selected: _dateMode == 'UPCOMING',
                            onSelected: (_) {
                              setModalState(() => _dateMode = 'UPCOMING');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            avatar: const Icon(Icons.today, size: 16),
                            label: Text(
                              _dateMode == 'SINGLE' && _singleDate != null
                                  ? 'On: ${_formatDateShort(_singleDate!)}'
                                  : 'Single Date',
                            ),
                            selected: _dateMode == 'SINGLE',
                            onSelected: (_) async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _singleDate ?? DateTime(2026, 11, 18),
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2028),
                              );
                              if (picked != null) {
                                setModalState(() {
                                  _dateMode = 'SINGLE';
                                  _singleDate = picked;
                                });
                                setState(() {});
                              }
                            },
                          ),
                          ChoiceChip(
                            avatar: const Icon(Icons.date_range, size: 16),
                            label: Text(
                              _dateMode == 'RANGE' && _dateRange != null
                                  ? '${_formatDateShort(_dateRange!.start)} - ${_formatDateShort(_dateRange!.end)}'
                                  : 'Date Range',
                            ),
                            selected: _dateMode == 'RANGE',
                            onSelected: (_) async {
                              final pickedRange = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime(2025),
                                lastDate: DateTime(2028),
                                initialDateRange: _dateRange ??
                                    DateTimeRange(
                                      start: DateTime(2026, 11, 18),
                                      end: DateTime(2026, 11, 24),
                                    ),
                              );
                              if (pickedRange != null) {
                                setModalState(() {
                                  _dateMode = 'RANGE';
                                  _dateRange = pickedRange;
                                });
                                setState(() {});
                              }
                            },
                          ),
                        ],
                      ),

                      const Divider(height: 28),

                      // SEZIONE 3: ORARIO (Qualsiasi, Da un'ora in poi, Intervallo di ore)
                      const Text(
                        '3. Kickoff Time Filter',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Any Time'),
                            selected: _timeMode == 'ANY',
                            onSelected: (_) {
                              setModalState(() => _timeMode = 'ANY');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: Text('From ${_fromHour.toString().padLeft(2, "0")}:00 onwards'),
                            selected: _timeMode == 'FROM',
                            onSelected: (_) {
                              setModalState(() => _timeMode = 'FROM');
                              setState(() {});
                            },
                          ),
                          ChoiceChip(
                            label: Text(
                              'Between ${_hourRange.start.round().toString().padLeft(2, "0")}:00 - ${_hourRange.end.round().toString().padLeft(2, "0")}:00',
                            ),
                            selected: _timeMode == 'RANGE',
                            onSelected: (_) {
                              setModalState(() => _timeMode = 'RANGE');
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      if (_timeMode == 'FROM') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Start from: '),
                            Expanded(
                              child: Slider(
                                value: _fromHour.toDouble(),
                                min: 6,
                                max: 23,
                                divisions: 17,
                                label: '${_fromHour.toString().padLeft(2, "0")}:00',
                                onChanged: (val) {
                                  setModalState(() => _fromHour = val.round());
                                  setState(() {});
                                },
                              ),
                            ),
                            Text(
                              '${_fromHour.toString().padLeft(2, "0")}:00+',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                      if (_timeMode == 'RANGE') ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${_hourRange.start.round().toString().padLeft(2, "0")}:00'),
                            Expanded(
                              child: RangeSlider(
                                values: _hourRange,
                                min: 6,
                                max: 24,
                                divisions: 18,
                                labels: RangeLabels(
                                  '${_hourRange.start.round()}:00',
                                  '${_hourRange.end.round()}:00',
                                ),
                                onChanged: (values) {
                                  setModalState(() => _hourRange = values);
                                  setState(() {});
                                },
                              ),
                            ),
                            Text('${_hourRange.end.round().toString().padLeft(2, "0")}:00'),
                          ],
                        ),
                      ],

                      const Divider(height: 24),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Free Matches Only (€0.00)'),
                        value: _onlyFreeMatches,
                        onChanged: (val) {
                          setModalState(() => _onlyFreeMatches = val);
                          setState(() => _onlyFreeMatches = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          onPressed: () => Navigator.pop(context),
                          label: const Text('Show Filtered Matches'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  List<MatchItem> _applyFilters(List<MatchItem> allMatches) {
    final favLower = UserSession.favoriteSports.map((s) => s.toLowerCase()).toSet();
    final customLower = _customSelectedSports.map((s) => s.toLowerCase()).toSet();

    return allMatches.where((m) {
      // 1. Filtro Sport (Tutti i preferiti, Tutti gli sport, oppure Selezione Multipla Custom)
      final catLower = m.category.toLowerCase();
      if (_sportFilterMode == 'FAV_ALL') {
        if (favLower.isNotEmpty && !favLower.contains(catLower)) return false;
      } else if (_sportFilterMode == 'CUSTOM') {
        if (customLower.isNotEmpty && !customLower.contains(catLower)) return false;
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

      // 4. Filtro Data (Upcoming, Single Date, Date Range)
      final matchDateObj = _parseRawDate(m.rawDate.isNotEmpty ? m.rawDate : m.date);
      if (matchDateObj != null) {
        final dOnly = DateTime(matchDateObj.year, matchDateObj.month, matchDateObj.day);
        if (_dateMode == 'SINGLE' && _singleDate != null) {
          final target = DateTime(_singleDate!.year, _singleDate!.month, _singleDate!.day);
          if (dOnly != target) return false;
        } else if (_dateMode == 'RANGE' && _dateRange != null) {
          final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
          final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day);
          if (dOnly.isBefore(start) || dOnly.isAfter(end)) return false;
        }
      }

      // 5. Filtro Orario (Any, From Hour onwards, Hour Range)
      if (_timeMode != 'ANY' && m.kickOffTime.contains(':')) {
        final parts = m.kickOffTime.split(':');
        final hour = int.tryParse(parts[0]) ?? 20;
        final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
        final decimalTime = hour + (minute / 60.0);

        if (_timeMode == 'FROM' && decimalTime < _fromHour) {
          return false;
        } else if (_timeMode == 'RANGE') {
          if (decimalTime < _hourRange.start || decimalTime > _hourRange.end) {
            return false;
          }
        }
      }

      // 6. Solo Partite Gratuite
      if (_onlyFreeMatches && m.feePerPerson > 0) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final favSports = UserSession.favoriteSports;

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
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh matches',
            onPressed: _refreshMatches,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilledButton.tonalIcon(
              icon: const Icon(Icons.tune, size: 18),
              label: const Text('Filters'),
              onPressed: _openAdvancedFiltersSheet,
            ),
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

          // BARRA ORIZZONTALE COMPATTA: [⭐ Favorite Sports, 1° Sport Preferito, 2°, 3°..., + More Sports]
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                // 1. Bottone "All My Favorites"
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('⭐ Favorite Sports'),
                    selected: _sportFilterMode == 'FAV_ALL',
                    onSelected: (_) {
                      setState(() {
                        _sportFilterMode = 'FAV_ALL';
                        _customSelectedSports.clear();
                        _selectedFormat = 'All';
                      });
                    },
                  ),
                ),

                // 2. Singoli bottoni solo per i tuoi sport preferiti!
                ...favSports.map((favSport) {
                  final bool isSelectedSingle = _sportFilterMode == 'CUSTOM' &&
                      _customSelectedSports.contains(favSport);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(favSport),
                      selected: isSelectedSingle,
                      onSelected: (_) {
                        setState(() {
                          _sportFilterMode = 'CUSTOM';
                          // Se clicchi sulla barra rapida puoi attivare/combinare i tuoi sport preferiti
                          if (_customSelectedSports.contains(favSport)) {
                            _customSelectedSports.remove(favSport);
                            if (_customSelectedSports.isEmpty) {
                              _sportFilterMode = 'FAV_ALL';
                            }
                          } else {
                            _customSelectedSports.add(favSport);
                          }
                          _selectedFormat = 'All';
                        });
                      },
                    ),
                  );
                }),

                // 3. Chip rapido per cercare altri sport tramite il Pannello Filtri
                ActionChip(
                  avatar: const Icon(Icons.add_circle_outline, size: 18),
                  label: Text(
                    _sportFilterMode == 'ALL'
                        ? 'Showing: All Sports'
                        : 'Other Sports...',
                  ),
                  onPressed: _openAdvancedFiltersSheet,
                ),
              ],
            ),
          ),

          // Riepilogo filtri attivi (Sport extra, Data, Ora, Gratis)
          if (_sportFilterMode == 'ALL' ||
              (_sportFilterMode == 'CUSTOM' && _customSelectedSports.isNotEmpty) ||
              _dateMode != 'UPCOMING' ||
              _timeMode != 'ANY' ||
              _onlyFreeMatches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_sportFilterMode == 'ALL')
                    InputChip(
                      label: const Text('Sports: All'),
                      onDeleted: () => setState(() => _sportFilterMode = 'FAV_ALL'),
                    ),
                  if (_sportFilterMode == 'CUSTOM' && _customSelectedSports.isNotEmpty)
                    InputChip(
                      label: Text('Selected: ${_customSelectedSports.join(", ")}'),
                      onDeleted: () => setState(() {
                        _customSelectedSports.clear();
                        _sportFilterMode = 'FAV_ALL';
                      }),
                    ),
                  if (_dateMode == 'SINGLE' && _singleDate != null)
                    InputChip(
                      label: Text('Date: ${_formatDateShort(_singleDate!)}'),
                      onDeleted: () => setState(() => _dateMode = 'UPCOMING'),
                    ),
                  if (_dateMode == 'RANGE' && _dateRange != null)
                    InputChip(
                      label: Text(
                        'Dates: ${_formatDateShort(_dateRange!.start)} - ${_formatDateShort(_dateRange!.end)}',
                      ),
                      onDeleted: () => setState(() => _dateMode = 'UPCOMING'),
                    ),
                  if (_timeMode == 'FROM')
                    InputChip(
                      label: Text('Time: From $_fromHour:00'),
                      onDeleted: () => setState(() => _timeMode = 'ANY'),
                    ),
                  if (_timeMode == 'RANGE')
                    InputChip(
                      label: Text(
                        'Time: ${_hourRange.start.round()}:00 - ${_hourRange.end.round()}:00',
                      ),
                      onDeleted: () => setState(() => _timeMode = 'ANY'),
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
                final matches = _applyFilters(allMatches);

                return matches.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('No matches match your current filters.'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _sportFilterMode = 'ALL';
                            _customSelectedSports.clear();
                            _dateMode = 'UPCOMING';
                            _timeMode = 'ANY';
                            _onlyFreeMatches = false;
                          });
                        },
                        child: const Text('Show All Upcoming Matches'),
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
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}