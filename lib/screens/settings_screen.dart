import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';

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

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Connection ──────────────────────────────────────────────────
          _Section(title: 'Server connection', children: [
            const Text(
              'Enter the IP address and port of your LIV Node.js gateway server. '
              'Make sure your phone is on the same Wi-Fi network as the server.',
              style: TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: InputDecoration(
                labelText: 'Server URL',
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
                label: Text(_saved ? 'Saved!' : 'Connect'),
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
          _Section(title: 'Connection status', children: [
            _StatusRow(
              label: 'Server',
              value: state.connected ? 'Connected' : 'Disconnected',
              color: state.connected ? LivTheme.ok : LivTheme.danger,
            ),
            _StatusRow(
              label: 'Data mode',
              value: state.useDemoData ? 'Demo (seed data)' : 'Live',
              color: state.useDemoData ? LivTheme.gold : LivTheme.ok,
            ),
            _StatusRow(label: 'Gateway ID', value: state.gatewayId),
            _StatusRow(label: 'UDP status', value: state.udpStatus),
            _StatusRow(label: 'MQTT status', value: state.mqttStatus),
          ]),

          const SizedBox(height: 16),

          // ── Demo reset ──────────────────────────────────────────────────
          _Section(title: 'Demo data', children: [
            const Text(
              'Reset the server\'s seeded demo state back to initial values. '
              'This calls POST /api/demo/reset on the connected server.',
              style: TextStyle(fontSize: 13, color: LivTheme.muted),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reset demo state'),
              style: OutlinedButton.styleFrom(
                foregroundColor: LivTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                await state.resetDemo();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Demo state reset ✓')),
                  );
                }
              },
            ),
          ]),

          const SizedBox(height: 16),

          // ── About ───────────────────────────────────────────────────────
          _Section(title: 'About', children: [
            _InfoRow('App', 'LIV Smart Farm Dashboard'),
            _InfoRow('Version', '1.0.0'),
            _InfoRow('Backend', 'Node.js · Express · Socket.IO · AWS IoT'),
            _InfoRow('Hardware', 'ESP32 → Farm PC → AWS'),
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
