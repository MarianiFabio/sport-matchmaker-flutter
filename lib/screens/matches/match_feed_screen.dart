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


  String _sportFilterMode = 'FAV_ALL';
  Set<String> _customSelectedSports = {};
  String _selectedFormat = 'All';
  String _searchQuery = '';

  String _dateMode = 'UPCOMING';
  DateTime? _singleDate;
  DateTimeRange? _dateRange;

  String _timeMode = 'ANY';
  int _fromHour = 18;
  RangeValues _hourRange = const RangeValues(17, 22);

  // Filtro Geografico per Area e Raggio in linea d'aria (km)
  bool _enableAreaFilter = false;
  double _maxRadiusKm = 15.0;

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

  // Punti geografici e indirizzi predefiniti selezionabili o spostabili sulla mappa interattiva
  static const List _presetLocations = [
  {'label': 'KTU Campus, Kaunas', 'lat': 54.9027, 'lng': 23.9575, 'city': 'Kaunas'},
  {'label': 'Žalgiris Arena, Kaunas', 'lat': 54.8902, 'lng': 23.9145, 'city': 'Kaunas'},
  {'label': 'Old Town / Santaka, Kaunas', 'lat': 54.8969, 'lng': 23.8860, 'city': 'Kaunas'},
  {'label': 'San Siro Area, Milano', 'lat': 45.4781, 'lng': 9.1239, 'city': 'Milano'},
  {'label': 'Moscova / Center, Milano', 'lat': 45.4773, 'lng': 9.1895, 'city': 'Milano'},
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
      _enableAreaFilter = false;
      _maxRadiusKm = 15.0;
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

  void _openAdvancedFiltersSheet() {
    String sportSearchText = '';
    // Coordinate normalizzate del pin sulla mappa interattiva (0.0 .. 1.0)
    double mapPinX = 0.5;
    double mapPinY = 0.5;

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
              initialChildSize: 0.88,
              maxChildSize: 0.94,
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

                      // 1. SPORT MULTI-SELEZIONE CON RICERCA
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
                            label: const Text('All Sports'),
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

                      // 2. FILTRO GEOGRAFICO: MAPPA INTERATTIVA + SCELTA PUNTO + RAGGIO KM
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              '2. Nearby Area & Radius Filter (GPS / Map)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ),
                          Switch(
                            value: _enableAreaFilter,
                            onChanged: (val) {
                              setModalState(() => _enableAreaFilter = val);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                      Text(
                        'Reference Point: ${UserSession.searchLocationLabel} (${UserSession.searchLat.toStringAsFixed(3)}, ${UserSession.searchLng.toStringAsFixed(3)})',
                        style: TextStyle(fontSize: 12, color: Colors.teal[800], fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _presetLocations.map((loc) {
                          final isSelected = UserSession.searchLocationLabel == loc['label'];
                          return ChoiceChip(
                            avatar: const Icon(Icons.place_outlined, size: 15),
                            label: Text(loc['label'].toString(), style: const TextStyle(fontSize: 12)),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(() {
                                UserSession.searchLat = loc['lat'] as double;
                                UserSession.searchLng = loc['lng'] as double;
                                UserSession.searchLocationLabel = loc['label'].toString();
                                _enableAreaFilter = true;
                                mapPinX = 0.5;
                                mapPinY = 0.5;
                              });
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 10),

                      // Mappa Radar Interattiva (Tocca un punto qualsiasi per spostare il centro di ricerca!)
                      GestureDetector(
                        onTapDown: (details) {
                          const double mapWidth = 320;
                          const double mapHeight = 150;
                          final dx = (details.localPosition.dx / mapWidth).clamp(0.08, 0.92);
                          final dy = (details.localPosition.dy / mapHeight).clamp(0.12, 0.88);
                          setModalState(() {
                            mapPinX = dx;
                            mapPinY = dy;
                            // Sposta dinamicamente le coordinate intorno all'area selezionata (~15km box)
                            final baseLat = UserSession.searchLat;
                            final baseLng = UserSession.searchLng;
                            UserSession.searchLat = baseLat + (0.5 - dy) * 0.08;
                            UserSession.searchLng = baseLng + (dx - 0.5) * 0.12;
                            UserSession.searchLocationLabel =
                            'Custom Map Point (${UserSession.searchLat.toStringAsFixed(3)}, ${UserSession.searchLng.toStringAsFixed(3)})';
                            _enableAreaFilter = true;
                          });
                          setState(() {});
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F2EF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.teal.withValues(alpha: 0.4), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: CustomPaint(
                              painter: _RadarMapPainter(
                                pinX: mapPinX,
                                pinY: mapPinY,
                                radiusKm: _maxRadiusKm,
                                isEnabled: _enableAreaFilter,
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    top: 8,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.88),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Tap anywhere on map to move search center pin',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 8,
                                    right: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.teal[800],
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        _enableAreaFilter
                                            ? 'Radius: ${_maxRadiusKm.round()} km'
                                            : 'Filter Off (Tap to enable)',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_enableAreaFilter) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Text('Max Distance: ', style: TextStyle(fontSize: 13)),
                            Expanded(
                              child: Slider(
                                value: _maxRadiusKm,
                                min: 1,
                                max: 50,
                                divisions: 49,
                                label: '${_maxRadiusKm.round()} km',
                                onChanged: (val) {
                                  setModalState(() => _maxRadiusKm = val);
                                  setState(() {});
                                },
                              ),
                            ),
                            Text(
                              '${_maxRadiusKm.round()} km',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],

                      const Divider(height: 28),

                      // 3. DATA
                      const Text(
                        '3. Date Filter',
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

                      // 4. ORARIO
                      const Text(
                        '4. Kickoff Time Filter',
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
                          setState(() {});
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
      final catLower = m.category.toLowerCase();
      if (_sportFilterMode == 'FAV_ALL') {
        if (favLower.isNotEmpty && !favLower.contains(catLower)) return false;
      } else if (_sportFilterMode == 'CUSTOM') {
        if (customLower.isNotEmpty && !customLower.contains(catLower)) return false;
      }

      if (_selectedFormat != 'All' &&
          m.format.toLowerCase() != _selectedFormat.toLowerCase()) {
        return false;
      }

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchesText = m.title.toLowerCase().contains(q) ||
            m.venue.toLowerCase().contains(q) ||
            m.sport.toLowerCase().contains(q) ||
            (m.organizerName?.toLowerCase().contains(q) ?? false);
        if (!matchesText) return false;
      }

      // Filtro Distanza in linea d'aria (Haversine)
      if (_enableAreaFilter) {
        final distKm = m.distanceFromUserKm();
        if (distKm > _maxRadiusKm) return false;
      }

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

          // BARRA COMPATTA: [Favorite Sports, 1° Sport Preferito, 2°..., 📍 Area Map, + Other Sports]
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: const Text('Favorite Sports'),
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
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.radar, size: 16),
                    label: Text(
                      _enableAreaFilter
                          ? 'Within ${_maxRadiusKm.round()} km'
                          : 'Nearby Radar',
                    ),
                    selected: _enableAreaFilter,
                    onSelected: (val) {
                      if (!val) {
                        setState(() => _enableAreaFilter = false);
                      } else {
                        _openAdvancedFiltersSheet();
                      }
                    },
                  ),
                ),
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

          // Riepilogo filtri attivi
          if (_sportFilterMode == 'ALL' ||
              (_sportFilterMode == 'CUSTOM' && _customSelectedSports.isNotEmpty) ||
              _enableAreaFilter ||
              _dateMode != 'UPCOMING' ||
              _timeMode != 'ANY' ||
              _onlyFreeMatches)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_enableAreaFilter)
                    InputChip(
                      avatar: const Icon(Icons.my_location, size: 15),
                      label: Text('<= ${_maxRadiusKm.round()} km from ${UserSession.searchLocationLabel}'),
                      onDeleted: () => setState(() => _enableAreaFilter = false),
                    ),
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
                      const Text('No matches match your current filters or radius.'),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _sportFilterMode = 'ALL';
                            _customSelectedSports.clear();
                            _enableAreaFilter = false;
                            _dateMode = 'UPCOMING';
                            _timeMode = 'ANY';
                            _onlyFreeMatches = false;
                          });
                        },
                        child: const Text('Reset Filters & Show All Matches'),
                      ),
                    ],
                  ),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    final match = matches[index];
                    final distKm = match.distanceFromUserKm();
                    final distLabel = distKm < 100
                        ? '${distKm.toStringAsFixed(1)} km away'
                        : '${distKm.round()} km away';

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
                                          '📍 ${match.venue} ($distLabel)',
                                          style: TextStyle(color: Colors.grey[700], fontSize: 12),
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

// Disegna la Mappa Radar Interattiva con griglia stradale, pin dell'utente e cerchio del raggio in km
class _RadarMapPainter extends CustomPainter {
  final double pinX;
  final double pinY;
  final double radiusKm;
  final bool isEnabled;

  _RadarMapPainter({
    required this.pinX,
    required this.pinY,
    required this.radiusKm,
    required this.isEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.teal.withValues(alpha: 0.15)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fiume / Strade stilizzate per dare l'effetto mappa urbana
    final roadPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.35), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.7, size.height), roadPaint);

    final center = Offset(pinX * size.width, pinY * size.height);
    final visualRadius = (radiusKm / 50.0) * (size.height * 0.75) + 14;

    if (isEnabled) {
      final circleFill = Paint()
        ..color = Colors.teal.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      final circleBorder = Paint()
        ..color = Colors.teal[700]!
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, visualRadius, circleFill);
      canvas.drawCircle(center, visualRadius, circleBorder);
    }

    // Pin centrale
    final pinPaint = Paint()..color = Colors.red[700]!;
    canvas.drawCircle(center, 7, pinPaint);
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _RadarMapPainter oldDelegate) =>
      oldDelegate.pinX != pinX ||
          oldDelegate.pinY != pinY ||
          oldDelegate.radiusKm != radiusKm ||
          oldDelegate.isEnabled != isEnabled;
}