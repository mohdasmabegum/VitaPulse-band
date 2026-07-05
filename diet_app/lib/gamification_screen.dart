import 'package:flutter/material.dart';
import 'api_service.dart';
import 'theme.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});
  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> {
  Map<String, dynamic>? _data;
  bool _loading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (ApiService.token == null) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.getGamification();
      setState(() => _data = data);
    } catch (_) {} finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _load)],
      ),
      body: ApiService.token == null
          ? const Center(child: Text('Login to view your achievements.'))
          : _loading
              ? const Center(child: CircularProgressIndicator(color: kAccent2))
              : _data == null
                  ? const Center(child: Text('Could not load achievements.'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(children: [
                        // Streak & count cards
                        Row(children: [
                          Expanded(child: _statCard('🔥', '${_data!['streak_days']}', 'Day Streak', Colors.orange)),
                          const SizedBox(width: 12),
                          Expanded(child: _statCard('📋', '${_data!['total_recommendations']}', 'Total Logs', kPrimary)),
                        ]),
                        const SizedBox(height: 24),
                        // Earned badges
                        Align(alignment: Alignment.centerLeft,
                            child: Text('Earned Badges', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary))),
                        const SizedBox(height: 12),
                        if ((_data!['badges'] as List).isEmpty)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: const Center(child: Text('No badges yet. Keep logging!', style: TextStyle(color: Colors.grey))),
                          )
                        else
                          Wrap(spacing: 12, runSpacing: 12,
                            children: (_data!['badges'] as List).map((b) => _badgeCard(b as Map<String, dynamic>, earned: true)).toList()),
                        // Next badge
                        if (_data!['next_badge'] != null) ...[
                          const SizedBox(height: 24),
                          Align(alignment: Alignment.centerLeft,
                              child: Text('Next Badge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary))),
                          const SizedBox(height: 12),
                          _badgeCard(_data!['next_badge'] as Map<String, dynamic>, earned: false),
                        ],
                      ]),
                    ),
    );
  }

  Widget _statCard(String emoji, String value, String label, Color color) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 28)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    ]),
  );

  Widget _badgeCard(Map<String, dynamic> badge, {required bool earned}) => Container(
    width: 140,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: earned ? Colors.white : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: earned ? kAccent.withOpacity(0.4) : Colors.grey.shade300),
      boxShadow: earned ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)] : [],
    ),
    child: Column(children: [
      Text(badge['icon'] ?? '🏅', style: TextStyle(fontSize: 32, color: earned ? null : Colors.grey.withOpacity(0.5))),
      const SizedBox(height: 8),
      Text(badge['name'] ?? '', textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: earned ? kPrimary : Colors.grey)),
      const SizedBox(height: 4),
      Text(badge['description'] ?? '', textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      if (!earned) ...[
        const SizedBox(height: 6),
        Text('Locked', style: TextStyle(fontSize: 10, color: Colors.grey.shade400, fontStyle: FontStyle.italic)),
      ],
    ]),
  );
}
