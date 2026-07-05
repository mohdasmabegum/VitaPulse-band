import 'package:flutter/material.dart';
import 'api_service.dart';
import 'result_screen.dart';
import 'theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<dynamic> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (ApiService.token == null) return;
    setState(() { _loading = true; _error = null; });
    try {
      final items = await ApiService.history();
      setState(() => _items = items);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load, tooltip: 'Refresh'),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
          child: ApiService.token == null
              ? _emptyState(Icons.lock_outline, 'Login to view history', 'Your saved recommendations will appear here')
              : _loading
                  ? const Center(child: CircularProgressIndicator(color: kAccent2))
                  : _error != null
                      ? _emptyState(Icons.error_outline, 'Something went wrong', _error!)
                      : _items.isEmpty
                          ? _emptyState(Icons.history, 'No history yet', 'Submit a recommendation to see it here')
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _items.length,
                              itemBuilder: (_, i) {
                                final item = _items[i] as Map<String, dynamic>;
                                final rec = item['recommendation'] as Map<String, dynamic>;
                                final risks = List<String>.from(rec['risk_summary'] ?? []);
                                final nutrients = List<dynamic>.from(rec['nutrient_status'] ?? []);
                                final date = item['created_at'].toString();
                                return GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(data: rec))),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                        Row(children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                                            child: const Icon(Icons.restaurant_menu, color: kPrimary, size: 20),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                              Text('Recommendation #${item['id']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                              Text(date.length > 16 ? date.substring(0, 16) : date,
                                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                            ]),
                                          ),
                                          const Icon(Icons.chevron_right, color: kAccent2),
                                        ]),
                                        if (risks.isNotEmpty) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 4,
                                            children: risks.take(3).map((r) => Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                                              child: Text(r, style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                                            )).toList(),
                                          ),
                                        ],
                                        if (nutrients.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          Text('${nutrients.length} nutrients tracked',
                                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        ],
                                      ]),
                                    ),
                                  ),
                                );
                              },
                            ),
        ),
      ),
    );
  }

  Widget _emptyState(IconData icon, String title, String subtitle) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 64, color: Colors.grey.shade400),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimary)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
      ]),
    ),
  );
}
