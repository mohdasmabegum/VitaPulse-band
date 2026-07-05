import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'symptom_screen.dart';
import 'recommend_screen.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'theme.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with SingleTickerProviderStateMixin {
  int _index = 0;
  late AnimationController _navCtrl;

  final _screens = const [
    SymptomScreen(),
    RecommendScreen(),
    HistoryScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 280));
    _navCtrl.forward();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final prefs = await SharedPreferences.getInstance();
    ApiService.setUsername(prefs.getString('username') ?? '');
  }

  @override
  void dispose() { _navCtrl.dispose(); super.dispose(); }

  void _onTap(int i) {
    if (i == _index) return;
    _navCtrl.reset();
    setState(() => _index = i);
    _navCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;

    if (isTablet) {
      // Side navigation rail for tablets
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              onDestinationSelected: _onTap,
              backgroundColor: kPrimary,
              selectedIconTheme: const IconThemeData(color: kAccent),
              unselectedIconTheme: IconThemeData(color: Colors.white.withOpacity(0.6)),
              selectedLabelTextStyle: const TextStyle(color: kAccent, fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelTextStyle: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ClipOval(child: Image.asset('assets/logo.png', width: 44, height: 44, fit: BoxFit.cover)),
              ),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety), label: Text('Symptoms')),
                NavigationRailDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu), label: Text('Recommend')),
                NavigationRailDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: Text('History')),
                NavigationRailDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: Text('Settings')),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: FadeTransition(opacity: _navCtrl, child: _screens[_index]),
            ),
          ],
        ),
      );
    }

    // Bottom nav for phones
    return Scaffold(
      body: FadeTransition(opacity: _navCtrl, child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        backgroundColor: Colors.white,
        indicatorColor: kAccent2.withOpacity(0.18),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.health_and_safety_outlined),
            selectedIcon: Icon(Icons.health_and_safety, color: kAccent2),
            label: 'Symptoms',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: kAccent2),
            label: 'Recommend',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history, color: kAccent2),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings, color: kAccent2),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
