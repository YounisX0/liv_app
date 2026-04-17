import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: Text(l.t('settings')),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _Section(title: l.t('language'), children: [
            Row(
              children: [
                Expanded(
                  child: _LangOption(
                    label: 'English',
                    flag: '🇬🇧',
                    selected: state.locale == AppLocale.en,
                    onTap: () => state.setLocale(AppLocale.en),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _LangOption(
                    label: 'العربية',
                    flag: '🇸🇦',
                    selected: state.locale == AppLocale.ar,
                    onTap: () => state.setLocale(AppLocale.ar),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: l.t('server_connection'), children: [
            const Text(
              'The backend URL is loaded from the .env file and is no longer editable inside the app.',
              style: TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: LivTheme.line),
              ),
              child: SelectableText(
                state.serverUrl.isEmpty ? 'Not configured' : state.serverUrl,
                style: TextStyle(
                  fontSize: 13,
                  color: state.serverUrl.isEmpty
                      ? LivTheme.danger
                      : LivTheme.text,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.lock_outline, size: 16, color: LivTheme.ok),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'To change the API URL, update the .env file and restart the app.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: LivTheme.muted,
                    ),
                  ),
                ),
              ],
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: l.t('connection_status'), children: [
            _InfoTile(
              title: l.t('server'),
              value: state.hasServerUrl ? l.t('configured') : l.t('not_configured'),
              valueColor: state.hasServerUrl ? LivTheme.ok : LivTheme.danger,
            ),
            _InfoTile(
              title: l.t('connected'),
              value: state.connected ? l.t('connected') : l.t('disconnected'),
              valueColor: state.connected ? LivTheme.ok : LivTheme.danger,
            ),
            _InfoTile(
              title: l.t('data_mode'),
              value: state.useDemoData ? l.t('demo_seed') : l.t('live'),
              valueColor: state.useDemoData ? LivTheme.gold : LivTheme.ok,
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: l.t('demo_data'), children: [
            Text(
              l.t('demo_reset_desc'),
              style: const TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: Text(l.t('reset_demo')),
                onPressed: () async {
                  await context.read<AppState>().resetDemo();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.t('demo_reset_ok'))),
                    );
                  }
                },
              ),
            ),
          ]),
          const SizedBox(height: 16),
          _Section(title: l.t('about'), children: const [
            _InfoTile(title: 'App', value: 'LIV Dashboard'),
            _InfoTile(title: 'Version', value: '1.0.0'),
            _InfoTile(title: 'Backend', value: 'AWS API Gateway + Lambda'),
            _InfoTile(title: 'Hardware', value: 'ESP32 livestock collar'),
          ]),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? LivTheme.primary : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? LivTheme.primary
                  : LivTheme.primary.withOpacity(0.20),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(flag),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : LivTheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.title,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                color: LivTheme.muted,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? LivTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}