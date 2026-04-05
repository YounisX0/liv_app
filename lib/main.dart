import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/app_state.dart';
import 'theme/liv_theme.dart';
import 'screens/overview_screen.dart';
import 'screens/cows_screen.dart';
import 'screens/breeding_screen.dart';
import 'screens/gateway_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const LivApp(),
    ),
  );
}

class LivApp extends StatelessWidget {
  const LivApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LIV Dashboard',
      debugShowCheckedModeBanner: false,
      theme: LivTheme.light,
      home: const AppShell(),
    );
  }
}

// ── App shell with bottom navigation ─────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  // Tab definitions
  static const _tabs = [
    _TabDef(label: 'Overview',  icon: Icons.dashboard_outlined,     activeIcon: Icons.dashboard),
    _TabDef(label: 'Herd',      icon: Icons.pets_outlined,          activeIcon: Icons.pets),
    _TabDef(label: 'Breeding',  icon: Icons.favorite_outline,       activeIcon: Icons.favorite),
    _TabDef(label: 'Gateway',   icon: Icons.router_outlined,        activeIcon: Icons.router),
    _TabDef(label: 'Settings',  icon: Icons.settings_outlined,      activeIcon: Icons.settings),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      // ── Top app bar ──────────────────────────────────────────────────────
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            // LIV logo mark
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LivTheme.primary, LivTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Center(
                child: Text('L',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('LIV',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: LivTheme.primary,
                        height: 1.1)),
                Text(_tabs[_tab].label,
                    style: const TextStyle(
                        fontSize: 11, color: LivTheme.muted, fontWeight: FontWeight.w400, height: 1)),
              ],
            ),
          ],
        ),
        actions: [
          // Connection indicator
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.connected ? LivTheme.ok : LivTheme.gold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  state.useDemoData ? 'Demo' : 'Live',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.useDemoData ? LivTheme.gold : LivTheme.ok,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // ── Body ────────────────────────────────────────────────────────────
      body: IndexedStack(
        index: _tab,
        children: const [
          OverviewScreen(),
          CowsScreen(),
          BreedingScreen(),
          GatewayScreen(),
          SettingsScreen(),
        ],
      ),

      // ── Bottom nav ───────────────────────────────────────────────────────
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: LivTheme.line,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.activeIcon, color: LivTheme.primary),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _TabDef({required this.label, required this.icon, required this.activeIcon});
}
