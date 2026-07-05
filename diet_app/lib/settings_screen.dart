import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'landing_screen.dart';
import 'theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? 'Guest');
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(color: kPrimary, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: kError),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    ApiService.clearToken();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Profile header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [kPrimary, kPrimaryMid]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: ClipOval(child: Image.asset('assets/logo.png', width: 60, height: 60, fit: BoxFit.cover)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_username, style: const TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      Text('VitaPulse Member', style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
              // Account section
              _sectionLabel('Account'),
              _card([
                _tile(Icons.person_outline, 'Username', _username),
                _divider(),
                _tile(Icons.shield_outlined, 'Account Type', 'Standard'),
              ]),
              const SizedBox(height: 16),
              // App section
              _sectionLabel('App Info'),
              _card([
                _tile(Icons.info_outline, 'Version', '1.0.0'),
                _divider(),
                _tile(Icons.medical_services_outlined, 'Engine', 'Rule-based Diet Engine'),
                _divider(),
                _tile(Icons.cloud_outlined, 'Backend', 'vitapulse-band.web.app'),
              ]),
              const SizedBox(height: 16),
              // Logout
              _sectionLabel('Session'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.shade100),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.logout, color: Colors.red.shade700, size: 20),
                  ),
                  title: Text('Logout', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                  subtitle: Text('Sign out of your account', style: TextStyle(color: Colors.red.shade400, fontSize: 12)),
                  trailing: Icon(Icons.chevron_right, color: Colors.red.shade400),
                  onTap: _logout,
                ),
              ),
              const SizedBox(height: 32),
              Text('Not a diagnostic system. Consult a healthcare professional.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey.shade500, letterSpacing: 1)),
  );

  Widget _card(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
    ),
    child: Column(children: children),
  );

  Widget _tile(IconData icon, String title, String value) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: kPrimary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: kPrimary, size: 20),
    ),
    title: Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
    subtitle: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTextDark)),
  );

  Widget _divider() => const Divider(height: 1, indent: 56, endIndent: 16);
}
