import 'package:flutter/material.dart';
import 'api_service.dart';
import 'theme.dart';

class SymptomScreen extends StatefulWidget {
  const SymptomScreen({super.key});
  @override
  State<SymptomScreen> createState() => _SymptomScreenState();
}

class _SymptomScreenState extends State<SymptomScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<String> _symptoms = [];
  final Map<String, bool> _answers = {};
  List<String> _followUps = [];
  List<Map<String, dynamic>> _insights = [];
  String? _disclaimer;
  bool _loading = false;
  String? _error;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final input = _ctrl.text.trim();
    if (input.isNotEmpty) {
      setState(() => _symptoms.add(input));
      _ctrl.clear();
    }
    if (_symptoms.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService.symptomCheck(_symptoms, _answers);
      setState(() {
        _insights = List<Map<String, dynamic>>.from(res['insights'] ?? []);
        _followUps = List<String>.from(res['follow_up_questions'] ?? []);
        _disclaimer = res['disclaimer'];
      });
      await Future.delayed(const Duration(milliseconds: 100));
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 400), curve: Curves.easeOut);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  void _answerFollowUp(String q, bool answer) {
    setState(() => _answers[q] = answer);
    _submit();
  }

  Color _confidenceColor(double c) {
    if (c >= 0.7) return Colors.red.shade600;
    if (c >= 0.4) return Colors.orange.shade600;
    return Colors.green.shade600;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Symptom Checker', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            color: kPrimary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: 1.0 + 0.1 * _pulseCtrl.value,
                    child: const Icon(Icons.health_and_safety, color: Colors.white, size: 28),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Text('Describe your symptoms and get preliminary insights',
                    style: TextStyle(color: Colors.white, fontSize: 13))),
              ]),
            ),
          ),
          Expanded(
            child: ListView(
              controller: _scrollCtrl,
              padding: const EdgeInsets.all(16),
              children: [
                if (_symptoms.isNotEmpty) ...[
                  const Text('Your symptoms:', style: TextStyle(fontWeight: FontWeight.w600, color: kPrimary)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: _symptoms.map((s) => Chip(
                      label: Text(s),
                      backgroundColor: kAccent2.withOpacity(0.1),
                      labelStyle: const TextStyle(color: kPrimary),
                      deleteIconColor: kAccent2,
                      onDeleted: () => setState(() => _symptoms.remove(s)),
                    )).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_loading)
                  const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: kAccent2))),
                if (_error != null)
                  _errorBox(_error!),
                if (_insights.isNotEmpty) ...[
                  _sectionHeader('Preliminary Insights', Icons.insights),
                  const SizedBox(height: 8),
                  ..._insights.map((i) => _insightCard(i)),
                ],
                if (_followUps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _sectionHeader('Follow-up Questions', Icons.quiz_outlined),
                  const SizedBox(height: 8),
                  ..._followUps.where((q) => !_answers.containsKey(q)).map((q) => _followUpCard(q)),
                ],
                if (_disclaimer != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.amber.shade200)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.warning_amber, color: Colors.amber.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_disclaimer!, style: TextStyle(fontSize: 11, color: Colors.amber.shade900))),
                    ]),
                  ),
                ],
                const SizedBox(height: 80),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, -2))],
            ),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  decoration: InputDecoration(
                    hintText: 'e.g. fatigue, bone pain...',
                    filled: true,
                    fillColor: const Color(0xFFF1F8F1),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 10),
              FloatingActionButton(
                onPressed: _submit,
                backgroundColor: kPrimary,
                mini: true,
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Icon(icon, color: kAccent2, size: 18),
    const SizedBox(width: 8),
    Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimary)),
  ]);

  Widget _insightCard(Map<String, dynamic> i) {
    final conf = (i['confidence'] as num).toDouble();
    final color = _confidenceColor(conf);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('${(conf * 100).round()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        title: Text(i['deficiency'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Padding(padding: const EdgeInsets.only(top: 4), child: Text(i['insight'], style: const TextStyle(fontSize: 13))),
      ),
    );
  }

  Widget _followUpCard(String q) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(q, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _answerFollowUp(q, true),
            style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Yes'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _answerFollowUp(q, false),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: kAccent2), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('No', style: TextStyle(color: kAccent2)),
          ),
        ),
      ]),
    ]),
  );

  Widget _errorBox(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
    child: Row(children: [
      Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
      const SizedBox(width: 8),
      Expanded(child: Text(msg, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
    ]),
  );
}
