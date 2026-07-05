import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'api_service.dart';
import 'theme.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});
  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _weightCtrl   = TextEditingController();
  final _stepsCtrl    = TextEditingController();
  final _sleepCtrl    = TextEditingController();
  final _fatCtrl      = TextEditingController();
  final _focusCtrl    = TextEditingController();
  bool _saving = false, _exporting = false;
  String _msg = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (ApiService.token == null) return;
    try {
      final p = await ApiService.getProfile();
      final g = p['health_goals'] as Map? ?? {};
      if (g['goal_weight_kg'] != null)        _weightCtrl.text = '${g['goal_weight_kg']}';
      if (g['goal_steps_per_day'] != null)    _stepsCtrl.text  = '${g['goal_steps_per_day']}';
      if (g['goal_sleep_hours'] != null)      _sleepCtrl.text  = '${g['goal_sleep_hours']}';
      if (g['goal_body_fat_percent'] != null) _fatCtrl.text    = '${g['goal_body_fat_percent']}';
      if ((g['focus_areas'] as List?)?.isNotEmpty == true)
        _focusCtrl.text = (g['focus_areas'] as List).join(', ');
      setState(() {});
    } catch (_) {}
  }

  Future<void> _save() async {
    if (ApiService.token == null) { setState(() => _msg = 'Login to save goals.'); return; }
    setState(() { _saving = true; _msg = ''; });
    final payload = <String, dynamic>{};
    if (_weightCtrl.text.isNotEmpty) payload['goal_weight_kg'] = double.tryParse(_weightCtrl.text);
    if (_stepsCtrl.text.isNotEmpty)  payload['goal_steps_per_day'] = int.tryParse(_stepsCtrl.text);
    if (_sleepCtrl.text.isNotEmpty)  payload['goal_sleep_hours'] = double.tryParse(_sleepCtrl.text);
    if (_fatCtrl.text.isNotEmpty)    payload['goal_body_fat_percent'] = double.tryParse(_fatCtrl.text);
    payload['focus_areas'] = _focusCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    try {
      await ApiService.updateGoals(payload);
      setState(() => _msg = '✓ Goals saved!');
    } catch (e) {
      setState(() => _msg = e.toString());
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _exportPdf() async {
    if (ApiService.token == null) { setState(() => _msg = 'Login to export PDF.'); return; }
    setState(() { _exporting = true; _msg = ''; });
    try {
      final bytes = await ApiService.downloadPdfReport();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/vitapulse_report.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      setState(() => _msg = 'PDF export failed: $e');
    } finally {
      setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('🎯 Health Goals'), backgroundColor: kPrimary, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            const Align(alignment: Alignment.centerLeft, child: Text('Personalise Your Goals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
            const SizedBox(height: 12),
            _field(_weightCtrl, 'Goal Weight (kg)', TextInputType.number),
            _field(_stepsCtrl, 'Goal Steps / Day', TextInputType.number),
            _field(_sleepCtrl, 'Goal Sleep Hours', TextInputType.number),
            _field(_fatCtrl, 'Goal Body Fat %', TextInputType.number),
            _field(_focusCtrl, 'Focus Areas (e.g. weight_loss, energy)', TextInputType.text),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
              child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('💾 Save Goals'),
            ),
            if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_msg, style: TextStyle(color: _msg.startsWith('✓') ? Colors.green : Colors.red))),
          ]))),
          const SizedBox(height: 16),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('📄 Export PDF Report', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 6),
            const Text('Download a summary of your health trends to share with your doctor.', style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _exporting ? null : _exportPdf,
              icon: _exporting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.download),
              label: const Text('Download PDF Report'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
            ),
          ]))),
        ]),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, TextInputType type) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: TextField(controller: ctrl, keyboardType: type, decoration: InputDecoration(labelText: label, border: const OutlineInputBorder())),
  );
}
