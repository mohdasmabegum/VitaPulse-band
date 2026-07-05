import 'package:flutter/material.dart';
import 'theme.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const ResultScreen({super.key, required this.data});

  Color _levelColor(String level) {
    switch (level) {
      case 'low': return Colors.red.shade600;
      case 'borderline': return Colors.orange.shade600;
      default: return kSuccess;
    }
  }

  Color _levelBg(String level) {
    switch (level) {
      case 'low': return Colors.red.shade50;
      case 'borderline': return Colors.orange.shade50;
      default: return Colors.green.shade50;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet    = MediaQuery.of(context).size.width > 600;
    final risks       = List<String>.from(data['risk_summary'] ?? []);
    final nutrients   = List<Map<String, dynamic>>.from(data['nutrient_status'] ?? []);
    final suggestions = List<Map<String, dynamic>>.from(data['food_suggestions'] ?? []);
    final plan        = data['daily_plan'] as Map<String, dynamic>? ?? {};
    final lifestyle   = List<String>.from(data['lifestyle_actions'] ?? []);
    final disclaimer  = data['disclaimer'] ?? '';

    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: kPrimary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Your Recommendation',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimary, kPrimaryMid],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Risk summary
                    if (risks.isNotEmpty) ...[
                      _sectionTitle('⚠️ Risk Summary'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8, runSpacing: 6,
                        children: risks.map((r) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: Colors.red.shade700, borderRadius: BorderRadius.circular(20)),
                          child: Text(r, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500)),
                        )).toList(),
                      ),
                      const SizedBox(height: 20),
                    ],
                    // Nutrient status
                    _sectionTitle('🧪 Nutrient Status'),
                    const SizedBox(height: 8),
                    ...nutrients.map((n) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n['nutrient'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark)),
                            const SizedBox(height: 4),
                            Text(n['note'], style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                            const SizedBox(height: 4),
                            Text('Current: ${n['current_value']} | Target: ≥${n['min_target']}',
                                style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                          ])),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _levelBg(n['level']),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: _levelColor(n['level']).withOpacity(0.3)),
                            ),
                            child: Text(n['level'].toString().toUpperCase(),
                                style: TextStyle(color: _levelColor(n['level']), fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ]),
                      ),
                    )),
                    const SizedBox(height: 12),
                    // Food suggestions
                    _sectionTitle('🥗 Food Suggestions'),
                    const SizedBox(height: 8),
                    ...suggestions.map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(width: 4, height: 20,
                                decoration: BoxDecoration(color: kAccent2, borderRadius: BorderRadius.circular(2))),
                            const SizedBox(width: 8),
                            Expanded(child: Text(s['purpose'],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: kTextDark))),
                          ]),
                          const SizedBox(height: 10),
                          _foodRow('✅ Eat', (s['foods'] as List).join(', '), Colors.green.shade700, Colors.green.shade50),
                          if ((s['avoid_or_limit'] as List?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            _foodRow('🚫 Avoid', (s['avoid_or_limit'] as List).join(', '), Colors.red.shade700, Colors.red.shade50),
                          ],
                        ]),
                      ),
                    )),
                    const SizedBox(height: 12),
                    // Daily plan
                    _sectionTitle('📅 Daily Plan'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(children: [
                          _mealRow('🌅', 'Breakfast', plan['breakfast']),
                          const Divider(height: 16),
                          _mealRow('☀️', 'Lunch', plan['lunch']),
                          const Divider(height: 16),
                          _mealRow('🌙', 'Dinner', plan['dinner']),
                          const Divider(height: 16),
                          _mealRow('🍎', 'Snacks', plan['snacks']),
                        ]),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Lifestyle
                    _sectionTitle('🏃 Lifestyle Actions'),
                    const SizedBox(height: 8),
                    ...lifestyle.map((a) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                      ),
                      child: Row(children: [
                        const Icon(Icons.check_circle, color: kAccent2, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(a, style: const TextStyle(fontSize: 13, color: kTextDark))),
                      ]),
                    )),
                    const SizedBox(height: 16),
                    if (disclaimer.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.amber.shade200),
                        ),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(disclaimer,
                              style: TextStyle(fontSize: 11, color: Colors.amber.shade900))),
                        ]),
                      ),
                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: kPrimary));

  Widget _foodRow(String label, String items, Color textColor, Color bgColor) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: textColor)),
      Expanded(child: Text(items, style: TextStyle(fontSize: 12, color: textColor))),
    ]),
  );

  Widget _mealRow(String emoji, String label, dynamic items) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(emoji, style: const TextStyle(fontSize: 18)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kPrimary)),
        const SizedBox(height: 2),
        Text((items as List?)?.join(', ') ?? '—',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
      ])),
    ],
  );
}
