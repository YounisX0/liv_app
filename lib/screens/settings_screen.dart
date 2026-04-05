import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../l10n/app_localizations.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _urlCtrl;
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _urlCtrl = TextEditingController(text: state.serverUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final state = context.read<AppState>();
    state.setServerUrl(_urlCtrl.text.trim());
    setState(() => _saved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _saved = false);
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(title: Text(l.t('settings')), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Language ────────────────────────────────────────────────────
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

          // ── Connection ──────────────────────────────────────────────────
          _Section(title: l.t('server_connection'), children: [
            Text(
              l.t('server_desc'),
              style: const TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: l.t('server_url'),
                hintText: 'http://192.168.1.100:3000',
                prefixIcon: const Icon(Icons.lan_outlined),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: _saved
                    ? const Icon(Icons.check, size: 18)
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_saved ? l.t('saved') : l.t('connect')),
                style: FilledButton.styleFrom(
                  backgroundColor: _saved ? LivTheme.ok : LivTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
              ),
            ),
          ]),

          const SizedBox(height: 16),

          // ── Status ──────────────────────────────────────────────────────
          _Section(title: l.t('connection_status'), children: [
            _StatusRow(
              label: l.t('server'),
              value: state.connected ? l.t('connected') : l.t('disconnected'),
              color: state.connected ? LivTheme.ok : LivTheme.danger,
            ),
            _StatusRow(
              label: l.t('data_mode'),
              value: state.useDemoData ? l.t('demo_seed') : l.t('live'),
              color: state.useDemoData ? LivTheme.gold : LivTheme.ok,
            ),
            _StatusRow(label: l.t('gateway_id'), value: state.gatewayId),
            _StatusRow(label: l.t('udp_status'), value: state.udpStatus),
            _StatusRow(label: l.t('mqtt_status'), value: state.mqttStatus),
          ]),

          const SizedBox(height: 16),

          // ── Demo reset ──────────────────────────────────────────────────
          _Section(title: l.t('demo_data'), children: [
            Text(
              l.t('demo_reset_desc'),
              style: const TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: Text(l.t('reset_demo')),
              style: OutlinedButton.styleFrom(
                foregroundColor: LivTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await state.resetDemo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.t('demo_reset_ok'))),
                  );
                }
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── About ───────────────────────────────────────────────────────
          _Section(title: l.t('about'), children: [
            _InfoRow(l.t('app_label'), 'LIV Smart Farm Dashboard'),
            _InfoRow(l.t('version'), '1.0.0'),
            _InfoRow(l.t('backend'), 'Node.js · Express · Socket.IO · AWS IoT'),
            _InfoRow(l.t('hardware'), 'ESP32 → Farm PC → AWS'),
            const SizedBox(height: 8),
            const Text(
              'Routes:\n'
              '  GET  /api/status        → Gateway + MQTT status\n'
              '  GET  /api/cloud-state   → Full herd state\n'
              '  POST /api/demo/reset    → Reset demo data',
              style: TextStyle(
                  fontSize: 11,
                  color: LivTheme.muted,
                  fontFamily: 'monospace',
                  height: 1.6),
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// ── Language option card ──────────────────────────────────────────────────────
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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: selected ? LivTheme.primary.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: selected ? LivTheme.primary : LivTheme.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: selected ? LivTheme.primary : LivTheme.text,
              ),
            ),
            if (selected) ...[
              const SizedBox(height: 4),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: LivTheme.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: LivTheme.muted,
                letterSpacing: 0.8)),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const _StatusRow({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: LivTheme.muted)),
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color ?? LivTheme.text)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
