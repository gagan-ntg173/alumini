import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _newSkillController = TextEditingController();
  List<String> _skills = [];
  String? _role;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserSkills();
  }

  @override
  void dispose() {
    _newSkillController.dispose();
    super.dispose();
  }

  Future<void> _loadUserSkills() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Not signed in.';
        });
        return;
      }
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!mounted) return;
      setState(() {
        _skills = List<String>.from(doc.data()?['skills'] ?? []);
        _role = doc.data()?['role'];
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _addSkill() async {
    final skill = _newSkillController.text.trim();
    if (skill.isEmpty || _skills.contains(skill)) return;
    setState(() {
      _skills = [..._skills, skill];
      _newSkillController.clear();
    });
    await _saveSkills();
  }

  Future<void> _removeSkill(String skill) async {
    setState(() {
      _skills = _skills.where((s) => s != skill).toList();
    });
    await _saveSkills();
  }

  Future<void> _saveSkills() async {
    final user = _auth.currentUser;
    if (user == null) return;
    setState(() => _isSaving = true);
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'skills': _skills, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error.message ?? 'Sign out failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final displayName = user?.displayName?.trim();
    final name = displayName == null || displayName.isEmpty
        ? (user?.email?.split('@').first ?? 'Student')
        : displayName;

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 64),
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUserSkills, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Skill Deck'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
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
            Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(user?.email ?? 'Student account', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.work_outline, color: Color(0xFF6366F1)),
              title: const Text('Role'),
              subtitle: Text(_role?.toUpperCase() ?? 'Not set'),
            ),
            const ListTile(
              leading: Icon(Icons.psychology, color: Color(0xFF6366F1)),
              title: Text('Target Skills'),
              subtitle: Text('Edit your skills below'),
            ),
            const Divider(color: Color(0xFF334155)),
            const SizedBox(height: 16),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Your Skills', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._skills.map(
                  (s) => Chip(
                    label: Text(s),
                    onDeleted: () => _removeSkill(s),
                    backgroundColor: const Color(0xFF334155),
                    deleteIconColor: Colors.white,
                  ),
                ),
                ActionChip(
                  label: const Text('Add'),
                  onPressed: _isSaving ? null : _addSkill,
                  avatar: const Icon(Icons.add, size: 18),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _newSkillController,
              onSubmitted: (_) => _addSkill(),
              decoration: InputDecoration(
                hintText: 'Add a skill...',
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
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
