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
  final Set<String> _prefetchedActionCowIds = <String>{};

  void _scheduleVetActionPrefetch(List<Cow> cows) {
    final state = context.read<AppState>();

    for (final cow in cows) {
      if (_prefetchedActionCowIds.contains(cow.id)) continue;
      _prefetchedActionCowIds.add(cow.id);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        state.loadCowVetActions(cow.id);
      });
    }
  }

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

    _scheduleVetActionPrefetch(filtered);

    final canAddCow = state.isVeterinarian || state.isAdmin;

    return Stack(
      children: [
        Column(
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  canAddCow ? 96 : 16,
                ),
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final cow = filtered[i];
                  final pendingCount = state
                      .cowVetActionsCache(cow.id)
                      .where((a) => !a.isAcknowledged)
                      .length;

                  return _CowCard(
                    cow: cow,
                    l: l,
                    pendingCount: pendingCount,
                  );
                },
              ),
            ),
          ],
        ),
        if (canAddCow)
          PositionedDirectional(
            end: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add_cow_fab',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddCowScreen(),
                  ),
                );
              },
              backgroundColor: LivTheme.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Add Cow'),
            ),
          ),
      ],
    );
  }
}

class AddCowScreen extends StatefulWidget {
  const AddCowScreen({super.key});

  @override
  State<AddCowScreen> createState() => _AddCowScreenState();
}

class _AddCowScreenState extends State<AddCowScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _cowIdCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _tagCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageMonthsCtrl;
  late final TextEditingController _deviceCtrl;

  bool _submitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _cowIdCtrl = TextEditingController();
    _nameCtrl = TextEditingController();
    _tagCtrl = TextEditingController();
    _breedCtrl = TextEditingController();
    _ageMonthsCtrl = TextEditingController();
    _deviceCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().clearVetCowMutationError();
    });
  }

  @override
  void dispose() {
    _cowIdCtrl.dispose();
    _nameCtrl.dispose();
    _tagCtrl.dispose();
    _breedCtrl.dispose();
    _ageMonthsCtrl.dispose();
    _deviceCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _submitting = true;
      _localError = null;
    });

    final app = context.read<AppState>();

    final ok = await app.addCowByVet(
      cowId: _cowIdCtrl.text.trim(),
      name: _nameCtrl.text.trim(),
      tagNumber: _tagCtrl.text.trim(),
      breed: _breedCtrl.text.trim(),
      ageMonths: int.tryParse(_ageMonthsCtrl.text.trim()) ?? 0,
      deviceId: _deviceCtrl.text.trim(),
    );

    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cow added successfully.'),
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _submitting = false;
      _localError =
          app.vetCowMutationError ?? 'Failed to add cow. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: const Text('Add Cow'),
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _cowIdCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Cow ID',
                        hintText: 'COW-909',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Cow ID is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Name',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _tagCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Tag Number',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breedCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Breed',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageMonthsCtrl,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Age (months)',
                      ),
                      validator: (value) {
                        final parsed = int.tryParse((value ?? '').trim());
                        if (parsed == null || parsed < 0) {
                          return 'Enter a valid age in months';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _deviceCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(
                        labelText: 'Device ID',
                      ),
                    ),
                    if (((_localError ?? app.vetCowMutationError) ?? '')
                        .trim()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (_localError ?? app.vetCowMutationError)!,
                            style: const TextStyle(
                              color: LivTheme.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _submitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Add'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CowCard extends StatelessWidget {
  final Cow cow;
  final AppLocalizations l;
  final int pendingCount;

  const _CowCard({
    required this.cow,
    required this.l,
    required this.pendingCount,
  });

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
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              cow.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                            if (pendingCount > 0)
                              _PendingCountBadge(count: pendingCount),
                          ],
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