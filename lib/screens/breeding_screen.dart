import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import '../l10n/app_localizations.dart';

class BreedingScreen extends StatefulWidget {
  final String? selectedCowId;
  const BreedingScreen({super.key, this.selectedCowId});

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  late String _cowId;
  String _sireId = '';

  @override
  void initState() {
    super.initState();
    final state = context.read<AppState>();
    _cowId = widget.selectedCowId ?? (state.cows.isNotEmpty ? state.cows[0].id : '');
    _sireId = state.sires.isNotEmpty ? state.sires[0].id : '';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final l = AppLocalizations(state.locale);
    final cow = state.cows.where((c) => c.id == _cowId).firstOrNull ?? state.cows.firstOrNull;
    final sire = state.sires.where((s) => s.id == _sireId).firstOrNull ?? state.sires.firstOrNull;

    if (cow == null || sire == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l.t('breeding_advisor'))),
        body: const Center(child: Text('No data available.')),
      );
    }

    final score = sire.breedingScore(cow);
    final ready = cow.isFertilityReady;
    final rec = _recommendation(score, ready, l);

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        title: Text(l.t('breeding_advisor')),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Selectors ───────────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _SelectorCard(
                    label: l.t('select_cow'),
                    value: cow.name,
                    icon: '🐄',
                    onTap: () => _pickCow(context, state.cows, l),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SelectorCard(
                    label: l.t('select_sire'),
                    value: sire.name,
                    icon: '🐂',
                    onTap: () => _pickSire(context, state.sires, l),
                  ),
                ),
              ],
            ),

            // ── Recommendation banner ───────────────────────────────────────
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [LivTheme.primary, LivTheme.accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(l.t('breeding_score'),
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(score.toStringAsFixed(1),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(rec.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(height: 4),
                  Text(rec.title,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(rec.body,
                      style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            ),

            // ── Cow details ─────────────────────────────────────────────────
            SectionHeader(title: l.t('cow_profile')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _Row(l.t('health'), cow.healthStatus),
                    _Row(l.t('body_condition_score'),
                        cow.fertility.bodyConditionScore.toStringAsFixed(1)),
                    _Row(l.t('conception_rate'),
                        '${(cow.fertility.conceptionRate * 100).toStringAsFixed(0)}%'),
                    _Row(l.t('inbreeding_risk'), cow.fertility.inbreedingRisk),
                    _Row(l.t('fertile_window'), ready ? l.t('yes') : l.t('not_yet')),
                  ],
                ),
              ),
            ),

            // ── Sire traits ─────────────────────────────────────────────────
            SectionHeader(title: l.t('sire_traits')),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(sire.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: LivTheme.primary)),
                    Text(sire.semenBatch,
                        style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                    const SizedBox(height: 12),
                    TraitBar(label: l.t('fertility'), value: sire.traits.fertility),
                    TraitBar(label: l.t('disease_resistance'), value: sire.traits.diseaseResistance),
                    TraitBar(label: l.t('temperament'), value: sire.traits.temperament),
                    TraitBar(label: l.t('milk_yield'), value: sire.traits.milkYield),
                    TraitBar(label: l.t('calving_ease'), value: sire.traits.calvingEase),
                    const SizedBox(height: 10),
                    Text(sire.notes,
                        style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                  ],
                ),
              ),
            ),

            // ── Protocol ────────────────────────────────────────────────────
            if (ready) ...[
              SectionHeader(title: l.t('rec_protocol')),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _ProtocolStep('1', l.t('step_confirm'), l.t('step_confirm_body')),
                      _ProtocolStep(
                        '2',
                        l.t('step_check_device'),
                        l.t('step_check_device_body').replaceAll('{id}', cow.deviceId),
                      ),
                      _ProtocolStep(
                        '3',
                        l.t('step_use_batch'),
                        l.t('step_use_batch_body')
                            .replaceAll('{batch}', sire.semenBatch)
                            .replaceAll('{sire}', sire.name),
                      ),
                      _ProtocolStep('4', l.t('step_record'), l.t('step_record_body')),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _pickCow(BuildContext ctx, List<Cow> cows, AppLocalizations l) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _PickerSheet(
        title: l.t('select_cow'),
        items: cows.map((c) => (c.id, c.name, c.healthStatus)).toList(),
        onSelect: (id) => setState(() => _cowId = id),
      ),
    );
  }

  void _pickSire(BuildContext ctx, List<Sire> sires, AppLocalizations l) {
    showModalBottomSheet(
      context: ctx,
      builder: (_) => _PickerSheet(
        title: l.t('select_sire'),
        items: sires.map((s) => (s.id, s.name, s.semenBatch)).toList(),
        onSelect: (id) => setState(() => _sireId = id),
      ),
    );
  }

  _Rec _recommendation(double score, bool ready, AppLocalizations l) {
    if (!ready) return _Rec(l.t('rec_not_fertile'), l.t('rec_not_fertile_title'), l.t('rec_not_fertile_body'));
    if (score >= 7.5) return _Rec(l.t('rec_strong'), l.t('rec_strong_title'), l.t('rec_strong_body'));
    if (score >= 6.0) return _Rec(l.t('rec_good'), l.t('rec_good_title'), l.t('rec_good_body'));
    if (score >= 4.5) return _Rec(l.t('rec_caution'), l.t('rec_caution_title'), l.t('rec_caution_body'));
    return _Rec(l.t('rec_no'), l.t('rec_no_title'), l.t('rec_no_body'));
  }
}

class _Rec {
  final String emoji;
  final String title;
  final String body;
  const _Rec(this.emoji, this.title, this.body);
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(fontSize: 13, color: LivTheme.muted)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

class _ProtocolStep extends StatelessWidget {
  final String num;
  final String title;
  final String body;
  const _ProtocolStep(this.num, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(color: LivTheme.primary, shape: BoxShape.circle),
            child: Center(
                child: Text(num,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                Text(body, style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectorCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final VoidCallback onTap;
  const _SelectorCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: LivTheme.muted)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(icon, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 6),
                  Expanded(
                      child: Text(value,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14))),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: LivTheme.muted),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String, String, String)> items;
  final void Function(String id) onSelect;
  const _PickerSheet(
      {required this.title, required this.items, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child:
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item.$2),
                subtitle: Text(item.$3),
                onTap: () {
                  onSelect(item.$1);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
