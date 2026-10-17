import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const AlumMatchApp());
}

class AlumMatchApp extends StatelessWidget {
  const AlumMatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlumMatch',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      home: const MainNavigationScreen(),
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
}

class ChatMessage {
  final String sender;
  final String text;
  final String time;
  final bool isMe;

  ChatMessage({
    required this.sender,
    required this.text,
    required this.time,
    required this.isMe,
  });
}

// -----------------------------------------------------------------------------
// DUMMY DATA
// -----------------------------------------------------------------------------
final List<AlumniProfile> mockAlumniList = [
  AlumniProfile(
    id: '1',
    name: 'Sarah Chen',
    title: 'Senior AI Engineer',
    company: 'Google',
    gradYear: "'18",
    major: 'Computer Science',
    avatarUrl:
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=500&auto=format&fit=crop&q=80',
    bio:
        'Passionate about LLMs, Distributed Systems, and scaling AI startups. Looking to help students break into FAANG AI roles.',
    matchPercentage: 96,
    skills: ['PyTorch', 'Python', 'LLMs', 'System Design'],
    mentorshipGoals: ['Resume Review', 'Mock Interview', 'AI Advice'],
  ),
  AlumniProfile(
    id: '2',
    name: 'Marcus Vance',
    title: 'Lead Product Manager',
    company: 'Stripe',
    gradYear: "'16",
    major: 'Economics & CS',
    avatarUrl:
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&auto=format&fit=crop&q=80',
    bio:
        'Ex-founder. Love product strategy, fintech systems, and helping young alumni navigate career pivots.',
    matchPercentage: 89,
    skills: ['Product Strategy', 'Fintech', 'SQL', 'A/B Testing'],
    mentorshipGoals: ['Portfolio Review', 'Career Growth', 'Networking'],
  ),
  AlumniProfile(
    id: '3',
    name: 'Elena Rostova',
    title: 'Staff UI/UX Designer',
    company: 'Airbnb',
    gradYear: "'20",
    major: 'HCI / Design',
    avatarUrl:
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=500&auto=format&fit=crop&q=80',
    bio:
        'Design system advocate. Open to portfolio feedback, design crit, and advice on transitioning from college to tech design.',
    matchPercentage: 92,
    skills: ['Figma', 'UX Research', 'Design Systems', 'Prototyping'],
    mentorshipGoals: ['Design Feedback', 'Portfolio Review'],
  ),
];

// -----------------------------------------------------------------------------
// MAIN BOTTOM NAV SCREEN
// -----------------------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const SwipeCardDeckScreen(),
    const MatchesAndChatScreen(),
    const UserProfileScreen(),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.style_rounded),
            label: 'Match',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.forum_rounded),
            label: 'Messages',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// SWIPE DECK SCREEN
// -----------------------------------------------------------------------------
class SwipeCardDeckScreen extends StatefulWidget {
  const SwipeCardDeckScreen({super.key});

  @override
  State<SwipeCardDeckScreen> createState() => _SwipeCardDeckScreenState();
}

class _SwipeCardDeckScreenState extends State<SwipeCardDeckScreen>
    with SingleTickerProviderStateMixin {
  List<AlumniProfile> _profiles = [];
  Offset _cardOffset = Offset.zero;
  double _cardAngle = 0.0;
  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _profiles = List.from(mockAlumniList);
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

  void _openFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => const FilterBottomSheet(),
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
              child: const Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AlumMatch',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white),
            onPressed: _openFilterBottomSheet,
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
                            Icon(
                              Icons.style_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No more profiles available right now!',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
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
                                  child: AlumniCardWidget(profile: profile),
                                ),
                              ),
                            );
                          } else if (index == _profiles.length - 2) {
                            return Transform.scale(
                              scale: 0.95,
                              child: AlumniCardWidget(profile: profile),
                            );
                          }
                          return const SizedBox.shrink();
                        }).toList(),
                      ),
              ),
            ),

            // ACTION BUTTONS
            if (_profiles.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Reject Pass Button
                    FloatingActionButton(
                      heroTag: 'pass',
                      onPressed: () => _swipeCard(isMatch: false),
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFFFF4081),
                        size: 28,
                      ),
                    ),

                    // Super Connect
                    FloatingActionButton.small(
                      heroTag: 'star',
                      onPressed: () => _swipeCard(isMatch: true),
                      backgroundColor: const Color(0xFF1E293B),
                      child: const Icon(
                        Icons.star_rounded,
                        color: Colors.amber,
                        size: 24,
                      ),
                    ),

                    // Match/Connect Button
                    FloatingActionButton(
                      heroTag: 'connect',
                      onPressed: () => _swipeCard(isMatch: true),
                      backgroundColor: const Color(0xFF6366F1),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
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
// ALUMNI CARD COMPONENT
// -----------------------------------------------------------------------------
class AlumniCardWidget extends StatelessWidget {
  final AlumniProfile profile;

  const AlumniCardWidget({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: DecorationImage(
          image: NetworkImage(profile.avatarUrl),
          fit: BoxFit.cover,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.3),
              Colors.black.withOpacity(0.95),
            ],
            stops: const [0.3, 0.6, 1.0],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // MATCH BADGE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.85),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt, color: Colors.white, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${profile.matchPercentage}% Skill Match',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // NAME & GRAD
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${profile.name}, ${profile.gradYear}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // TITLE & COMPANY
            Text(
              '${profile.title} @ ${profile.company}',
              style: const TextStyle(fontSize: 16, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 8),

            // BIO
            Text(
              profile.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),

            // SKILL CHIPS
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: profile.skills
                  .map(
                    (s) => Chip(
                      label: Text(
                        s,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                      backgroundColor: const Color(0xFF334155),
                      padding: const EdgeInsets.all(2),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
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
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 64),
            const SizedBox(height: 12),
            const Text(
              "It's a Skill Match!",
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You and ${profile.name} share common interests in ${profile.skills.take(2).join(', ')}.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 20),

            CircleAvatar(
              radius: 44,
              backgroundImage: NetworkImage(profile.avatarUrl),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => DirectChatScreen(profile: profile),
                  ),
                );
              },
              child: const Text(
                'Send Message',
                style: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Keep Swiping',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MATCHES & CHAT LIST SCREEN
// -----------------------------------------------------------------------------
class MatchesAndChatScreen extends StatelessWidget {
  const MatchesAndChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Matches & Chat',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'New Matches',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 90,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mockAlumniList.length,
              itemBuilder: (context, index) {
                final alumni = mockAlumniList[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => DirectChatScreen(profile: alumni),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 14),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: NetworkImage(alumni.avatarUrl),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          alumni.name.split(' ')[0],
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Conversations',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: mockAlumniList.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFF334155)),
            itemBuilder: (context, index) {
              final alumni = mockAlumniList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(alumni.avatarUrl),
                ),
                title: Text(
                  alumni.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Hey! I would love to connect and chat about ${alumni.skills.first}.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Text(
                  '2m ago',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => DirectChatScreen(profile: alumni),
                    ),
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
// DIRECT CHAT & SMART ICEBREAKERS
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
        text:
            "Hi there! Glad we matched. How can I assist with your career or ${widget.profile.skills.first} journey?",
        time: 'Just now',
        isMe: false,
      ),
    );
  }

  void _sendMessage([String? customText]) {
    final text = customText ?? _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(sender: 'Me', text: text, time: 'Now', isMe: true),
      );
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
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.profile.avatarUrl),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.profile.name, style: const TextStyle(fontSize: 16)),
                Text(
                  '${widget.profile.company}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
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
                  alignment: msg.isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isMe
                          ? const Color(0xFF6366F1)
                          : const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      msg.text,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),

          // SMART ICEBREAKER PILLS
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
                  label: Text(
                    icebreakers[i],
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  backgroundColor: const Color(0xFF1E293B),
                  onPressed: () => _sendMessage(icebreakers[i]),
                ),
              ),
            ),
          ),

          // INPUT BAR
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF6366F1),
                  ),
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
// USER PROFILE SCREEN
// -----------------------------------------------------------------------------
class UserProfileScreen extends StatelessWidget {
  const UserProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Skill Deck')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=500&auto=format&fit=crop&q=80',
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Alex Rivera',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Computer Science Senior @ Class of \'25',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),

            const ListTile(
              leading: Icon(Icons.psychology, color: Color(0xFF6366F1)),
              title: Text('Target Skills'),
              subtitle: Text('System Design, React Native, Machine Learning'),
            ),
            const Divider(color: Color(0xFF334155)),
            const ListTile(
              leading: Icon(Icons.flag, color: Color(0xFF6366F1)),
              title: Text('Mentorship Goals'),
              subtitle: Text('Resume Review, Mock Interviews'),
            ),
          ],
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FILTER BOTTOM SHEET
// -----------------------------------------------------------------------------
class FilterBottomSheet extends StatelessWidget {
  const FilterBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Alumni Stack',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Filter by Target Skill',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['System Design', 'AI / ML', 'Product Management', 'UX']
                .map(
                  (s) => FilterChip(
                    label: Text(s),
                    selected: s == 'AI / ML',
                    onSelected: (_) {},
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Apply Filters',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
