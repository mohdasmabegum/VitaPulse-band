import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'api_service.dart';
import 'result_screen.dart';
import 'theme.dart';

class RecommendScreen extends StatefulWidget {
  const RecommendScreen({super.key});
  @override
  State<RecommendScreen> createState() => _RecommendScreenState();
}

class _RecommendScreenState extends State<RecommendScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  bool _uploading = false;
  String? _error;
  String? _uploadMsg;

  // Picked file
  PlatformFile? _pickedFile;

  final _age      = TextEditingController(text: '30');
  String _sex     = 'male';
  String _diet    = 'omnivore';
  final _allergies = TextEditingController();
  final _vitD     = TextEditingController(text: '18');
  final _vitB12   = TextEditingController(text: '250');
  final _iron     = TextEditingController(text: '28');
  final _ldl      = TextEditingController(text: '140');
  final _hdl      = TextEditingController(text: '39');
  final _tg       = TextEditingController(text: '180');
  final _height   = TextEditingController(text: '170');
  final _weight   = TextEditingController(text: '75');
  final _fat      = TextEditingController(text: '28');
  final _steps    = TextEditingController(text: '6000');
  final _sleep    = TextEditingController(text: '7');
  final _workouts = TextEditingController(text: '2');

  static const int _maxBytes = 5 * 1024 * 1024; // 5 MB

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    if ((file.size) > _maxBytes) {
      setState(() {
        _pickedFile = null;
        _uploadMsg = '❌ File too large. Maximum allowed size is 5 MB.';
      });
      return;
    }
    setState(() {
      _pickedFile = file;
      _uploadMsg = null;
      _error = null;
    });
  }

  Future<void> _uploadReport() async {
    if (_pickedFile == null) return;
    setState(() { _uploading = true; _uploadMsg = null; });
    try {
      final msg = await ApiService.uploadReport(_pickedFile!);
      setState(() => _uploadMsg = '✅ $msg');
    } catch (e) {
      setState(() => _uploadMsg = '❌ ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      setState(() => _uploading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final payload = {
        'age': int.parse(_age.text),
        'sex': _sex,
        'diet_type': _diet,
        'allergies': _allergies.text.isEmpty ? [] : _allergies.text.split(',').map((s) => s.trim()).toList(),
        'biomarkers': {
          'vitamin_d_ng_ml': double.parse(_vitD.text),
          'vitamin_b12_pg_ml': double.parse(_vitB12.text),
          'iron_ferritin_ng_ml': double.parse(_iron.text),
          'ldl_mg_dl': double.parse(_ldl.text),
          'hdl_mg_dl': double.parse(_hdl.text),
          'triglycerides_mg_dl': double.parse(_tg.text),
        },
        'body_metrics': {
          'height_cm': double.parse(_height.text),
          'weight_kg': double.parse(_weight.text),
          'body_fat_percent': double.parse(_fat.text),
        },
        'lifestyle': {
          'avg_daily_steps': int.parse(_steps.text),
          'avg_sleep_hours': double.parse(_sleep.text),
          'weekly_workouts': int.parse(_workouts.text),
        },
      };
      final result = await ApiService.recommend(payload);
      if (mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(data: result)));
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
        title: const Text('Diet Recommendation', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 700 : double.infinity),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Medical Report Upload ──────────────────────────────
                _sectionCard('📄 Medical Report (Optional)', [
                  Text('Upload a lab report (PDF, JPG, PNG — max 5 MB) to help pre-fill your biomarkers.',
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                  const SizedBox(height: 14),
                  // File picker row
                  Row(children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF6FBF6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _pickedFile != null ? kAccent2 : const Color(0xFFCDE8CD),
                              width: _pickedFile != null ? 2 : 1,
                            ),
                          ),
                          child: Row(children: [
                            Icon(Icons.attach_file, color: _pickedFile != null ? kAccent2 : Colors.grey.shade500, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _pickedFile != null ? _pickedFile!.name : 'Tap to choose file…',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _pickedFile != null ? kTextDark : Colors.grey.shade500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (_pickedFile != null)
                              GestureDetector(
                                onTap: () => setState(() { _pickedFile = null; _uploadMsg = null; }),
                                child: Icon(Icons.close, size: 18, color: Colors.grey.shade500),
                              ),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: (_pickedFile == null || _uploading) ? null : _uploadReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccent2,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        child: _uploading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Text('Upload', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ]),
                  if (_pickedFile != null) ...[
                    const SizedBox(height: 6),
                    Text('Size: ${(_pickedFile!.size / 1024).toStringAsFixed(1)} KB',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ],
                  if (_uploadMsg != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _uploadMsg!.startsWith('✅') ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _uploadMsg!.startsWith('✅') ? Colors.green.shade200 : Colors.red.shade200,
                        ),
                      ),
                      child: Text(_uploadMsg!, style: TextStyle(
                        fontSize: 13,
                        color: _uploadMsg!.startsWith('✅') ? Colors.green.shade800 : Colors.red.shade700,
                      )),
                    ),
                  ],
                ]),
                // ── Basic Info ─────────────────────────────────────────
                _sectionCard('👤 Basic Info', [
                  _field('Age', _age),
                  _dropdown('Sex', _sex, ['male', 'female', 'other'], (v) => setState(() => _sex = v!)),
                  _dropdown('Diet Type', _diet, ['omnivore', 'vegetarian'], (v) => setState(() => _diet = v!)),
                  _field('Allergies (comma-separated)', _allergies, required: false, keyboard: TextInputType.text),
                ]),
                // ── Biomarkers ─────────────────────────────────────────
                _sectionCard('🧪 Biomarkers', [
                  _field('Vitamin D (ng/mL)', _vitD),
                  _field('Vitamin B12 (pg/mL)', _vitB12),
                  _field('Iron / Ferritin (ng/mL)', _iron),
                  _field('LDL (mg/dL)', _ldl),
                  _field('HDL (mg/dL)', _hdl),
                  _field('Triglycerides (mg/dL)', _tg),
                ]),
                // ── Body Metrics ───────────────────────────────────────
                _sectionCard('⚖️ Body Metrics', [
                  _field('Height (cm)', _height),
                  _field('Weight (kg)', _weight),
                  _field('Body Fat %', _fat),
                ]),
                // ── Lifestyle ─────────────────────────────────────────
                _sectionCard('🏃 Lifestyle', [
                  _field('Avg Daily Steps', _steps),
                  _field('Avg Sleep Hours', _sleep),
                  _field('Weekly Workouts', _workouts),
                ]),
                if (_error != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.red.shade200)),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13))),
                    ]),
                  ),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Get My Recommendation', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget> fields) => Container(
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: kPrimary)),
        const SizedBox(height: 14),
        ...fields,
      ]),
    ),
  );

  Widget _field(String label, TextEditingController ctrl, {bool required = true, TextInputType keyboard = TextInputType.number}) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6FBF6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent2, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: required ? (v) => (v == null || v.isEmpty) ? 'Required' : null : null,
    ),
  );

  Widget _dropdown(String label, String value, List<String> items, void Function(String?) onChanged) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF6FBF6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCDE8CD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent2, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: onChanged,
    ),
  );
}
