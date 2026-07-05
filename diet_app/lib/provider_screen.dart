import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'api_service.dart';
import 'theme.dart';

class ProviderScreen extends StatefulWidget {
  const ProviderScreen({super.key});
  @override
  State<ProviderScreen> createState() => _ProviderScreenState();
}

class _ProviderScreenState extends State<ProviderScreen> {
  List<dynamic> _results = [];
  bool _loading = false;
  String _type = 'clinic';
  String? _error;

  Future<void> _search() async {
    setState(() { _loading = true; _error = null; });
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) {
        setState(() { _error = 'Location permission denied. Enable it in settings.'; _loading = false; });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      final results = await ApiService.searchProviders(pos.latitude, pos.longitude, _type, radiusKm: 50);
      setState(() => _results = results);
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
        title: const Text('Find Providers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary, foregroundColor: Colors.white, elevation: 0,
      ),
      body: Column(children: [
        Container(
          color: kPrimary,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _type,
                dropdownColor: Colors.white,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: const [
                  DropdownMenuItem(value: 'clinic',   child: Text('Clinic')),
                  DropdownMenuItem(value: 'lab',      child: Text('Lab / Diagnostics')),
                  DropdownMenuItem(value: 'hospital', child: Text('Hospital')),
                  DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              onPressed: _loading ? null : _search,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Search'),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ]),
        ),
        Expanded(child: _loading
            ? const Center(child: CircularProgressIndicator(color: kAccent2))
            : _error != null
                ? Center(child: Padding(padding: const EdgeInsets.all(24),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red))))
                : _results.isEmpty
                    ? const Center(child: Text('Tap Search to find nearby providers.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _results.length,
                        itemBuilder: (_, i) {
                          final p = _results[i] as Map<String, dynamic>;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(14),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (p['low_cost'] == true ? Colors.green : kPrimary).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_typeIcon(p['type'] ?? ''),
                                    color: p['low_cost'] == true ? Colors.green : kPrimary),
                              ),
                              title: Row(children: [
                                Expanded(child: Text(p['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                                if (p['low_cost'] == true)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.shade200)),
                                    child: Text('Low Cost', style: TextStyle(fontSize: 10, color: Colors.green.shade700)),
                                  ),
                              ]),
                              subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                const SizedBox(height: 4),
                                Text(p['address'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 4),
                                Row(children: [
                                  Icon(Icons.location_on_outlined, size: 12, color: Colors.grey.shade500),
                                  const SizedBox(width: 4),
                                  Text('${p['distance_km']} km away', style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  if (p['phone'] != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(Icons.phone_outlined, size: 12, color: Colors.grey.shade500),
                                    const SizedBox(width: 4),
                                    Text(p['phone'], style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                                  ],
                                ]),
                              ]),
                              trailing: IconButton(
                                icon: const Icon(Icons.map_outlined, color: kPrimary),
                                onPressed: () async {
                                  final url = Uri.parse(p['maps_url'] ?? '');
                                  if (await canLaunchUrl(url)) launchUrl(url, mode: LaunchMode.externalApplication);
                                },
                              ),
                            ),
                          );
                        },
                      )),
      ]),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'lab':      return Icons.biotech_outlined;
      case 'hospital': return Icons.local_hospital_outlined;
      case 'pharmacy': return Icons.local_pharmacy_outlined;
      default:         return Icons.medical_services_outlined;
    }
  }
}
