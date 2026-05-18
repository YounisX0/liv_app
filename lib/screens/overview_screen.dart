import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/api_models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import '../l10n/app_localizations.dart';
import 'cow_profile_screen.dart';

class OverviewScreen extends StatefulWidget {
  const OverviewScreen({super.key});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
  final Set<String> _prefetchedCowIds = <String>{};

  void _scheduleVetActionPrefetch(List<FarmAlert> alerts) {
    final state = context.read<AppState>();
    final cowIds = alerts.map((a) => a.cowId).where((id) => id.trim().isNotEmpty).toSet();

    for (final cowId in cowIds) {
      if (_prefetchedCowIds.contains(cowId)) continue;
      _prefetchedCowIds.add(cowId);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        state.loadCowVetActions(cowId);
      });
    }
  }

  Future<void> _openSendActionScreen(BuildContext context, Cow cow) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SendVetActionScreen(cow: cow),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await context.read<AppState>().loadCowVetActions(cow.id, force: true);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action sent to farmer.'),
        ),
      );
    }
  }

  Future<void> _acknowledgeAction(
    BuildContext context, {
    required String cowId,
    required String actionId,
  }) async {
    final state = context.read<AppState>();
    final ok = await state.acknowledgeVetAction(
      cowId: cowId,
      actionId: actionId,
    );

    if (!context.mounted) return;

    if (ok) {
      await state.loadCowVetActions(cowId, force: true);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action acknowledged.'),
        ),
      );
    }
  }

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

    _scheduleVetActionPrefetch(topAlerts);

    return RefreshIndicator(
      onRefresh: () => state.resetDemo(),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (state.useDemoData) DemoBanner(message: l.t('demo_banner')),

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
                      hint: healthyCnt == state.cows.length
                          ? l.t('all_clear')
                          : l.t('check_others'),
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

                SectionHeader(title: l.t('herd_health_breakdown')),
                ...healthCounts.entries.map((e) {
                  final badge = HealthBadge(e.key);
                  final cowWord = e.value == 1 ? l.t('cow') : l.t('cows');
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(
                        e.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${e.value} $cowWord'),
                      trailing: badge,
                    ),
                  );
                }),

                SectionHeader(
                  title: l.t('recent_alerts'),
                  subtitle: l.t('latest_6'),
                ),
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
                ...topAlerts.map(
                  (a) => _AlertCard(
                    alert: a,
                    cows: state.cows,
                    l: l,
                    actions: state.cowVetActionsCache(a.cowId),
                    actionsLoading: state.isCowVetActionsLoading(a.cowId),
                    actionsError: state.cowVetActionsError(a.cowId),
                    canSendAction: state.isVeterinarian || state.isAdmin,
                    canAcknowledge: state.isFarmer || state.isAdmin,
                    onSendAction: (cow) => _openSendActionScreen(context, cow),
                    onAcknowledge: (actionId) => _acknowledgeAction(
                      context,
                      cowId: a.cowId,
                      actionId: actionId,
                    ),
                    isAcknowledgingAction: (actionId) =>
                        state.isAcknowledgingVetAction(actionId),
                  ),
                ),

                SectionHeader(title: l.t('herd_overview')),
                ...state.cows.map((c) => _CowRow(cow: c, l: l)),

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
  final List<ApiVetAction> actions;
  final bool actionsLoading;
  final String? actionsError;
  final bool canSendAction;
  final bool canAcknowledge;
  final Future<void> Function(Cow cow) onSendAction;
  final Future<void> Function(String actionId) onAcknowledge;
  final bool Function(String actionId) isAcknowledgingAction;

  const _AlertCard({
    required this.alert,
    required this.cows,
    required this.l,
    required this.actions,
    required this.actionsLoading,
    required this.actionsError,
    required this.canSendAction,
    required this.canAcknowledge,
    required this.onSendAction,
    required this.onAcknowledge,
    required this.isAcknowledgingAction,
  });

  @override
  Widget build(BuildContext context) {
    final cow = cows.where((c) => c.id == alert.cowId).firstOrNull;
    final time = _fmtTime(alert.createdAt, l);
    final latestAction = actions.isNotEmpty ? actions.first : null;
    final pendingCount = actions.where((a) => !a.isAcknowledged).length;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
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
                            child: Text(
                              alert.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Text(
                            time,
                            style: const TextStyle(
                              fontSize: 11,
                              color: LivTheme.muted,
                            ),
                          ),
                        ],
                      ),
                      if (cow != null)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              cow.name,
                              style: const TextStyle(
                                fontSize: 12,
                                color: LivTheme.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (pendingCount > 0)
                              _PendingCountBadge(count: pendingCount),
                          ],
                        ),
                      const SizedBox(height: 4),
                      Text(
                        alert.details,
                        style: const TextStyle(
                          fontSize: 12,
                          color: LivTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (actionsLoading)
              const Padding(
                padding: EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Loading guidance...',
                      style: TextStyle(
                        fontSize: 12,
                        color: LivTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
            if (!actionsLoading &&
                actionsError != null &&
                actionsError!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    actionsError!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: LivTheme.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (!actionsLoading && latestAction != null) ...[
              const SizedBox(height: 12),
              _OverviewVetActionSummary(
                action: latestAction,
                canAcknowledge: canAcknowledge,
                isAcknowledging: isAcknowledgingAction(latestAction.actionId),
                onAcknowledge: latestAction.isAcknowledged
                    ? null
                    : () => onAcknowledge(latestAction.actionId),
              ),
            ],
            if (canSendAction && cow != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: () => onSendAction(cow),
                  icon: const Icon(Icons.campaign_outlined),
                  label: const Text('Send Action'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _fmtTime(String iso, AppLocalizations l) {
    try {
      final t = DateTime.parse(iso);
      final diff = DateTime.now().difference(t);
      if (diff.inMinutes < 60) {
        return l.t('min_ago').replaceAll('{n}', '${diff.inMinutes}');
      }
      return l.t('hr_ago').replaceAll('{n}', '${diff.inHours}');
    } catch (_) {
      return '';
    }
  }
}

class _OverviewVetActionSummary extends StatelessWidget {
  final ApiVetAction action;
  final bool canAcknowledge;
  final bool isAcknowledging;
  final VoidCallback? onAcknowledge;

  const _OverviewVetActionSummary({
    required this.action,
    required this.canAcknowledge,
    required this.isAcknowledging,
    required this.onAcknowledge,
  });

  Color _priorityColor(String value) {
    switch (value.toLowerCase()) {
      case 'high':
        return LivTheme.danger;
      case 'medium':
        return LivTheme.warn;
      default:
        return LivTheme.ok;
    }
  }

  Color _statusColor(String value) {
    switch (value.toLowerCase()) {
      case 'acknowledged':
        return LivTheme.ok;
      default:
        return LivTheme.accent;
    }
  }

  String _acknowledgedByDisplay(BuildContext context) {
    final state = context.watch<AppState>();

    if (action.acknowledgedByName.trim().isNotEmpty) {
      return action.acknowledgedByName;
    }

    final currentUser = state.currentUser;
    if (currentUser != null &&
        currentUser.userId == action.acknowledgedBy &&
        currentUser.fullName.trim().isNotEmpty) {
      return currentUser.fullName;
    }

    return action.acknowledgedBy;
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _priorityColor(action.priority);
    final statusColor = _statusColor(action.status);
    final acknowledgedByText = _acknowledgedByDisplay(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: LivTheme.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: priorityColor.withOpacity(0.35)),
                ),
                child: Text(
                  'Priority: ${action.priority}',
                  style: TextStyle(
                    color: priorityColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Text(
                  'Status: ${action.status}',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Vet Message',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: LivTheme.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.message,
            style: const TextStyle(
              fontSize: 12,
              color: LivTheme.text,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Recommended Action',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: LivTheme.primary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            action.recommendedAction,
            style: const TextStyle(
              fontSize: 12,
              color: LivTheme.text,
            ),
          ),
          if (action.isAcknowledged && acknowledgedByText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Acknowledged by: $acknowledgedByText',
              style: const TextStyle(
                fontSize: 12,
                color: LivTheme.muted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (canAcknowledge && !action.isAcknowledged) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonalIcon(
                onPressed: isAcknowledging ? null : onAcknowledge,
                icon: isAcknowledging
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline, size: 18),
                label: const Text('Acknowledge'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingCountBadge extends StatelessWidget {
  final int count;
  const _PendingCountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: LivTheme.danger,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CowRow extends StatelessWidget {
  final Cow cow;
  final AppLocalizations l;

  const _CowRow({
    required this.cow,
    required this.l,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final device = state.devices.where((d) => d.id == cow.deviceId).firstOrNull;

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
                child: const Center(
                  child: Text('🐄', style: TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cow.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      '${cow.breed} · ${cow.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: LivTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  HealthBadge(cow.healthStatus),
                  const SizedBox(height: 4),
                  Text(
                    cow.vitals.tempC != null
                        ? '${cow.vitals.tempC!.toStringAsFixed(1)} °C'
                        : l.t('no_data'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: LivTheme.muted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.chevron_right,
                color: LivTheme.muted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}