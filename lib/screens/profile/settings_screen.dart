import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _pushNotifications = true;
  bool _matchReminders = true;
  bool _darkMode = false;
  bool _isLoading = true;

  // String get _apiUrl {
  //   if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
  //     return 'http://10.0.2.2/sportmatch/api.php';
  //   }
  //   return 'http://localhost/sportmatch/api.php';
  // }

  String get _apiUrl {
    // URL pubblico così funziona sia sul mio PC che su quello del professore!
    return 'http://sportmatch-fabio.atwebpages.com/api.php';
  }

  @override
  void initState() {
    super.initState();
    _loadSettingsFromServer();
  }

  // Legge lo stato attuale delle impostazioni dal JSON del profilo
  Future<void> _loadSettingsFromServer() async {
    try {
      final response = await http.get(Uri.parse('$_apiUrl?action=get_profile&id_user=1'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _pushNotifications = data['push_notifications'] != false;
            _matchReminders = data['match_reminders'] != false;
            _darkMode = data['dark_mode'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Salva ogni modifica agli switch direttamente sul server XAMPP
  Future<void> _syncSettings({String? newPassword}) async {
    try {
      await http.post(
        Uri.parse('$_apiUrl?action=update_settings'),
        body: {
          'id_user': '1',
          'push_notifications': _pushNotifications ? '1' : '0',
          'match_reminders': _matchReminders ? '1' : '0',
          'dark_mode': _darkMode ? '1' : '0',
          if (newPassword != null) 'new_password': newPassword,
        },
      );
    } catch (e) {
      debugPrint('Settings sync error: $e');
    }
  }

  void _showChangePasswordDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'New Password',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newPass = controller.text.trim();
              Navigator.pop(ctx);
              if (newPass.isNotEmpty) {
                await _syncSettings(newPassword: newPass);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password updated on server!')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'NOTIFICATIONS',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Push notifications'),
            subtitle: const Text('Receive updates about new matches'),
            value: _pushNotifications,
            onChanged: (val) {
              setState(() => _pushNotifications = val);
              _syncSettings();
            },
          ),
          SwitchListTile(
            title: const Text('Match reminders'),
            subtitle: const Text('Notification 2 hours before kickoff'),
            value: _matchReminders,
            onChanged: (val) {
              setState(() => _matchReminders = val);
              _syncSettings();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'PREFERENCES',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Dark mode'),
            subtitle: const Text('Save dark theme preference to account'),
            value: _darkMode,
            onChanged: (val) {
              setState(() => _darkMode = val);
              _syncSettings();
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'SECURITY & SESSION',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _showChangePasswordDialog,
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Log out', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}