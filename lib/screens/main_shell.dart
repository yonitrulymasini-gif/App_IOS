import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'home_screen.dart';
import 'dashboard_stats_screen.dart';
import 'scenarios_overview_screen.dart';
import 'community_screen.dart';
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
    ScenariosOverviewScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _i, children: _pages),
      bottomNavigationBar: _NavBar(current: _i, onTap: (i) => setState(() => _i = i)),
    );
  }
}

class _NavBar extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _NavBar({required this.current, required this.onTap});

  static const _tabs = [
    (icon: Icons.home_outlined,       iconSel: Icons.home_rounded,           label: 'Accueil'),
    (icon: Icons.bar_chart_outlined,  iconSel: Icons.bar_chart_rounded,      label: 'Dashboard'),
    (icon: Icons.bolt_outlined,       iconSel: Icons.bolt_rounded,           label: 'Scénarios'),
    (icon: Icons.people_outline,      iconSel: Icons.people_rounded,         label: 'Communauté'),
    (icon: Icons.person_outline,      iconSel: Icons.person_rounded,         label: 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: T.surface,
        border: Border(top: BorderSide(color: T.border, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 52,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final sel = current == i;
              final tab = _tabs[i];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: sel ? 1.0 : 0.45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          sel ? tab.iconSel : tab.icon,
                          size: 22,
                          color: sel ? T.green : T.textSecondary,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
                            color: sel ? T.green : T.textSecondary,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
