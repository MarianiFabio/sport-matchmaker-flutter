import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/match_item.dart';

// 1. SCHERMATA PRINCIPALE: LISTA CHAT DEI CLUB IN STILE WHATSAPP
class ClubsScreen extends StatefulWidget {
  const ClubsScreen({super.key});

  @override
  State<ClubsScreen> createState() => _ClubsScreenState();
}

class _ClubsScreenState extends State<ClubsScreen> {
  List _allClubs = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  Future<void> _loadClubs() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        '${UserSession.apiUrl}?action=get_clubs&id_user=${UserSession.currentUserId}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _allClubs = decoded.map((e) => e as Map<String, dynamic>).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading clubs: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinClub(Map<String, dynamic> club) async {
    try {
      await http.post(
        Uri.parse('${UserSession.apiUrl}?action=join_club'),
        body: {
          'id_club': club['id_club'].toString(),
          'id_user': UserSession.currentUserId.toString(),
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('You joined "${club['club_name']}"!')),
      );
      await _loadClubs();
      if (!mounted) return;
      _openClubChat(club);
    } catch (e) {
      debugPrint('Join club error: $e');
    }
  }

  Future<void> _openClubChat(Map<String, dynamic> club) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubChatScreen(
          idClub: club['id_club'] as int,
          clubName: club['club_name'].toString(),
          sportCategory: club['sport_category'].toString(),
          memberCount: club['member_count'] as int,
        ),
      ),
    );
    _loadClubs();
  }

  void _showCreateClubDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String selectedSport = 'Football';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Friend Group / Club',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Club Name',
                      hintText: 'e.g., Kaunas Thursday Futsal',
                      prefixIcon: Icon(Icons.groups_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: selectedSport,
                    decoration: const InputDecoration(
                      labelText: 'Main Sport',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Football', child: Text('Football')),
                      DropdownMenuItem(value: 'Basketball', child: Text('Basketball')),
                      DropdownMenuItem(value: 'Padel', child: Text('Padel')),
                      DropdownMenuItem(value: 'Tennis', child: Text('Tennis')),
                      DropdownMenuItem(value: 'Volleyball', child: Text('Volleyball')),
                      DropdownMenuItem(value: 'Badminton', child: Text('Badminton')),
                      DropdownMenuItem(value: 'Rugby', child: Text('Rugby')),
                    ],
                    onChanged: (val) {
                      if (val != null) setModalState(() => selectedSport = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Short Description',
                      hintText: 'e.g., Friends group for weekly evening games',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.add),
                      label: const Text('Create Club'),
                      onPressed: () async {
                        final name = nameCtrl.text.trim();
                        if (name.isEmpty) return;
                        Navigator.pop(ctx);
                        final response = await http.post(
                          Uri.parse('${UserSession.apiUrl}?action=create_club'),
                          body: {
                            'club_name': name,
                            'description': descCtrl.text.trim(),
                            'sport_category': selectedSport,
                            'id_user': UserSession.currentUserId.toString(),
                            'user_name': UserSession.fullName,
                          },
                        );
                        if (!mounted) return;
                        final decoded = json.decode(response.body) as Map<String, dynamic>;
                        if (decoded['success'] == true) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Club "$name" created!')),
                          );
                          _loadClubs();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text((decoded['error'] ?? 'Error').toString())),
                          );
                        }
                      },
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

  @override
  Widget build(BuildContext context) {
    final filtered = _allClubs.where((c) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return c['club_name'].toString().toLowerCase().contains(q) ||
          c['sport_category'].toString().toLowerCase().contains(q) ||
          c['description'].toString().toLowerCase().contains(q);
    }).toList();

    final myClubs = filtered.where((c) => c['is_member'] == true).toList();
    final discoverClubs = filtered.where((c) => c['is_member'] != true).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clubs & Chats', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClubs,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateClubDialog,
        icon: const Icon(Icons.group_add),
        label: const Text('New Club'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search clubs or sports...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
              padding: const EdgeInsets.only(bottom: 80),
              children: [
                // SEZIONE 1: I MIEI CLUB (Stile lista chat WhatsApp)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'MY CLUB CHATS (${myClubs.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (myClubs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('You have not joined any clubs yet. Join one below or create a new club!'),
                  )
                else
                  ...myClubs.map((club) {
                    final sport = club['sport_category'].toString();
                    return Column(
                      children: [
                        ListTile(
                          onTap: () => _openClubChat(club),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              MatchItem.iconForCategory(sport),
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  club['club_name'].toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                club['last_time'].toString(),
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              club['last_message'].toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
                        ),
                        const Divider(height: 1, indent: 72),
                      ],
                    );
                  }),

                const SizedBox(height: 16),

                // SEZIONE 2: ESPLORA ALTRI CLUB A CUI UNIRSI
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'DISCOVER CLUBS TO JOIN (${discoverClubs.length})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                if (discoverClubs.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('You are already a member of all available clubs!'),
                  )
                else
                  ...discoverClubs.map((club) {
                    final sport = club['sport_category'].toString();
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(MatchItem.iconForCategory(sport), color: Colors.teal),
                        ),
                        title: Text(
                          club['club_name'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${club['description']} • ${club['member_count']} members',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: FilledButton.tonal(
                          onPressed: () => _joinClub(club),
                          child: const Text('Join'),
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 2. SCHERMATA INTERNA DELLA CHAT DEL SINGOLO CLUB (Con Sondaggi e Controllo Organizzatore)
class ClubChatScreen extends StatefulWidget {
  final int idClub;
  final String clubName;
  final String sportCategory;
  final int memberCount;

  const ClubChatScreen({
    super.key,
    required this.idClub,
    required this.clubName,
    required this.sportCategory,
    required this.memberCount,
  });

  @override
  State<ClubChatScreen> createState() => _ClubChatScreenState();
}

class _ClubChatScreenState extends State<ClubChatScreen> {
  List _clubItems = [];
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClubFeed();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadClubFeed() async {
    setState(() => _isLoading = true);
    try {
      final url = Uri.parse(
        '${UserSession.apiUrl}?action=get_club_feed&club_name=${Uri.encodeComponent(widget.clubName)}',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> decoded = json.decode(response.body) as List<dynamic>;
        if (mounted) {
          setState(() {
            _clubItems = decoded.map((e) => e as Map<String, dynamic>).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Club chat error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    try {
      await http.post(
        Uri.parse('${UserSession.apiUrl}?action=post_club_item'),
        body: {
          'club_name': widget.clubName,
          'id_sender': UserSession.currentUserId.toString(),
          'sender_name': UserSession.fullName,
          'item_type': 'MESSAGE',
          'message_text': text,
        },
      );
      _loadClubFeed();
    } catch (e) {
      debugPrint('Send message error: $e');
    }
  }

  Future<void> _leaveClub() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Club?'),
        content: Text('Do you want to leave "${widget.clubName}"? You can rejoin anytime.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await http.post(
      Uri.parse('${UserSession.apiUrl}?action=leave_club'),
      body: {
        'id_club': widget.idClub.toString(),
        'id_user': UserSession.currentUserId.toString(),
      },
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('You left "${widget.clubName}".')),
    );
    Navigator.pop(context);
  }

  Future<void> _votePoll(int idItem, String vote) async {
    try {
      await http.post(
        Uri.parse('${UserSession.apiUrl}?action=vote_poll'),
        body: {
          'id_item': idItem.toString(),
          'id_user': UserSession.currentUserId.toString(),
          'vote': vote,
        },
      );
      _loadClubFeed();
    } catch (e) {
      debugPrint('Vote error: $e');
    }
  }

  Future<void> _convertToPublicMatch(int idItem) async {
    try {
      final response = await http.post(
        Uri.parse('${UserSession.apiUrl}?action=convert_poll_to_match'),
        body: {
          'id_item': idItem.toString(),
          'id_user': UserSession.currentUserId.toString(),
        },
      );
      final decoded = json.decode(response.body) as Map<String, dynamic>;
      if (!mounted) return;

      if (decoded['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.teal[700],
            content: Text(
              'Published to Public Feed! Looking for ${decoded['missing_slots']} missing players.',
            ),
          ),
        );
        _loadClubFeed();
      }
    } catch (e) {
      debugPrint('Convert error: $e');
    }
  }

  void _openProposeMatchDialog() {
    String sportCat = widget.sportCategory;
    String format = sportCat == 'Padel'
        ? '2v2 (Doubles)'
        : (sportCat == 'Basketball'
        ? '3v3 (Streetball)'
        : (sportCat == 'Volleyball' ? '6v6 (Indoor)' : '5v5 (Futsal)'));
    int totalSlots = sportCat == 'Padel'
        ? 4
        : (sportCat == 'Basketball' ? 6 : (sportCat == 'Volleyball' ? 12 : 10));

    final titleCtrl = TextEditingController();
    final venueCtrl = TextEditingController(text: 'KTU Sports Center');
    final dateCtrl = TextEditingController(text: '26/11/2026');
    final timeCtrl = TextEditingController(text: '20:00');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Propose Group Match (Quick Poll)',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: sportCat,
                    decoration: const InputDecoration(
                      labelText: 'Sport & Format',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Football', child: Text('Football • 5v5 (10 players)')),
                      DropdownMenuItem(value: 'Football7', child: Text('Football • 7v7 (14 players)')),
                      DropdownMenuItem(value: 'Padel', child: Text('Padel • 2v2 (4 players)')),
                      DropdownMenuItem(value: 'Basketball', child: Text('Basketball • 3v3 (6 players)')),
                      DropdownMenuItem(value: 'Volleyball', child: Text('Volleyball • 6v6 (12 players)')),
                    ],
                    onChanged: (val) {
                      if (val == null) return;
                      setModalState(() {
                        if (val == 'Football') {
                          sportCat = 'Football';
                          format = '5v5 (Futsal)';
                          totalSlots = 10;
                        } else if (val == 'Football7') {
                          sportCat = 'Football';
                          format = '7v7';
                          totalSlots = 14;
                        } else if (val == 'Padel') {
                          sportCat = 'Padel';
                          format = '2v2 (Doubles)';
                          totalSlots = 4;
                        } else if (val == 'Basketball') {
                          sportCat = 'Basketball';
                          format = '3v3 (Streetball)';
                          totalSlots = 6;
                        } else {
                          sportCat = 'Volleyball';
                          format = '6v6 (Indoor)';
                          totalSlots = 12;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Proposal Note',
                      hintText: 'e.g., Thursday clan match, who is in?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: venueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Venue',
                      prefixIcon: Icon(Icons.pin_drop_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: dateCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Date (DD/MM/YYYY)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: timeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Time (HH:MM)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.poll_outlined),
                      label: const Text('Launch Poll as Organizer'),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await http.post(
                          Uri.parse('${UserSession.apiUrl}?action=post_club_item'),
                          body: {
                            'club_name': widget.clubName,
                            'id_sender': UserSession.currentUserId.toString(),
                            'sender_name': UserSession.fullName,
                            'item_type': 'POLL',
                            'message_text': titleCtrl.text.trim(),
                            'sport_category': sportCat == 'Football7' ? 'Football' : sportCat,
                            'sport_format': format,
                            'venue_name': venueCtrl.text.trim(),
                            'match_date': dateCtrl.text.trim(),
                            'match_time': timeCtrl.text.trim(),
                            'total_slots': totalSlots.toString(),
                          },
                        );
                        _loadClubFeed();
                      },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.clubName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${widget.sportCategory} Club • ${widget.memberCount} members',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadClubFeed,
          ),
          IconButton(
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Leave Club',
            onPressed: _leaveClub,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _clubItems.isEmpty
                ? const Center(child: Text('No messages yet. Start chatting or launch a poll!'))
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clubItems.length,
              itemBuilder: (context, index) {
                final item = _clubItems[index];
                if (item['item_type'] == 'POLL') {
                  return _buildPollCard(item);
                }
                return _buildChatBubble(item);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _openProposeMatchDialog,
                    icon: const Icon(Icons.add_chart, size: 18),
                    label: const Text('Poll'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 6),
                  IconButton.filled(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, size: 18),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(Map<String, dynamic> item) {
    final bool isMe = item['id_sender'] == UserSession.currentUserId;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 290),
        decoration: BoxDecoration(
          color: isMe
              ? Theme.of(context).colorScheme.primaryContainer
              : Colors.grey[200],
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isMe ? 'You' : (item['sender_name'] ?? 'Member').toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text((item['message_text'] ?? '').toString()),
            const SizedBox(height: 2),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                (item['created_at'] ?? '').toString(),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPollCard(Map<String, dynamic> item) {
    final int idItem = item['id_item'] as int;
    final int idOrganizer = int.tryParse((item['id_sender'] ?? '0').toString()) ?? 0;
    final bool isPollOrganizer = idOrganizer == UserSession.currentUserId;

    final List<dynamic> accepted = (item['accepted_users'] as List<dynamic>?) ?? [];
    final List<dynamic> declined = (item['declined_users'] as List<dynamic>?) ?? [];
    final int totalSlots = (item['total_slots'] as int?) ?? 10;
    final int acceptedCount = accepted.length;
    final int missingSlots = (totalSlots - acceptedCount).clamp(0, totalSlots);
    final bool isConverted = item['is_converted'] == true;

    final String myIdStr = UserSession.currentUserId.toString();
    final bool iAccepted = accepted.map((e) => e.toString()).contains(myIdStr);
    final bool iDeclined = declined.map((e) => e.toString()).contains(myIdStr);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  avatar: const Icon(Icons.poll, size: 16),
                  label: Text('${item['sport_category']} • ${item['sport_format']}'),
                  visualDensity: VisualDensity.compact,
                ),
                Text(
                  isPollOrganizer ? 'Organizer: You' : 'Organizer: ${item['sender_name']}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isPollOrganizer ? FontWeight.bold : FontWeight.normal,
                    color: isPollOrganizer ? Colors.teal[700] : Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (item['message_text'] ?? 'Match Proposal').toString(),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '📍 ${item['venue_name']}  •  🗓️ ${item['match_date']}, ${item['match_time']}',
              style: TextStyle(fontSize: 13, color: Colors.grey[700]),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: totalSlots > 0 ? (acceptedCount / totalSlots).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 6),
            Text(
              '$acceptedCount / $totalSlots Players In  •  ${declined.length} Declined  •  $missingSlots Missing',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _votePoll(idItem, 'ACCEPT'),
                    icon: Icon(
                      iAccepted ? Icons.check_circle : Icons.check_circle_outline,
                      color: iAccepted ? Colors.green[800] : null,
                    ),
                    label: Text(iAccepted ? "I'm In ✓" : "I'm In"),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _votePoll(idItem, 'DECLINE'),
                    icon: Icon(
                      Icons.cancel_outlined,
                      color: iDeclined ? Colors.red : null,
                    ),
                    label: Text(iDeclined ? "Can't ✗" : "Can't"),
                  ),
                ),
              ],
            ),
            if (missingSlots > 0) ...[
              const Divider(height: 20),
              if (isConverted)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.public, size: 16, color: Colors.green),
                      SizedBox(width: 6),
                      Text(
                        'Converted to Public Match in Home Feed!',
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ],
                  ),
                )
              else if (isPollOrganizer)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _convertToPublicMatch(idItem),
                    icon: const Icon(Icons.public, size: 18),
                    label: Text('Open $missingSlots Missing Spots to Public Feed'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline, size: 15, color: Colors.grey),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Only the organizer (${item['sender_name']}) can open the $missingSlots missing spots to public.',
                          style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}