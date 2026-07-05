import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _username = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _username = prefs.getString('username') ?? 'User');
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    return Scaffold(
      backgroundColor: kBg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: isTablet ? 240 : 200,
            pinned: true,
            backgroundColor: kPrimary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [kPrimary, kPrimaryMid],
                  ),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 40),
                  CircleAvatar(
                    radius: isTablet ? 52 : 40,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: ClipOval(
                      child: Image.asset('assets/logo.png', width: isTablet ? 104 : 80, height: isTablet ? 104 : 80, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(_username, style: TextStyle(fontSize: isTablet ? 24 : 20, color: Colors.white, fontWeight: FontWeight.w600)),
                  Text('VitaPulse Member', style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8))),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isTablet ? 600 : double.infinity),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(children: [
                    _card([
                      _tile(Icons.person, 'Username', _username),
                      _divider(),
                      _tile(Icons.shield, 'Account Type', 'Standard'),
                    ]),
                    const SizedBox(height: 16),
                    _card([
                      _tile(Icons.info_outline, 'App Version', '1.0.0'),
                      _divider(),
                      _tile(Icons.medical_services_outlined, 'System', 'Rule-based Diet Engine'),
                      _divider(),
                      _tile(Icons.cloud_outlined, 'Backend', 'vitapulse-band.web.app'),
                    ]),
                    const SizedBox(height: 24),
                    Text('Not a diagnostic system. Consult a healthcare professional.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

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
