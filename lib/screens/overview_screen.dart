import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';
import 'cow_profile_screen.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);

    final healthCounts = <String, int>{};
    for (final c in state.cows) {
      healthCounts[c.healthStatus] = (healthCounts[c.healthStatus] ?? 0) + 1;
    }
    final healthyCnt = healthCounts['Healthy'] ?? 0;
    final alertCnt = state.alerts.length;
    final onlineCnt = state.devices.where((d) => d.status == 'Online').length;
    final recentAlerts = [...state.alerts]
      ..sort((a, b) => DateTime.parse(b.createdAt).compareTo(DateTime.parse(a.createdAt)));
    final topAlerts = recentAlerts.take(6).toList();

    return RefreshIndicator(
      onRefresh: () => state.resetDemo(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.useDemoData) DemoBanner(message: l.t('demo_banner')),

                // ── KPI row ───────────────────────────────────────────────
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    KpiCard(
                      label: l.t('total_cows'),
                      value: '${state.cows.length}',
                      hint: l.t('in_herd'),
                    ),
                    KpiCard(
                      label: l.t('healthy'),
                      value: '$healthyCnt',
                      valueColor: LivTheme.ok,
                      hint: healthyCnt == state.cows.length ? l.t('all_clear') : l.t('check_others'),
                    ),
                    KpiCard(
                      label: l.t('active_alerts'),
                      value: '$alertCnt',
                      valueColor: alertCnt > 0 ? LivTheme.danger : LivTheme.ok,
                      hint: alertCnt > 0 ? l.t('needs_attention') : l.t('all_clear'),
                    ),
                    KpiCard(
                      label: l.t('devices_online'),
                      value: '$onlineCnt',
                      hint: l.t('of_total').replaceAll('{n}', '${state.devices.length}'),
                    ),
                  ],
                ),

                // ── Health breakdown ──────────────────────────────────────
                SectionHeader(title: l.t('herd_health_breakdown')),
                ...healthCounts.entries.map((e) {
                  final badge = HealthBadge(e.key);
                  final cowWord = e.value == 1 ? l.t('cow') : l.t('cows');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${e.value} $cowWord'),
                      trailing: badge,
                    ),
                  );
                }),

                // ── Recent alerts ─────────────────────────────────────────
                SectionHeader(title: l.t('recent_alerts'), subtitle: l.t('latest_6')),
                if (topAlerts.isEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: LivTheme.ok),
                          const SizedBox(width: 10),
                          Text(l.t('no_alerts')),
                        ],
                      ),
                    ),
                  ),
                ...topAlerts.map((a) => _AlertCard(alert: a, cows: state.cows, l: l)),

                // ── Quick cow list ────────────────────────────────────────
                SectionHeader(title: l.t('herd_overview')),
                ...state.cows.map((c) => _CowRow(cow: c)),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final FarmAlert alert;
  final List<Cow> cows;
  final AppLocalizations l;
  const _AlertCard({required this.alert, required this.cows, required this.l});

  @override
  Widget build(BuildContext context) {
    final cow = cows.where((c) => c.id == alert.cowId).firstOrNull;
    final time = _fmtTime(alert.createdAt, l);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AlertIcon(alert.severity),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                          child: Text(alert.title,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
                      Text(time, style: const TextStyle(fontSize: 11, color: LivTheme.muted)),
                    ],
                  ),
                  if (cow != null)
                    Text(cow.name,
                        style: const TextStyle(
                            fontSize: 12, color: LivTheme.accent, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(alert.details, style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso, AppLocalizations l) {
    try {
      final t = DateTime.parse(iso);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 60) return l.t('min_ago').replaceAll('{n}', '${diff.inMinutes}');
      return l.t('hr_ago').replaceAll('{n}', '${diff.inHours}');
    } catch (_) {
      return '';
    }
  }
}

class _CowRow extends StatelessWidget {
  final Cow cow;
  const _CowRow({required this.cow});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CowProfileScreen(cowId: cow.id)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: LivTheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text('🐄', style: TextStyle(fontSize: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cow.name,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    Text('${cow.breed} · ${cow.id}',
                        style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  HealthBadge(cow.healthStatus),
                  const SizedBox(height: 4),
                  Text('${cow.vitals.tempC.toStringAsFixed(1)} °C',
                      style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: LivTheme.muted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
