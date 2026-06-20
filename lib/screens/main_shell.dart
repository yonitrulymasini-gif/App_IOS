import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'dashboard_stats_screen.dart';
import 'community_screen.dart';
import 'scenarios_overview_screen.dart';
import 'profile_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _i = 0;

  static const _pages = [
    HomeScreen(),
    DashboardStatsScreen(),
    CommunityScreen(),
    ScenariosOverviewScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: _TerraNav(current: _i, onTap: (i) => setState(() => _i = i)),
    );
  }
}

class _TerraNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _TerraNav({required this.current, required this.onTap});

  static const _items = [
    (icon: Icons.home_outlined,      label: 'Accueil'),
    (icon: Icons.monitor_heart_outlined, label: 'Mesures'),
    (icon: Icons.people_outline,     label: 'Communauté'),
    (icon: Icons.auto_awesome_outlined, label: 'Scénarios'),
    (icon: Icons.person_outline,     label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xEA0A1A0F),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: T.border),
      ),
      child: Row(
        children: List.generate(_items.length, (i) {
          final sel = current == i;
          final item = _items[i];
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    vertical: 6, horizontal: sel ? 12 : 0),
                decoration: BoxDecoration(
                  color: sel ? T.card2 : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(item.icon,
                        size: 22,
                        color: sel ? T.green : T.textSecondary),
                    const SizedBox(height: 3),
                    Text(item.label,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: sel ? FontWeight.w600 : FontWeight.normal,
                          color: sel ? T.green : T.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
