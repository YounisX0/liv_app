import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // App will still run, but backend URL may be empty if .env is missing.
  }

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
    final l = AppLocalizations(locale);

    return MaterialApp(
      title: l.t('app_name'),
      debugShowCheckedModeBanner: false,
      theme: LivTheme.light,
      darkTheme: LivTheme.dark,
      themeMode: state.themeMode,
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
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _BrandMark(size: 120),
            const SizedBox(height: 22),
            Text(
              l.t('brand_title'),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            const CircularProgressIndicator(),
            const SizedBox(height: 14),
            Text(
              l.t('restoring_session'),
              style: const TextStyle(color: LivTheme.muted),
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
    final l = AppLocalizations(state.locale);

    final tabs = [
      _TabDef(
        label: l.t('admin_panel'),
        icon: Icons.admin_panel_settings_outlined,
        activeIcon: Icons.admin_panel_settings,
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
        title: Row(
          children: [
            const _BrandMark(size: 44),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('brand_title'),
                  style: const TextStyle(
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
            tooltip: l.t('refresh'),
            onPressed: (state.isAdminLoading || state.isFetchingData)
                ? null
                : () => state.refreshLiveData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l.t('logout'),
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
        title: Row(
          children: [
            const _BrandMark(size: 44),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l.t('brand_title'),
                  style: const TextStyle(
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
            tooltip: l.t('refresh'),
            onPressed: state.isBusy ? null : () => state.refreshLiveData(),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l.t('logout'),
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

class _BrandMark extends StatelessWidget {
  final double size;
  const _BrandMark({required this.size});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        'assets/images/LIVLogo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [LivTheme.primary, LivTheme.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(size * 0.26),
            ),
            child: const Center(
              child: Icon(
                Icons.agriculture_rounded,
                color: Colors.white,
              ),
            ),
          );
        },
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