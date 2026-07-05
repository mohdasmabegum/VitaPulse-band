import 'package:flutter/material.dart';
import 'symptom_screen.dart';
import 'recommend_screen.dart';
import 'history_screen.dart';
import 'profile_screen.dart';
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
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _navCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _navCtrl.forward();
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
    return Scaffold(
      body: FadeTransition(opacity: _navCtrl, child: _screens[_index]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onTap,
        backgroundColor: kCard,
        indicatorColor: kAccent.withOpacity(0.2),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.health_and_safety_outlined), selectedIcon: Icon(Icons.health_and_safety, color: kPrimary), label: 'Symptoms'),
          NavigationDestination(icon: Icon(Icons.restaurant_menu_outlined), selectedIcon: Icon(Icons.restaurant_menu, color: kPrimary), label: 'Recommend'),
          NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history, color: kPrimary), label: 'History'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: kPrimary), label: 'Profile'),
        ],
      ),
    );
  }
}
