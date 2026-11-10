import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/match_item.dart';

class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  List<SportFormatOption> _allSportOptions = [];
  bool _isLoadingSports = true;

  String? _selectedCategory;
  SportFormatOption? _selectedFormatOption;

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _venueController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  final TextEditingController _spotsController = TextEditingController();
  final TextEditingController _feeController = TextEditingController();
  bool _isSubmitting = false;

  String get _apiUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2/sportmatch/api.php';
    }
    return 'http://localhost/sportmatch/api.php';
  }

  // String get _apiUrl {
  //   // URL pubblico
  //   return 'http://sportmatch-fabio.atwebpages.com/api.php';
  // }

  @override
  void initState() {
    super.initState();
    _loadSportsFromServer();
  }

  // Carica dinamicamente Sport e Formati dal JSON sul server XAMPP
  Future<void> _loadSportsFromServer() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl?action=get_sports'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body) as List<dynamic>;
        final options = data
            .map((item) => SportFormatOption.fromJson(item as Map<String, dynamic>))
            .toList();

        if (mounted && options.isNotEmpty) {
          setState(() {
            _allSportOptions = options;
            _selectedCategory = options.first.category;
            _selectedFormatOption = options.first;
            _isLoadingSports = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading sports catalog: $e');
      if (mounted) setState(() => _isLoadingSports = false);
    }
  }

  // Lista unica degli sport (Category) ricavata dal JSON
  List<String> get _availableCategories =>
      _allSportOptions.map((e) => e.category).toSet().toList();

  // Lista dei formati disponibili per lo sport selezionato
  List<SportFormatOption> get _formatsForSelectedCategory => _allSportOptions
      .where((e) => e.category == _selectedCategory)
      .toList();

  int get _currentTotalPlayers => _selectedFormatOption?.defaultPlayers ?? 10;

  @override
  void dispose() {
    _descriptionController.dispose();
    _venueController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    _spotsController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      final day = picked.day.toString().padLeft(2, '0');
      final month = picked.month.toString().padLeft(2, '0');
      _dateController.text = '$day/$month/${picked.year}';
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 20, minute: 0),
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      _timeController.text = '$hour:$minute';
    }
  }

  Future<void> _publishMatch() async {
    if (_selectedFormatOption == null) return;
    setState(() => _isSubmitting = true);

    final String title = _descriptionController.text.trim();
    final String venue = _venueController.text.trim().isNotEmpty
        ? _venueController.text.trim()
        : 'KTU Sports Center, Radvilėnų pl. 19';
    final String date = _dateController.text.trim().isNotEmpty
        ? _dateController.text.trim()
        : '15/11/2026';
    final String time = _timeController.text.trim().isNotEmpty
        ? _timeController.text.trim()
        : '20:00';
    final String spots = _spotsController.text.trim().isNotEmpty
        ? _spotsController.text.trim()
        : '2';
    final String fee = _feeController.text.trim().isNotEmpty
        ? _feeController.text.trim()
        : '5.00';

    try {
      final url = Uri.parse('$_apiUrl?action=create_match');
      await http.post(
        url,
        body: {
          'id_sport': _selectedFormatOption!.idSport.toString(),
          'sport_category': _selectedFormatOption!.category,
          'sport_format': _selectedFormatOption!.format,
          'title': title,
          'venue_name': venue,
          'match_date': date,
          'match_time': time,
          'spots_needed': spots,
          'fee_per_person': fee,
        },
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_selectedFormatOption!.sportName} published ($_currentTotalPlayers total slots)!',
          ),
        ),
      );

      _descriptionController.clear();
      _venueController.clear();
      _dateController.clear();
      _timeController.clear();
      _spotsController.clear();
      _feeController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to publish match: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Match', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoadingSports
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PRIMA TENDINA: Selezione dello Sport (Category)
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Select Sport',
                prefixIcon: Icon(Icons.sports_soccer),
                border: OutlineInputBorder(),
              ),
              value: _selectedCategory,
              items: _availableCategories
                  .map((cat) => DropdownMenuItem(
                value: cat,
                child: Text(cat),
              ))
                  .toList(),
              onChanged: (newCategory) {
                if (newCategory != null) {
                  setState(() {
                    _selectedCategory = newCategory;
                    _selectedFormatOption = _formatsForSelectedCategory.first;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 2. SECONDA TENDINA SEPARATA: Selezione del Formato (5v5, 7v7, 3v3...)
            DropdownButtonFormField<SportFormatOption>(
              decoration: InputDecoration(
                labelText: 'Select Format',
                prefixIcon: const Icon(Icons.people_alt_outlined),
                helperText: 'Standard match capacity: $_currentTotalPlayers total players',
                border: const OutlineInputBorder(),
              ),
              value: _selectedFormatOption,
              items: _formatsForSelectedCategory
                  .map((opt) => DropdownMenuItem(
                value: opt,
                child: Text('${opt.format} (${opt.defaultPlayers} players)'),
              ))
                  .toList(),
              onChanged: (newOption) {
                if (newOption != null) {
                  setState(() => _selectedFormatOption = newOption);
                }
              },
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Match Title / Urgency Note',
                hintText: 'e.g., Competitive evening game, need goalkeeper!',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _venueController,
              decoration: const InputDecoration(
                labelText: 'Venue Address',
                hintText: 'e.g., KTU Sports Center, Radvilėnų pl. 19',
                prefixIcon: Icon(Icons.pin_drop_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: const InputDecoration(
                      labelText: 'Date',
                      hintText: 'DD/MM/YYYY',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _timeController,
                    readOnly: true,
                    onTap: _pickTime,
                    decoration: const InputDecoration(
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

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _spotsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Missing Players (max $_currentTotalPlayers)',
                      hintText: 'e.g., 2',
                      prefixIcon: const Icon(Icons.group_add_outlined),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _feeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Fee per Person (€)',
                      hintText: 'e.g., 5.00 (0 = Free)',
                      prefixIcon: Icon(Icons.euro),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.publish),
                label: const Text('Publish Match', style: TextStyle(fontSize: 16)),
                onPressed: _isSubmitting ? null : _publishMatch,
              ),
            ),
          ],
        ),
      ),
    );
  }
}