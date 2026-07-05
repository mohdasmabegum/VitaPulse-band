import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'theme.dart';

class ProvidersScreen extends StatefulWidget {
  const ProvidersScreen({super.key});
  @override
  State<ProvidersScreen> createState() => _ProvidersScreenState();
}

class _ProvidersScreenState extends State<ProvidersScreen> {
  final _latCtrl    = TextEditingController();
  final _lonCtrl    = TextEditingController();
  final _radiusCtrl = TextEditingController(text: '50');
  String _type = 'lab';
  List _results = [];
  bool _loading = false;
  String _msg = '';

  Future<void> _search() async {
    final lat = double.tryParse(_latCtrl.text);
    final lon = double.tryParse(_lonCtrl.text);
    final radius = double.tryParse(_radiusCtrl.text) ?? 50;
    if (lat == null || lon == null) { setState(() => _msg = 'Enter valid coordinates.'); return; }
    setState(() { _loading = true; _msg = ''; });
    try {
      final r = await ApiService.searchProviders(lat, lon, radius, _type);
      setState(() { _results = r; _loading = false; if (r.isEmpty) _msg = 'No providers found. Try a larger radius.'; });
    } catch (e) {
      setState(() { _loading = false; _msg = e.toString(); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(title: const Text('🏥 Find Providers'), backgroundColor: kPrimary, foregroundColor: Colors.white),
      body: Column(children: [
        Card(
          margin: const EdgeInsets.all(12),
          child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
            Row(children: [
              Expanded(child: TextField(controller: _latCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Latitude', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: TextField(controller: _lonCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Longitude', border: OutlineInputBorder()))),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: _radiusCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Radius (km)', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              Expanded(child: DropdownButtonFormField<String>(
                value: _type,
                items: ['lab','clinic','hospital','pharmacy'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setState(() => _type = v!),
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
              )),
            ]),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.search),
              label: const Text('Search Providers'),
              style: ElevatedButton.styleFrom(backgroundColor: kPrimary, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(44)),
            ),
            if (_msg.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(_msg, style: const TextStyle(color: Colors.grey))),
          ])),
        ),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _results.length,
              itemBuilder: (_, i) {
                final p = _results[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(_typeIcon(p['type']), color: kPrimary, size: 28),
                    title: Row(children: [
                      Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (p['low_cost'] == true) const Chip(label: Text('Low Cost', style: TextStyle(fontSize: 10)), backgroundColor: Color(0xFFE8F5E9)),
                    ]),
                    subtitle: Text('${p['address']}\n${p['distance_km']} km away${p['phone'] != null ? ' · ${p['phone']}' : ''}'),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.map_outlined, color: kPrimary),
                      onPressed: () => launchUrl(Uri.parse(p['maps_url']), mode: LaunchMode.externalApplication),
                    ),
                  ),
                );
              },
            ),
        ),
      ]),
    );
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'lab': return Icons.biotech_outlined;
      case 'hospital': return Icons.local_hospital_outlined;
      case 'pharmacy': return Icons.local_pharmacy_outlined;
      default: return Icons.medical_services_outlined;
    }
  }
}
