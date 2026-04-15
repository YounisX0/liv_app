import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/breeding_screen.dart';
import 'screens/cows_screen.dart';
import 'screens/gateway_screen.dart';
import 'screens/login_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_state.dart';
import 'theme/liv_theme.dart';

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
    final state = context.watch<AppState>();
    final locale = state.locale;

    return MaterialApp(
      title: 'LIV Dashboard',
      debugShowCheckedModeBanner: false,
      theme: LivTheme.light,
      locale: Locale(locale.code),
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: [
        AppLocalizationsDelegate(locale),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: locale.isRtl ? TextDirection.rtl : TextDirection.ltr,
          child: child!,
        );
      },
      home: const LaunchGate(),
    );
  }
}

class LaunchGate extends StatelessWidget {
  const LaunchGate({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.isInitializing) {
      return const SplashGateScreen();
    }

    if (!state.isAuthenticated) {
      return const LoginScreen();
    }

    if (state.isAdmin) {
      return const AdminShell();
    }

    return const AppShell();
  }
}

class SplashGateScreen extends StatelessWidget {
  const SplashGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LivTheme.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LivTheme.primary, LivTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Text(
                  'L',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 34,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'LIV Smart Farm',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            const Text(
              'Restoring session...',
              style: TextStyle(color: LivTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    final tabs = const [
      _TabDef(
        label: 'Admin',
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
      ),
      _TabDef(
        label: 'Gateway',
        icon: Icons.router_outlined,
        activeIcon: Icons.router,
      ),
      _TabDef(
        label: 'Settings',
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
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
                child: Text(
                  'A',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ADMIN',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: LivTheme.primary,
                    height: 1.1,
                  ),
                ),
                Text(
                  tabs[_tab].label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LivTheme.muted,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                final next =
                    state.locale == AppLocale.en ? AppLocale.ar : AppLocale.en;
                state.setLocale(next);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: LivTheme.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                  color: LivTheme.primary.withOpacity(0.06),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      state.locale == AppLocale.en ? 'AR' : 'EN',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LivTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
          IconButton(
            tooltip: 'Refresh',
            onPressed: (state.isAdminLoading || state.isFetchingData)
                ? null
                : () => state.refreshLiveData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AppState>().logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: const [
          AdminDashboardScreen(),
          GatewayScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: LivTheme.line,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final t in tabs)
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

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);

    final tabs = [
      _TabDef(
        label: l.t('nav_overview'),
        icon: Icons.dashboard_outlined,
        activeIcon: Icons.dashboard,
      ),
      _TabDef(
        label: l.t('nav_herd'),
        icon: Icons.pets_outlined,
        activeIcon: Icons.pets,
      ),
      _TabDef(
        label: l.t('nav_breeding'),
        icon: Icons.favorite_outline,
        activeIcon: Icons.favorite,
      ),
      _TabDef(
        label: l.t('nav_gateway'),
        icon: Icons.router_outlined,
        activeIcon: Icons.router,
      ),
      _TabDef(
        label: l.t('nav_settings'),
        icon: Icons.settings_outlined,
        activeIcon: Icons.settings,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
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
                child: Text(
                  'L',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LIV',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: LivTheme.primary,
                    height: 1.1,
                  ),
                ),
                Text(
                  tabs[_tab].label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: LivTheme.muted,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: TextButton(
              onPressed: () {
                final next =
                    state.locale == AppLocale.en ? AppLocale.ar : AppLocale.en;
                state.setLocale(next);
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: LivTheme.primary.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(20),
                  color: LivTheme.primary.withOpacity(0.06),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🌐', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      state.locale == AppLocale.en ? 'AR' : 'EN',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: LivTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
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
                  state.useDemoData ? l.t('demo') : l.t('live'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: state.useDemoData ? LivTheme.gold : LivTheme.ok,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: state.isBusy ? null : () => state.refreshLiveData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await context.read<AppState>().logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 4),
        ],
      ),
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
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: LivTheme.line,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          for (final t in tabs)
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

  const _TabDef({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}