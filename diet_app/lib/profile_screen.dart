import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'gamification_screen.dart';
import 'report_screen.dart';
import 'provider_screen.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';
  Map<String, dynamic>? _profile;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? 'User');
    if (ApiService.token != null) {
      try {
        final p = await ApiService.getProfile();
        if (mounted) setState(() => _profile = p);
      } catch (_) {}
    }
  }

  void _showGoalsEditor() {
    if (ApiService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login to set health goals.')));
      return;
    }
    final goals = (_profile?['health_goals'] as Map<String, dynamic>?) ?? {};
    final weightCtrl  = TextEditingController(text: goals['goal_weight_kg']?.toString() ?? '');
    final stepsCtrl   = TextEditingController(text: goals['goal_steps_per_day']?.toString() ?? '');
    final sleepCtrl   = TextEditingController(text: goals['goal_sleep_hours']?.toString() ?? '');
    final fatCtrl     = TextEditingController(text: goals['goal_body_fat_percent']?.toString() ?? '');
    final focusAreas  = List<String>.from(goals['focus_areas'] ?? []);
    final allAreas    = ['weight_loss', 'energy', 'cholesterol', 'sleep', 'muscle_gain', 'immunity'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
        child: StatefulBuilder(builder: (ctx, setS) => SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Health Goals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary)),
          const SizedBox(height: 16),
          _goalField(weightCtrl, 'Target Weight (kg)', Icons.monitor_weight_outlined),
          const SizedBox(height: 10),
          _goalField(stepsCtrl, 'Daily Steps Goal', Icons.directions_walk),
          const SizedBox(height: 10),
          _goalField(sleepCtrl, 'Sleep Goal (hours)', Icons.bedtime_outlined),
          const SizedBox(height: 10),
          _goalField(fatCtrl, 'Body Fat % Goal', Icons.fitness_center),
          const SizedBox(height: 14),
          Align(alignment: Alignment.centerLeft,
              child: Text('Focus Areas', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700))),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 6,
            children: allAreas.map((a) {
              final selected = focusAreas.contains(a);
              return FilterChip(
                label: Text(a.replaceAll('_', ' ')),
                selected: selected,
                onSelected: (v) => setS(() => v ? focusAreas.add(a) : focusAreas.remove(a)),
                selectedColor: kPrimary.withOpacity(0.15),
                checkmarkColor: kPrimary,
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final payload = <String, dynamic>{'focus_areas': focusAreas};
              if (weightCtrl.text.isNotEmpty) payload['goal_weight_kg'] = double.tryParse(weightCtrl.text);
              if (stepsCtrl.text.isNotEmpty)  payload['goal_steps_per_day'] = int.tryParse(stepsCtrl.text);
              if (sleepCtrl.text.isNotEmpty)  payload['goal_sleep_hours'] = double.tryParse(sleepCtrl.text);
              if (fatCtrl.text.isNotEmpty)    payload['goal_body_fat_percent'] = double.tryParse(fatCtrl.text);
              await ApiService.updateGoals(payload);
              _load();
            },
            child: const Text('Save Goals'),
          )),
          const SizedBox(height: 20),
        ]))),
      ),
    );
  }

  Widget _goalField(TextEditingController ctrl, String label, IconData icon) => TextField(
    controller: ctrl,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: kPrimary, size: 20),
      border: const OutlineInputBorder(),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final goals = (_profile?['health_goals'] as Map<String, dynamic>?) ?? {};
    final focusAreas = List<String>.from(goals['focus_areas'] ?? []);

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: isTablet ? 240 : 200,
          pinned: true,
          backgroundColor: kPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                    colors: [kPrimary, kPrimaryMid]),
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const SizedBox(height: 40),
                CircleAvatar(
                  radius: isTablet ? 52 : 40,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: ClipOval(child: Image.asset('assets/logo.png',
                      width: isTablet ? 104 : 80, height: isTablet ? 104 : 80, fit: BoxFit.cover)),
                ),
                const SizedBox(height: 10),
                Text(_username, style: TextStyle(fontSize: isTablet ? 24 : 20, color: Colors.white, fontWeight: FontWeight.w600)),
                if (_profile != null) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('🔥 ${_profile!['streak_days']} day streak', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                  const SizedBox(width: 12),
                  Text('📋 ${_profile!['total_recommendations']} logs', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.85))),
                ]),
              ]),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  // Health Goals card
                  _sectionLabel('Health Goals'),
                  _card([
                    if (goals['goal_weight_kg'] != null)
                      _tile(Icons.monitor_weight_outlined, 'Target Weight', '${goals['goal_weight_kg']} kg'),
                    if (goals['goal_steps_per_day'] != null)
                      _tile(Icons.directions_walk, 'Daily Steps', '${goals['goal_steps_per_day']}'),
                    if (goals['goal_sleep_hours'] != null)
                      _tile(Icons.bedtime_outlined, 'Sleep Goal', '${goals['goal_sleep_hours']} hrs'),
                    if (goals['goal_body_fat_percent'] != null)
                      _tile(Icons.fitness_center, 'Body Fat Goal', '${goals['goal_body_fat_percent']}%'),
                    if (focusAreas.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                        child: Wrap(spacing: 6, runSpacing: 4,
                          children: focusAreas.map((a) => Chip(
                            label: Text(a.replaceAll('_', ' '), style: const TextStyle(fontSize: 11)),
                            backgroundColor: kPrimary.withOpacity(0.08),
                            side: BorderSide.none,
                            padding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ),
                    if (goals.isEmpty)
                      _tile(Icons.flag_outlined, 'No goals set', 'Tap Edit to add your goals'),
                  ]),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _showGoalsEditor,
                      icon: const Icon(Icons.edit, size: 16, color: kPrimary),
                      label: const Text('Edit Goals', style: TextStyle(color: kPrimary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Quick links
                  _sectionLabel('Features'),
                  _card([
                    _navTile(Icons.emoji_events_outlined, 'Achievements & Badges', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationScreen()))),
                    _divider(),
                    _navTile(Icons.picture_as_pdf_outlined, 'Export Health Report', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen()))),
                    _divider(),
                    _navTile(Icons.local_hospital_outlined, 'Find Nearby Providers', () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProviderScreen()))),
                  ]),
                  const SizedBox(height: 16),
                  // Account info
                  _sectionLabel('Account'),
                  _card([
                    _tile(Icons.person, 'Username', _username),
                    _divider(),
                    _tile(Icons.shield, 'Account Type', 'Standard'),
                    _divider(),
                    _tile(Icons.info_outline, 'App Version', '1.0.0'),
                  ]),
                  const SizedBox(height: 24),
                  Text('Not a diagnostic system. Consult a healthcare professional.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Align(alignment: Alignment.centerLeft,
        child: Text(label.toUpperCase(),
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1))),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
    child: Column(children: children),
  );

  Widget _tile(IconData icon, String title, String value) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: kPrimary, size: 20)),
    title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark)),
  );

  Widget _navTile(IconData icon, String title, VoidCallback onTap) => ListTile(
    leading: Container(padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: kPrimary, size: 20)),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark)),
    trailing: const Icon(Icons.chevron_right, color: kAccent2),
    onTap: onTap,
  );

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16);
}
