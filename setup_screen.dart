import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _nameController = TextEditingController();
  String? _role;
  final Set<String> _selectedSkills = {};
  final Set<String> _customSkills = {};
  final _newSkillController = TextEditingController();
  bool _isSaving = false;

  static const List<String> _skillOptions = [
    'Python',
    'JavaScript',
    'React',
    'Flutter',
    'Node.js',
    'Java',
    'C++',
    'Swift',
    'Kotlin',
    'SQL',
    'MongoDB',
    'Firebase',
    'AWS',
    'Docker',
    'Kubernetes',
    'UI/UX Design',
    'Figma',
    'Machine Learning',
    'AI / ML',
    'Data Analysis',
    'Product Management',
    'Project Management',
    'Digital Marketing',
    'Content Writing',
    'Public Speaking',
    'Leadership',
  ];

  @override
  void initState() {
    super.initState();
    final user = _auth.currentUser;
    if (user != null) {
      _nameController.text = user.displayName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _toggleSkill(String skill) {
    setState(() {
      if (_selectedSkills.contains(skill)) {
        _selectedSkills.remove(skill);
      } else {
        _selectedSkills.add(skill);
      }
    });
  }

  void _addCustomSkill() {
    final skill = _newSkillController.text.trim();
    if (skill.isEmpty || _selectedSkills.contains(skill) || _customSkills.contains(skill)) return;
    setState(() {
      _customSkills.add(skill);
      _selectedSkills.add(skill);
      _newSkillController.clear();
    });
  }

  void _removeCustomSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
      _selectedSkills.remove(skill);
    });
  }

  Future<void> _saveProfile() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your name')));
      return;
    }
    if (_role == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a role')));
      return;
    }
    if (_selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select at least one skill')));
      return;
    }

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    try {
      await user.updateDisplayName(name);
      await _firestore.collection('users').doc(user.uid).set({
        'name': name,
        'email': user.email,
        'role': _role,
        'skills': _selectedSkills.toList(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Center(
                child: _BrandMark(size: 72),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tell us about yourself',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'This helps us match you with the right people.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                  filled: true,
                  fillColor: const Color(0xFF1E293B),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5)),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Role', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Student',
                      selected: _role == 'Student',
                      onSelected: (v) => setState(() => _role = v ? 'Student' : null),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ChoiceChip(
                      label: 'Alumni',
                      selected: _role == 'Alumni',
                      onSelected: (v) => setState(() => _role = v ? 'Alumni' : null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Skills', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._skillOptions.map(
                    (s) => FilterChip(
                      label: Text(s),
                      selected: _selectedSkills.contains(s),
                      onSelected: (_) => _toggleSkill(s),
                      backgroundColor: const Color(0xFF1E293B),
                      selectedColor: const Color(0xFF6366F1),
                      checkmarkColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newSkillController,
                      onSubmitted: (_) => _addCustomSkill(),
                      decoration: InputDecoration(
                        hintText: 'Add custom skill...',
                        filled: true,
                        fillColor: const Color(0xFF1E293B),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addCustomSkill,
                    icon: const Icon(Icons.add, color: Color(0xFF6366F1)),
                  ),
                ],
              ),
              if (_customSkills.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _customSkills.map(
                    (s) => Chip(
                      label: Text(s),
                      onDeleted: () => _removeCustomSkill(s),
                      backgroundColor: const Color(0xFF6366F1),
                      deleteIconColor: Colors.white,
                    ),
                  ).toList(),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save & Continue', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  const _ChoiceChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: const Color(0xFF1E293B),
      selectedColor: const Color(0xFF6366F1),
      checkmarkColor: Colors.white,
    );
  }
}

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFFA855F7)]),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: const Color(0xFF6366F1).withValues(alpha: 0.35), blurRadius: 30, spreadRadius: 2)],
      ),
      child: const Icon(Icons.school_rounded, color: Colors.white, size: 36),
    );
  }
}
