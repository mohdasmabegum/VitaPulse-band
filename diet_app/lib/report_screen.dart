import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'api_service.dart';
import 'theme.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  bool _loading = false;
  String? _savedPath;
  String? _error;
  int _limit = 5;

  Future<void> _download() async {
    if (ApiService.token == null) {
      setState(() => _error = 'Login required to download your report.');
      return;
    }
    setState(() { _loading = true; _error = null; _savedPath = null; });
    try {
      final bytes = await ApiService.downloadReport(limit: _limit);
      final dir  = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/vitapulse_report.pdf');
      await file.writeAsBytes(bytes);
      setState(() => _savedPath = file.path);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Export Report', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.picture_as_pdf, size: 56, color: kPrimary),
            ),
            const SizedBox(height: 24),
            const Text('Health Report PDF', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: kPrimary)),
            const SizedBox(height: 10),
            Text(
              'Export a summary of your health trends, nutrient status, and lifestyle actions to share with your doctor.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.5),
            ),
            const SizedBox(height: 28),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Text('Include last ', style: TextStyle(fontSize: 14)),
              DropdownButton<int>(
                value: _limit,
                items: [3, 5, 10, 20].map((n) => DropdownMenuItem(value: n, child: Text('$n'))).toList(),
                onChanged: (v) => setState(() => _limit = v!),
              ),
              const Text(' recommendations', style: TextStyle(fontSize: 14)),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _download,
                icon: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download),
                label: Text(_loading ? 'Generating…' : 'Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            if (_savedPath != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200)),
                child: Row(children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Report saved!', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                    Text(_savedPath!, style: TextStyle(fontSize: 11, color: Colors.green.shade600), overflow: TextOverflow.ellipsis),
                  ])),
                ]),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13), textAlign: TextAlign.center),
            ],
            const SizedBox(height: 24),
            Text(
              'Not a diagnostic document. Always consult a healthcare professional.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ]),
        ),
      ),
    );
  }
}
