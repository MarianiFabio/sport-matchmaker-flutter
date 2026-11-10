import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic>? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _surnameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _bioController;
  late TextEditingController _cityController;
  late TextEditingController _phoneController;

  String _abilityLevel = 'Intermediate';
  bool _isPlayer = true;
  bool _isOrganizer = true;
  Set<String> _selectedFavoriteSports = {'Football', 'Padel'};
  bool _isSaving = false;

  static const List<String> _allSports = [
    'Football',
    'Basketball',
    'Padel',
    'Tennis',
    'Volleyball',
    'Badminton',
    'Table Tennis',
    'Rugby',
  ];

  static const List<String> _abilityLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Pro / Competitive',
  ];

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
    final p = widget.initialProfile ?? {};
    _nameController = TextEditingController(text: (p['name'] ?? 'Fabio').toString());
    _surnameController = TextEditingController(text: (p['surname'] ?? 'Mariani').toString());
    _usernameController = TextEditingController(text: (p['username'] ?? 'fabio_m').toString());
    _emailController = TextEditingController(text: (p['email'] ?? 'fabio@email.com').toString());
    _bioController = TextEditingController(text: (p['bio'] ?? '').toString());
    _cityController = TextEditingController(text: (p['city'] ?? 'Kaunas').toString());
    _phoneController = TextEditingController(text: (p['phone'] ?? '+39 333 1234567').toString());

    final String level = (p['ability_level'] ?? 'Intermediate').toString();
    _abilityLevel = _abilityLevels.contains(level) ? level : 'Intermediate';
    _isPlayer = p['is_player'] != false;
    _isOrganizer = p['is_organizer'] != false;

    if (p['favorite_sports'] is List) {
      _selectedFavoriteSports = (p['favorite_sports'] as List)
          .map((e) => e.toString())
          .toSet();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);

    try {
      final url = Uri.parse('$_apiUrl?action=update_profile');
      final response = await http.post(
        url,
        body: {
          'id_user': '1',
          'name': _nameController.text.trim(),
          'surname': _surnameController.text.trim(),
          'username': _usernameController.text.trim(),
          'email': _emailController.text.trim(),
          'bio': _bioController.text.trim(),
          'city': _cityController.text.trim(),
          'phone': _phoneController.text.trim(),
          'ability_level': _abilityLevel,
          'favorite_sports': _selectedFavoriteSports.join(','),
          'is_player': _isPlayer ? '1' : '0',
          'is_organizer': _isOrganizer ? '1' : '0',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile & preferences saved to server!')),
        );
        Navigator.pop(context, true);
      } else {
        throw Exception('Server status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _surnameController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.alternate_email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Bio / Player Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Skill / Ability Level',
                prefixIcon: Icon(Icons.workspace_premium_outlined),
                border: OutlineInputBorder(),
              ),
              value: _abilityLevel,
              items: _abilityLevels
                  .map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _abilityLevel = val);
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Favorite Sports',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allSports.map((sport) {
                final isSelected = _selectedFavoriteSports.contains(sport);
                return FilterChip(
                  label: Text(sport),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFavoriteSports.add(sport);
                      } else {
                        _selectedFavoriteSports.remove(sport);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Available as Player'),
              subtitle: const Text('Join matches organized by others'),
              value: _isPlayer,
              onChanged: (val) => setState(() => _isPlayer = val),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Match Organizer'),
              subtitle: const Text('Host and manage your own matches'),
              value: _isOrganizer,
              onChanged: (val) => setState(() => _isOrganizer = val),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: _isSaving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                onPressed: _isSaving ? null : _saveProfile,
              ),
            ),
          ],
        ),
      ),
    );
  }
}