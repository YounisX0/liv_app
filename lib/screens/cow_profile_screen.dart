import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/api_models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import 'breeding_screen.dart';

class CowProfileScreen extends StatefulWidget {
  final String cowId;
  const CowProfileScreen({super.key, required this.cowId});

  @override
  State<CowProfileScreen> createState() => _CowProfileScreenState();
}

class _CowProfileScreenState extends State<CowProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = context.read<AppState>();
      await state.loadCowProfileData(widget.cowId);
      await state.loadCowVetActions(widget.cowId);
    });
  }

  Future<void> _refreshAll() async {
    final state = context.read<AppState>();
    await state.refreshCowData(widget.cowId);
    await state.loadCowVetActions(widget.cowId, force: true);
  }

  Future<void> _openEditCowScreen(BuildContext context, Cow cow) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditCowScreen(cow: cow),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      await _refreshAll();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cow updated successfully.'),
        ),
      );
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
    final cow = state.cows.where((c) => c.id == widget.cowId).firstOrNull;
    final device =
        cow != null ? state.devices.where((d) => d.id == cow.deviceId).firstOrNull : null;

    final isLoading = state.isCowDataLoading(widget.cowId);
    final loadError = state.cowDataError(widget.cowId);

    final isVet = state.isVeterinarian || state.isAdmin;
    final canAcknowledge = state.isFarmer || state.isAdmin;

    final vetActions = state.cowVetActionsCache(widget.cowId);
    final isVetActionsLoading = state.isCowVetActionsLoading(widget.cowId);
    final vetActionsError = state.cowVetActionsError(widget.cowId);
    final pendingCount = vetActions.where((a) => !a.isAcknowledged).length;

    if (cow == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.t('cow_not_found'))),
        body: Center(child: Text(l.t('could_not_load'))),
      );
    }

    final now = DateTime.now();
    final lastEstrus = DateTime.tryParse(cow.fertility.lastEstrusDate);
    final daysAgo = lastEstrus != null ? now.difference(lastEstrus).inDays : '--';

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: Text(cow.name),
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: isLoading ? null : _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          if (isVet)
            IconButton(
              tooltip: 'Edit Cow',
              onPressed: () => _openEditCowScreen(context, cow),
              icon: const Icon(Icons.edit_outlined),
            ),
          if (isVet)
            IconButton(
              tooltip: 'Send Action',
              onPressed: () => _openSendActionScreen(context, cow),
              icon: const Icon(Icons.campaign_outlined),
            ),
          TextButton.icon(
            icon: const Icon(Icons.favorite_outlined, size: 18),
            label: Text(l.t('breeding_btn')),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BreedingScreen(selectedCowId: cow.id),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshAll,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(),
                ),
              if (loadError != null && loadError.trim().isNotEmpty)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: LivTheme.warn.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: LivTheme.warn.withOpacity(0.25)),
                  ),
                  child: Text(
                    loadError,
                    style: const TextStyle(
                      color: LivTheme.warn,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: LivTheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Center(child: Text('🐄', style: TextStyle(fontSize: 32))),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Text(
                                  cow.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: LivTheme.primary,
                                  ),
                                ),
                                HealthBadge(cow.healthStatus),
                                if (pendingCount > 0)
                                  _PendingCountBadge(count: pendingCount),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${cow.breed}  ·  ${cow.ageYears.toStringAsFixed(1)} yrs  ·  Parity ${cow.parity}',
                              style: const TextStyle(fontSize: 13, color: LivTheme.muted),
                            ),
                            Text(
                              'Device: ${cow.deviceId}',
                              style: const TextStyle(fontSize: 12, color: LivTheme.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SectionHeader(title: l.t('live_vitals')),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.7,
                children: [
                  KpiCard(
                    label: l.t('temperature'),
                    value: cow.vitals.tempC != null
                        ? '${cow.vitals.tempC!.toStringAsFixed(1)}°C'
                        : l.t('no_data'),
                    valueColor: cow.vitals.tempC != null
                        ? (cow.vitals.tempC! > 39.5 ? LivTheme.danger : LivTheme.ok)
                        : LivTheme.muted,
                  ),
                  KpiCard(
                    label: l.t('heart_rate'),
                    value: cow.vitals.hrBpm != null
                        ? '${cow.vitals.hrBpm!.toInt()} bpm'
                        : l.t('no_data'),
                    valueColor: cow.vitals.hrBpm != null
                        ? (cow.vitals.hrBpm! > 100 ? LivTheme.warn : LivTheme.text)
                        : LivTheme.muted,
                  ),
                  KpiCard(
                    label: l.t('spo2'),
                    value: cow.vitals.spO2 != null
                        ? '${cow.vitals.spO2!.toInt()}%'
                        : l.t('no_data'),
                    valueColor: cow.vitals.spO2 != null
                        ? (cow.vitals.spO2! < 92 ? LivTheme.danger : LivTheme.ok)
                        : LivTheme.muted,
                  ),
                  KpiCard(
                    label: l.t('activity'),
                    value: cow.vitals.activity != null
                        ? '${cow.vitals.activity!.toInt()}%'
                        : l.t('no_data'),
                    valueColor: LivTheme.text,
                  ),
                ],
              ),
              SectionHeader(title: l.t('temp_trend')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                  child: SizedBox(
                    height: 150,
                    child: _VitalsChart(history: cow.vitalsHistory, l: l),
                  ),
                ),
              ),
              if (device != null) ...[
                SectionHeader(title: l.t('iot_device')),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(l.t('device_id'), device.id),
                        _InfoRow(
                          l.t('status'),
                          device.status,
                          valueColor:
                              device.status == 'Online' ? LivTheme.ok : LivTheme.danger,
                        ),
                        _InfoRow(
                          l.t('battery'),
                          '${device.battery}%',
                          valueColor: device.battery < 30 ? LivTheme.danger : null,
                        ),
                        _InfoRow(l.t('signal'), '${device.signal} dBm'),
                        _InfoRow(
                          l.t('last_packet'),
                          l.t('sec_ago').replaceAll('{n}', '${device.lastPacketSecAgo}'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              SectionHeader(title: l.t('fertility_data')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (cow.isFertilityReady)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: LivTheme.gold.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: LivTheme.gold.withOpacity(0.4)),
                          ),
                          child: Row(
                            children: [
                              const Text('🌸', style: TextStyle(fontSize: 18)),
                              const SizedBox(width: 8),
                              Text(
                                l.t('fertile_window_banner'),
                                style: const TextStyle(
                                  color: LivTheme.gold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      _InfoRow(
                        l.t('last_estrus'),
                        l.t('days_ago').replaceAll('{n}', '$daysAgo'),
                      ),
                      _InfoRow(
                        l.t('predicted_in'),
                        '${cow.fertility.predictedEstrusInDays} ${l.t('days')}',
                      ),
                      _InfoRow(
                        l.t('cycle_length'),
                        '${cow.fertility.cycleLengthDays} ${l.t('days')}',
                      ),
                      _InfoRow(
                        l.t('conception_rate'),
                        '${(cow.fertility.conceptionRate * 100).toStringAsFixed(0)}%',
                      ),
                      _InfoRow(
                        l.t('body_condition'),
                        cow.fertility.bodyConditionScore.toStringAsFixed(1),
                      ),
                      _InfoRow(
                        l.t('inbreeding_risk'),
                        cow.fertility.inbreedingRisk,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vet Actions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: LivTheme.primary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Vet-to-farmer guidance for this cow',
                          style: TextStyle(
                            fontSize: 12,
                            color: LivTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (pendingCount > 0)
                    _PendingCountBadge(count: pendingCount),
                ],
              ),
              const SizedBox(height: 10),
              if (isVetActionsLoading)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading vet actions...'),
                      ],
                    ),
                  ),
                ),
              if (!isVetActionsLoading &&
                  vetActionsError != null &&
                  vetActionsError.trim().isNotEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      vetActionsError,
                      style: const TextStyle(
                        color: LivTheme.danger,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              if (!isVetActionsLoading &&
                  (vetActionsError == null || vetActionsError.trim().isEmpty) &&
                  vetActions.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No vet actions yet for this cow.',
                      style: TextStyle(color: LivTheme.muted),
                    ),
                  ),
                ),
              ...vetActions.map(
                (action) => _VetActionCard(
                  action: action,
                  canAcknowledge: canAcknowledge,
                  isAcknowledging: state.isAcknowledgingVetAction(action.actionId),
                  onAcknowledge: action.isAcknowledged
                      ? null
                      : () => _acknowledgeAction(
                            context,
                            cowId: cow.id,
                            actionId: action.actionId,
                          ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class EditCowScreen extends StatefulWidget {
  final Cow cow;
  const EditCowScreen({super.key, required this.cow});

  @override
  State<EditCowScreen> createState() => _EditCowScreenState();
}

class _EditCowScreenState extends State<EditCowScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _tagCtrl;
  late final TextEditingController _breedCtrl;
  late final TextEditingController _ageMonthsCtrl;
  late final TextEditingController _deviceCtrl;

  bool _submitting = false;
  String? _localError;
  late String _healthStatus;

  @override
  void initState() {
    super.initState();
    final cow = widget.cow;

    _nameCtrl = TextEditingController(text: cow.name);
    _tagCtrl = TextEditingController(text: cow.id);
    _breedCtrl = TextEditingController(text: cow.breed);
    _ageMonthsCtrl =
        TextEditingController(text: (cow.ageYears * 12).round().toString());
    _deviceCtrl = TextEditingController(text: cow.deviceId);
    _healthStatus = cow.healthStatus;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().clearVetCowMutationError();
    });
  }

  @override
  void dispose() {
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

    final ok = await app.updateCowByVet(
      cowId: widget.cow.id,
      updates: {
        'name': _nameCtrl.text.trim(),
        'tagNumber': _tagCtrl.text.trim(),
        'breed': _breedCtrl.text.trim(),
        'ageMonths': int.tryParse(_ageMonthsCtrl.text.trim()) ?? 0,
        'deviceId': _deviceCtrl.text.trim(),
        'healthStatus': _healthStatus,
      },
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _localError =
          app.vetCowMutationError ?? 'Failed to update cow. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: const Text('Edit Cow'),
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
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(labelText: 'Name'),
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
                      decoration: const InputDecoration(labelText: 'Tag Number'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _breedCtrl,
                      enabled: !_submitting,
                      decoration: const InputDecoration(labelText: 'Breed'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _ageMonthsCtrl,
                      enabled: !_submitting,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age (months)'),
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
                      decoration: const InputDecoration(labelText: 'Device ID'),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _healthStatus,
                      decoration: const InputDecoration(labelText: 'Health Status'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Healthy',
                          child: Text('Healthy'),
                        ),
                        DropdownMenuItem(
                          value: 'Fever',
                          child: Text('Fever'),
                        ),
                        DropdownMenuItem(
                          value: 'Heat Stress',
                          child: Text('Heat Stress'),
                        ),
                        DropdownMenuItem(
                          value: 'Low SpO2',
                          child: Text('Low SpO2'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _healthStatus = value;
                                });
                              }
                            },
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
                            onPressed:
                                _submitting ? null : () => Navigator.of(context).pop(),
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
                                : const Text('Save'),
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

class SendVetActionScreen extends StatefulWidget {
  final Cow cow;
  const SendVetActionScreen({super.key, required this.cow});

  @override
  State<SendVetActionScreen> createState() => _SendVetActionScreenState();
}

class _SendVetActionScreenState extends State<SendVetActionScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _messageCtrl;
  late final TextEditingController _actionCtrl;

  bool _submitting = false;
  String? _localError;
  String _priority = 'medium';

  @override
  void initState() {
    super.initState();
    _messageCtrl = TextEditingController();
    _actionCtrl = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppState>().clearVetActionMutationError();
    });
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    _actionCtrl.dispose();
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

    final ok = await app.sendVetAction(
      cowId: widget.cow.id,
      message: _messageCtrl.text.trim(),
      recommendedAction: _actionCtrl.text.trim(),
      priority: _priority,
    );

    if (!mounted) return;

    if (ok) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _submitting = false;
      _localError =
          app.vetActionMutationError ?? 'Failed to send action. Please try again.';
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppState>();

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: const Text('Send Action to Farmer'),
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
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Cow: ${widget.cow.name} (${widget.cow.id})',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: LivTheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _messageCtrl,
                      enabled: !_submitting,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Message',
                        hintText: 'Describe the issue clearly.',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Message is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _actionCtrl,
                      enabled: !_submitting,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Recommended Action',
                        hintText: 'What should the farmer do now?',
                      ),
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return 'Recommended action is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'low',
                          child: Text('Low'),
                        ),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(
                          value: 'high',
                          child: Text('High'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _priority = value;
                                });
                              }
                            },
                    ),
                    if (((_localError ?? app.vetActionMutationError) ?? '')
                        .trim()
                        .isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            (_localError ?? app.vetActionMutationError)!,
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
                            onPressed:
                                _submitting ? null : () => Navigator.of(context).pop(),
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
                                : const Text('Send'),
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

class _VetActionCard extends StatelessWidget {
  final ApiVetAction action;
  final bool canAcknowledge;
  final bool isAcknowledging;
  final VoidCallback? onAcknowledge;

  const _VetActionCard({
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

  String _fmt(String value) {
    if (value.trim().isEmpty) return '--';
    try {
      final dt = DateTime.parse(value).toLocal();
      final two = (int n) => n.toString().padLeft(2, '0');
      return '${dt.year}-${two(dt.month)}-${two(dt.day)} ${two(dt.hour)}:${two(dt.minute)}';
    } catch (_) {
      return value;
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Message',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.message,
              style: const TextStyle(
                color: LivTheme.text,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Recommended Action',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              action.recommendedAction,
              style: const TextStyle(
                color: LivTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            _MetaRow(label: 'Sent', value: _fmt(action.createdAt)),
            if (action.acknowledgedAt.trim().isNotEmpty)
              _MetaRow(label: 'Acknowledged', value: _fmt(action.acknowledgedAt)),
            if (acknowledgedByText.trim().isNotEmpty)
              _MetaRow(label: 'Acknowledged By', value: acknowledgedByText),
            if (canAcknowledge && !action.isAcknowledged) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: isAcknowledging ? null : onAcknowledge,
                  icon: isAcknowledging
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: const Text('Acknowledge'),
                ),
              ),
            ],
          ],
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

class _MetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetaRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                color: LivTheme.muted,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: LivTheme.text,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: LivTheme.muted)),
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

class _VitalsChart extends StatelessWidget {
  final List<double> history;
  final AppLocalizations l;
  const _VitalsChart({required this.history, required this.l});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return Center(
        child: Text(
          l.t('no_data'),
          style: const TextStyle(color: LivTheme.muted),
        ),
      );
    }

    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    final minY = history.reduce((a, b) => a < b ? a : b) - 0.5;
    final maxY = history.reduce((a, b) => a > b ? a : b) + 0.5;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: LivTheme.line, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(1),
                style: const TextStyle(fontSize: 9, color: LivTheme.muted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: LivTheme.accent,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: LivTheme.accent.withOpacity(0.10),
            ),
          ),
        ],
      ),
    );
  }
}