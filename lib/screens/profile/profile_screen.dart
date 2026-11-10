import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'edit_profile_screen.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  String? _errorMessage;

  // String get _apiUrl {
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2/sportmatch/api.php';
  //   }
  //   return 'http://localhost/sportmatch/api.php';
  // }

  String get _apiUrl {
    // URL pubblico
    return 'http://sportmatch-fabio.atwebpages.com/api.php';
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // Carica i dati del profilo dal JSON di XAMPP senza usare FutureBuilder
  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse('$_apiUrl?action=get_profile&id_user=1');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _userData = decoded;
            _isLoading = false;
          });
        }
      } else {
        throw Exception('Server status ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProfile,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null || _userData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
              const SizedBox(height: 12),
              Text(
                'Could not load profile from XAMPP:\n${_errorMessage ?? ''}',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final user = _userData!;
    final String firstName = (user['name'] ?? 'Fabio').toString();
    final String lastName = (user['surname'] ?? 'Mariani').toString();
    final String fullName = '$firstName $lastName'.trim();
    final String initials =
    '${firstName.isNotEmpty ? firstName[0] : 'F'}${lastName.isNotEmpty ? lastName[0] : 'M'}'
        .toUpperCase();

    final List<dynamic> rawFavorites = (user['favorite_sports'] as List<dynamic>?) ?? [];
    final List<String> favoriteSports = rawFavorites.map((e) => e.toString()).toList();

    final List<String> activeRoles = [];
    if (user['is_player'] == true) activeRoles.add('Player');
    if (user['is_organizer'] == true) activeRoles.add('Organizer');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(fullName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          Text('@${user['username'] ?? ''}', style: TextStyle(color: Colors.grey[600])),
          const SizedBox(height: 8),
          if ((user['bio'] ?? '').toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                user['bio'].toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[800]),
              ),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.star, size: 16, color: Colors.amber),
                label: Text('Level: ${user['ability_level'] ?? 'Intermediate'}'),
              ),
              Chip(
                avatar: const Icon(Icons.location_city, size: 16),
                label: Text((user['city'] ?? 'Kaunas').toString()),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          '${user['karma_score'] ?? 100}%',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Karma Score', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          '${user['matches_organized'] ?? 0}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Hosted', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          '${user['matches_joined'] ?? 0}',
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const Text('Joined', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Favorite Sports',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: favoriteSports.isEmpty
                ? const Text('No favorite sports selected yet.')
                : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: favoriteSports
                  .map((sport) => Chip(
                label: Text(sport),
                backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email'),
                  subtitle: Text((user['email'] ?? '').toString()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('Phone'),
                  subtitle: Text((user['phone'] ?? '').toString()),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Active Roles'),
                  subtitle: Text(activeRoles.join(' • ')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile & Favorite Sports'),
              onPressed: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProfileScreen(initialProfile: user),
                  ),
                );
                if (updated == true) {
                  _loadProfile();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}