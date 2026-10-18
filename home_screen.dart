import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SwipeCardDeckScreen(),
    const MatchesAndChatScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: const Color(0xFF6366F1),
        unselectedItemColor: Color(0xFF94A3B8),
        type: BottomNavigationBarType.fixed,
        onTap: (idx) => setState(() => _currentIndex = idx),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.style_rounded), label: 'Match'),
          BottomNavigationBarItem(icon: Icon(Icons.forum_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SWIPE DECK SCREEN (TINDER-LIKE) - DATA FROM FIRESTORE
// -----------------------------------------------------------------------------
class SwipeCardDeckScreen extends StatefulWidget {
  const SwipeCardDeckScreen({super.key});

  @override
  State<SwipeCardDeckScreen> createState() => _SwipeCardDeckScreenState();
}

class _SwipeCardDeckScreenState extends State<SwipeCardDeckScreen>
    with SingleTickerProviderStateMixin {
  List<AlumniProfile> _profiles = [];
  List<String> _userSkills = [];
  Offset _cardOffset = Offset.zero;
  double _cardAngle = 0.0;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!mounted) return;
    setState(() {
      _userSkills = List<String>.from(doc.data()?['skills'] ?? []);
    });
    await _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final snapshot = await FirebaseFirestore.instance.collection('alumni_profiles').get();
    if (!mounted) return;
    setState(() {
      _profiles = snapshot.docs
          .map((doc) => AlumniProfile.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _cardOffset += details.delta;
      _cardAngle = (_cardOffset.dx / _screenSize.width) * 0.35;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_cardOffset.dx.abs() > 120) {
      bool isMatch = _cardOffset.dx > 0;
      _swipeCard(isMatch: isMatch);
    } else {
      setState(() {
        _cardOffset = Offset.zero;
        _cardAngle = 0.0;
      });
    }
  }

  void _swipeCard({required bool isMatch}) {
    if (_profiles.isEmpty) return;
    final swipedProfile = _profiles.removeLast();
    setState(() {
      _cardOffset = Offset.zero;
      _cardAngle = 0.0;
    });
    if (isMatch) {
      _showMatchDialog(swipedProfile);
    }
  }

  void _showMatchDialog(AlumniProfile profile) {
    showDialog(
      context: context,
      builder: (ctx) => MatchCelebrationDialog(profile: profile),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('SkillMatch', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _profiles.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.style_outlined, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No more profiles available right now!', style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      )
                    : Stack(
                        children: _profiles.asMap().entries.map((entry) {
                          int index = entry.key;
                          AlumniProfile profile = entry.value;
                          bool isTop = index == _profiles.length - 1;
                          if (isTop) {
                            return GestureDetector(
                              onPanUpdate: _onPanUpdate,
                              onPanEnd: _onPanEnd,
                              child: Transform.translate(
                                offset: _cardOffset,
                                child: Transform.rotate(
                                  angle: _cardAngle,
                                  child: AlumniCardWidget(
                                    profile: profile,
                                    userSkills: _userSkills,
                                  ),
                                ),
                              ),
                            );
                          } else if (index == _profiles.length - 2) {
                            return Transform.scale(scale: 0.95, child: AlumniCardWidget(profile: profile, userSkills: _userSkills));
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      ),
              ),
            ),
            if (_profiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    FloatingActionButton(
                      heroTag: 'pass',
                      onPressed: () => _swipeCard(isMatch: false),
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(Icons.close_rounded, color: Color(0xFFFF4081), size: 28),
                    ),
                    FloatingActionButton.small(
                      heroTag: 'star',
                      onPressed: () => _swipeCard(isMatch: true),
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(Icons.star_rounded, color: Colors.amber, size: 24),
                    ),
                    FloatingActionButton(
                      heroTag: 'connect',
                      onPressed: () => _swipeCard(isMatch: true),
                      backgroundColor: const Color(0xFF6366F1),
                      child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MATCHES & CHAT LIST SCREEN - DATA FROM FIRESTORE
// -----------------------------------------------------------------------------
class MatchesAndChatScreen extends StatefulWidget {
  const MatchesAndChatScreen({super.key});

  @override
  State<MatchesAndChatScreen> createState() => _MatchesAndChatScreenState();
}

class _MatchesAndChatScreenState extends State<MatchesAndChatScreen> {
  List<AlumniProfile> _profiles = [];

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final snapshot = await FirebaseFirestore.instance.collection('alumni_profiles').get();
    if (!mounted) return;
    setState(() {
      _profiles = snapshot.docs
          .map((doc) => AlumniProfile.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Matches & Chat', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('New Matches', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _profiles.length,
              itemBuilder: (context, index) {
                final alumni = _profiles[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (ctx) => DirectChatScreen(profile: alumni)),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        CircleAvatar(radius: 28, backgroundImage: NetworkImage(alumni.avatarUrl)),
                        const SizedBox(height: 6),
                        Text(alumni.name.split(' ')[0], style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text('Conversations', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _profiles.length,
            separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155)),
            itemBuilder: (context, index) {
              final alumni = _profiles[index];
              return ListTile(
                leading: CircleAvatar(backgroundImage: NetworkImage(alumni.avatarUrl)),
                title: Text(alumni.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Hey! I would love to connect and chat about ${alumni.skills.first}.', maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Text('2m ago', style: TextStyle(fontSize: 11, color: Colors.grey)),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (ctx) => DirectChatScreen(profile: alumni)),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// DIRECT CHAT SCREEN
// -----------------------------------------------------------------------------
class DirectChatScreen extends StatefulWidget {
  final AlumniProfile profile;
  const DirectChatScreen({super.key, required this.profile});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messages.add(
      ChatMessage(
        sender: widget.profile.name,
        text: "Hi there! Glad we matched. How can I assist with your career or ${widget.profile.skills.first} journey?",
        time: 'Just now',
        isMe: false,
      ),
    );
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(sender: 'Me', text: text, time: 'Now', isMe: true));
    });
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    List<String> icebreakers = [
      "Could you review my resume?",
      "How is the AI team at ${widget.profile.company}?",
      "Tips for ${widget.profile.skills.first} interviews?",
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.profile.avatarUrl)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.profile.name, style: const TextStyle(fontSize: 16)),
                Text(widget.profile.company, style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return Align(
                  alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg.isMe ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg.text, style: const TextStyle(color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            height: 40,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: icebreakers.length,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Text(icebreakers[i], style: const TextStyle(fontSize: 11, color: Colors.indigoAccent)),
                  backgroundColor: const Color(0xFF1E293B),
                  onPressed: () => _sendMessage(icebreakers[i]),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(hintText: 'Type a message...', border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF6366F1)),
                  onPressed: () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// ALUMNI CARD COMPONENT
// -----------------------------------------------------------------------------
class AlumniCardWidget extends StatelessWidget {
  final AlumniProfile profile;
  final List<String> userSkills;
  const AlumniCardWidget({super.key, required this.profile, required this.userSkills});

  int _calculateScore() {
    if (userSkills.isEmpty || profile.skills.isEmpty) return 0;
    final matches = userSkills.where((s) => profile.skills.contains(s)).length;
    return ((matches / profile.skills.length) * 100).round();
  }

  List<String> _getMatchingSkills() {
    return userSkills.where((s) => profile.skills.contains(s)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final score = _calculateScore();
    final matching = _getMatchingSkills();

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(image: NetworkImage(profile.avatarUrl), fit: BoxFit.cover),
        boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Colors.black.withOpacity(0.3), Colors.black.withOpacity(0.95)],
            stops: const [0.3, 0.6, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text('$score% Skill Match', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (matching.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF3B82F6).withOpacity(0.85), borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('${matching.join(', ')}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            Row(children: [Expanded(child: Text('${profile.name}, ${profile.gradYear}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)))]),
            Text('${profile.title} @ ${profile.company}', style: const TextStyle(fontSize: 16, color: Color(0xFFCBD5E1))),
            const SizedBox(height: 8),
            Text(profile.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 14),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.skills.map((s) => Chip(label: Text(s, style: const TextStyle(fontSize: 11, color: Colors.white)), backgroundColor: const Color(0xFF334155), padding: const EdgeInsets.all(2), visualDensity: VisualDensity.compact)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MATCH CELEBRATION DIALOG
// -----------------------------------------------------------------------------
class MatchCelebrationDialog extends StatelessWidget {
  final AlumniProfile profile;
  const MatchCelebrationDialog({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(28), border: Border.all(color: const Color(0xFF6366F1), width: 1.5)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 64),
            const SizedBox(height: 12),
            const Text("It's a Skill Match!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            Text("You and ${profile.name} share common interests in ${profile.skills.take(2).join(', ')}.", textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF94A3B8))),
            const SizedBox(height: 20),
            CircleAvatar(radius: 44, backgroundImage: NetworkImage(profile.avatarUrl)),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), minimumSize: const Size(double.infinity, 48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (ctx) => DirectChatScreen(profile: profile)));
              },
              child: const Text('Send Message', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep Swiping', style: TextStyle(color: Colors.grey))),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MODELS
// -----------------------------------------------------------------------------
class AlumniProfile {
  final String id;
  final String name;
  final String title;
  final String company;
  final String gradYear;
  final String major;
  final String avatarUrl;
  final String bio;
  final int matchPercentage;
  final List<String> skills;
  final List<String> mentorshipGoals;

  AlumniProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.company,
    required this.gradYear,
    required this.major,
    required this.avatarUrl,
    required this.bio,
    required this.matchPercentage,
    required this.skills,
    required this.mentorshipGoals,
  });

  factory AlumniProfile.fromFirestore(Map<String, dynamic> data, String docId) {
    return AlumniProfile(
      id: docId,
      name: data['name'] ?? '',
      title: data['title'] ?? '',
      company: data['company'] ?? '',
      gradYear: data['gradYear'] ?? '',
      major: data['major'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
      bio: data['bio'] ?? '',
      matchPercentage: (data['matchPercentage'] ?? 0) as int,
      skills: List<String>.from(data['skills'] ?? []),
      mentorshipGoals: List<String>.from(data['mentorshipGoals'] ?? []),
    );
  }
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;
  ChatMessage({required this.sender, required this.text, required this.time, required this.isMe});
}
