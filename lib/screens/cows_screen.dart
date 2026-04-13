import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import 'cow_profile_screen.dart';

class CowsScreen extends StatefulWidget {
  const CowsScreen({super.key});

  @override
  State<CowsScreen> createState() => _CowsScreenState();
}

class _CowsScreenState extends State<CowsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);
    final q = _query.trim().toLowerCase();

    final filtered = state.cows.where((c) {
      if (q.isEmpty) return true;
      return c.name.toLowerCase().contains(q) ||
          c.id.toLowerCase().contains(q) ||
          c.breed.toLowerCase().contains(q) ||
          c.healthStatus.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            decoration: InputDecoration(
              hintText: l.t('search_hint'),
              prefixIcon: const Icon(Icons.search, color: LivTheme.muted),
              filled: true,
              fillColor: LivTheme.bg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (ctx, i) => _CowCard(cow: filtered[i], l: l),
          ),
        ),
      ],
    );
  }
}

class _CowCard extends StatelessWidget {
  final Cow cow;
  final AppLocalizations l;
  const _CowCard({required this.cow, required this.l});

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final device = state.devices.where((d) => d.id == cow.deviceId).firstOrNull;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CowProfileScreen(cowId: cow.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: LivTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(child: Text('🐄', style: TextStyle(fontSize: 24))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cow.name,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        Text(
                          '${cow.breed} · ${cow.id}',
                          style: const TextStyle(fontSize: 12, color: LivTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  HealthBadge(cow.healthStatus),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _VitalChip(
                    icon: '🌡️',
                    value: cow.vitals.tempC != null
                        ? '${cow.vitals.tempC!.toStringAsFixed(1)}°C'
                        : l.t('no_data'),
                  ),
                  const SizedBox(width: 8),
                  _VitalChip(
                    icon: '❤️',
                    value: cow.vitals.hrBpm != null
                        ? '${cow.vitals.hrBpm!.toInt()} bpm'
                        : l.t('no_data'),
                  ),
                  const SizedBox(width: 8),
                  _VitalChip(
                    icon: '💨',
                    value: cow.vitals.spO2 != null
                        ? '${cow.vitals.spO2!.toInt()}%'
                        : l.t('no_data'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (device != null) ...[
                    Icon(
                      Icons.battery_std,
                      size: 14,
                      color: device.battery < 30 ? LivTheme.danger : LivTheme.ok,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${device.battery}%',
                      style: const TextStyle(fontSize: 12, color: LivTheme.muted),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (cow.isFertilityReady) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: LivTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: LivTheme.gold.withOpacity(0.5)),
                      ),
                      child: Text(
                        '🌸 ${l.t('fertile_window')}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: LivTheme.gold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Parity ${cow.parity}',
                    style: const TextStyle(fontSize: 11, color: LivTheme.muted),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18, color: LivTheme.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  final String icon;
  final String value;
  const _VitalChip({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LivTheme.bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LivTheme.line),
      ),
      child: Text(
        '$icon $value',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}