import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/match_item.dart';
import '../main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLogin = true;
  bool _isSubmitting = false;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController =
  TextEditingController(text: 'fabio@email.com');
  final TextEditingController _passwordController =
  TextEditingController(text: 'password123');

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Esegue il vero Login o Registrazione con controllo passwordHash sul DB XAMPP
  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty || (!_isLogin && fullName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final action = _isLogin ? 'login' : 'register';
      final response = await http.post(
        Uri.parse('${UserSession.apiUrl}?action=$action'),
        body: {
          'full_name': fullName,
          'email': email,
          'password': password,
        },
      );

      final decoded = json.decode(response.body) as Map<String, dynamic>;

      if (!mounted) return;

      if (response.statusCode == 200 && decoded['success'] == true) {
        // Salva i dati dell'utente loggato (inclusi i suoi sport preferiti!) nella sessione
        UserSession.updateFromJson(decoded);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((decoded['message'] ?? 'Authenticated!').toString())),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MainNavigationScreen(),
          ),
        );
      } else {
        // Mostra l'errore reale (es. password errata o email già esistente)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red[700],
            content: Text((decoded['error'] ?? 'Authentication failed').toString()),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red[700],
          content: Text('Cannot connect to XAMPP server: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _fillDemoUser(String email) {
    setState(() {
      _isLogin = true;
      _emailController.text = email;
      _passwordController.text = 'password123';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 80,
                  color: Colors.teal,
                ),
                const SizedBox(height: 16),
                Text(
                  _isLogin ? 'Welcome Back!' : 'Create an Account',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isLogin
                      ? 'Sign in to find teammates and organize matches'
                      : 'Sign up to start playing in your city',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                if (!_isLogin) ...[
                  TextField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name (Name & Surname)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submitAuth,
                    child: _isSubmitting
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                        : Text(_isLogin ? 'Sign In' : 'Sign Up', style: const TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isLogin = !_isLogin;
                    });
                  },
                  child: Text(
                    _isLogin
                        ? 'Don\'t have an account? Sign up'
                        : 'Already have an account? Sign in',
                  ),
                ),
                if (_isLogin) ...[
                  const Divider(height: 32),
                  const Text(
                    'Quick Demo Switch (Password: password123)',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: const Text('Fabio'),
                        onPressed: () => _fillDemoUser('fabio@email.com'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: const Text('Luca'),
                        onPressed: () => _fillDemoUser('luca@email.com'),
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.person, size: 16),
                        label: const Text('Andrea'),
                        onPressed: () => _fillDemoUser('andrea@email.com'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}