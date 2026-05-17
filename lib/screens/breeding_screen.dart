import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/breeding_sires.dart';
import '../models/breeding_models.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../services/breeding_recommender_service.dart';
import '../theme/liv_theme.dart';

class BreedingScreen extends StatefulWidget {
  final String? selectedCowId;

  const BreedingScreen({
    super.key,
    this.selectedCowId,
  });

  @override
  State<BreedingScreen> createState() => _BreedingScreenState();
}

class _BreedingScreenState extends State<BreedingScreen> {
  final _formKey = GlobalKey<FormState>();
  final BreedingRecommenderService _service = const BreedingRecommenderService();

  String? _selectedCowId;
  bool _didInitialPrefill = false;

  final TextEditingController _breedCtrl = TextEditingController();
  final TextEditingController _parityCtrl = TextEditingController();
  final TextEditingController _daysPostpartumCtrl = TextEditingController();
  final TextEditingController _inseminationCountCtrl = TextEditingController();
  final TextEditingController _conceptionFailuresCtrl = TextEditingController();

  String _heiferOrCow = 'cow';
  String _pregnancyStatus = 'open';
  String _healthStatus = 'stable';
  String _breedingGoal = 'balanced';

  bool _feverFlag = false;
  bool _lamenessFlag = false;
  bool _mastitisHistory = false;
  bool _medicationOngoing = false;
  bool _previousCalvingDifficulty = false;

  BreedingRecommendationResult? _result;

  @override
  void dispose() {
    _breedCtrl.dispose();
    _parityCtrl.dispose();
    _daysPostpartumCtrl.dispose();
    _inseminationCountCtrl.dispose();
    _conceptionFailuresCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialPrefill) return;

    final cows = context.read<AppState>().cows;
    if (cows.isEmpty) return;

    Cow? chosenCow;

    if (widget.selectedCowId != null) {
      try {
        chosenCow = cows.firstWhere((c) => c.id == widget.selectedCowId);
      } catch (_) {
        chosenCow = null;
      }
    }

    chosenCow ??= cows.first;

    _selectedCowId = chosenCow.id;
    _prefillFromCow(chosenCow);
    _didInitialPrefill = true;
  }

  String _inferHeiferOrCow(Cow cow) {
    if (cow.parity == 0 && cow.ageYears < 2.2) {
      return 'heifer';
    }
    return 'cow';
  }

  String _inferHealthStatus(Cow cow) {
    final status = cow.healthStatus.trim().toLowerCase();
    final temp = cow.vitals.tempC;

    if (status.contains('healthy')) {
      if (temp != null && temp >= 39.6) return 'monitoring';
      return 'stable';
    }

    if (status.contains('fever') ||
        status.contains('salmon') ||
        status.contains('respiratory') ||
        status.contains('heart')) {
      return 'sick';
    }

    return 'monitoring';
  }

  int _inferDaysPostpartum(Cow cow, String animalType) {
    if (animalType == 'heifer') return 0;

    int days;

    if (cow.parity <= 1) {
      days = 60;
    } else if (cow.parity == 2) {
      days = 72;
    } else {
      days = 85;
    }

    final conceptionRate = cow.fertility.conceptionRate;
    if (conceptionRate < 0.35) {
      days += 15;
    } else if (conceptionRate < 0.50) {
      days += 8;
    }

    final bcs = cow.fertility.bodyConditionScore;
    if (bcs < 2.5 || bcs > 4.0) {
      days += 10;
    }

    final health = _inferHealthStatus(cow);
    if (health == 'sick') {
      days += 10;
    } else if (health == 'monitoring') {
      days += 5;
    }

    return days.clamp(45, 150).toInt();
  }

  int _inferInseminationCount(Cow cow, String animalType) {
    final conceptionRate = cow.fertility.conceptionRate;
    int count;

    if (animalType == 'heifer') {
      count = conceptionRate >= 0.60 ? 1 : 2;
    } else if (conceptionRate >= 0.60) {
      count = 1;
    } else if (conceptionRate >= 0.40) {
      count = 2;
    } else if (conceptionRate >= 0.25) {
      count = 3;
    } else {
      count = 4;
    }

    if (cow.parity >= 4 && count < 5) {
      count += 1;
    }

    return count.clamp(1, 5).toInt();
  }

  int _inferConceptionFailures(Cow cow, int inseminationCount) {
    final conceptionRate = cow.fertility.conceptionRate;
    int failures;

    if (inseminationCount <= 1 && conceptionRate >= 0.60) {
      failures = 0;
    } else if (conceptionRate >= 0.60) {
      failures = 1;
    } else if (conceptionRate >= 0.40) {
      failures = inseminationCount - 1;
    } else if (conceptionRate >= 0.25) {
      failures = inseminationCount - 1;
    } else {
      failures = inseminationCount;
    }

    if (cow.fertility.inbreedingRisk.toLowerCase() == 'high' && failures < inseminationCount) {
      failures += 1;
    }

    if (failures < 0) failures = 0;
    if (failures > inseminationCount) failures = inseminationCount;

    return failures;
  }

  bool _inferFeverFlag(Cow cow) {
    final status = cow.healthStatus.toLowerCase();
    final temp = cow.vitals.tempC;
    return status.contains('fever') || (temp != null && temp >= 39.6);
  }

  bool _inferLamenessFlag(Cow cow) {
    final status = cow.healthStatus.toLowerCase();
    return status.contains('lameness');
  }

  bool _inferMastitisHistory(Cow cow) {
    final status = cow.healthStatus.toLowerCase();
    return status.contains('mastitis');
  }

  bool _inferMedicationOngoing(Cow cow) {
    final status = cow.healthStatus.toLowerCase();
    return status.contains('salmon') ||
        status.contains('respiratory') ||
        status.contains('heart');
  }

  bool _inferPreviousCalvingDifficulty(Cow cow) {
    return cow.parity >= 3 &&
        cow.fertility.inbreedingRisk.toLowerCase() == 'high';
  }

  String _inferBreedingGoal(Cow cow, String animalType) {
    if (animalType == 'heifer') {
      return 'safer_calving';
    }

    final conceptionRate = cow.fertility.conceptionRate;
    final risk = cow.fertility.inbreedingRisk.toLowerCase();
    final health = cow.healthStatus.toLowerCase();

    if (risk == 'high') {
      return 'inbreeding';
    }
    if (conceptionRate < 0.40) {
      return 'fertility';
    }
    if (health.contains('fever') ||
        health.contains('respiratory') ||
        health.contains('heart') ||
        health.contains('salmon')) {
      return 'health';
    }
    return 'balanced';
  }

  void _prefillFromCow(Cow cow) {
    final animalType = _inferHeiferOrCow(cow);
    final health = _inferHealthStatus(cow);
    final inseminationCount = _inferInseminationCount(cow, animalType);
    final conceptionFailures = _inferConceptionFailures(cow, inseminationCount);
    final daysPostpartum = _inferDaysPostpartum(cow, animalType);

    _breedCtrl.text = cow.breed;
    _parityCtrl.text = '${cow.parity}';

    _heiferOrCow = animalType;
    _pregnancyStatus = 'open';
    _healthStatus = health;
    _daysPostpartumCtrl.text = '$daysPostpartum';
    _inseminationCountCtrl.text = '$inseminationCount';
    _conceptionFailuresCtrl.text = '$conceptionFailures';

    _feverFlag = _inferFeverFlag(cow);
    _lamenessFlag = _inferLamenessFlag(cow);
    _mastitisHistory = _inferMastitisHistory(cow);
    _medicationOngoing = _inferMedicationOngoing(cow);
    _previousCalvingDifficulty = _inferPreviousCalvingDifficulty(cow);
    _breedingGoal = _inferBreedingGoal(cow, animalType);

    _result = null;
  }

  Cow? _selectedCow(List<Cow> cows) {
    try {
      return cows.firstWhere((c) => c.id == _selectedCowId);
    } catch (_) {
      return cows.isNotEmpty ? cows.first : null;
    }
  }

  int _parseInt(TextEditingController controller, {int fallback = 0}) {
    return int.tryParse(controller.text.trim()) ?? fallback;
  }

  void _generateRecommendation(List<Cow> cows) {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final cow = _selectedCow(cows);
    if (cow == null) return;

    final input = BreedingInput(
      cowId: cow.id,
      breed: _breedCtrl.text.trim(),
      parity: _parseInt(_parityCtrl),
      heiferOrCow: _heiferOrCow,
      daysPostpartum: _parseInt(_daysPostpartumCtrl),
      inseminationCount: _parseInt(_inseminationCountCtrl),
      conceptionFailures: _parseInt(_conceptionFailuresCtrl),
      pregnancyStatus: _pregnancyStatus,
      healthStatus: _healthStatus,
      feverFlag: _feverFlag,
      lamenessFlag: _lamenessFlag,
      mastitisHistory: _mastitisHistory,
      medicationOngoing: _medicationOngoing,
      previousCalvingDifficulty: _previousCalvingDifficulty,
      breedingGoal: _breedingGoal,
    );

    final result = _service.generateRecommendation(
      input: input,
      sires: breedingSires,
    );

    setState(() {
      _result = result;
    });
  }

  String _goalLabel(String goal) {
    switch (goal) {
      case 'fertility':
        return 'Improve fertility';
      case 'safer_calving':
        return 'Safer calving';
      case 'health':
        return 'Better daughter health';
      case 'udder':
        return 'Udder traits';
      case 'inbreeding':
        return 'Avoid inbreeding';
      default:
        return 'Balanced';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cows = state.cows;
    final selectedCow = _selectedCow(cows);

    return Scaffold(
      backgroundColor: LivTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Breeding Recommender'),
      ),
      body: cows.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No cows available yet. Add or sync cows first to generate breeding recommendations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: LivTheme.muted,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Breeding Recommender',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: LivTheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Generate sire recommendations using the richer web-style rule engine, now inside the mobile app.',
                  style: TextStyle(
                    fontSize: 13,
                    color: LivTheme.muted,
                  ),
                ),
                const SizedBox(height: 16),

                _SectionCard(
                  title: '1. Select cow',
                  child: DropdownButtonFormField<String>(
                    value: _selectedCowId,
                    decoration: const InputDecoration(
                      labelText: 'Cow',
                      border: OutlineInputBorder(),
                    ),
                    items: cows
                        .map(
                          (cow) => DropdownMenuItem<String>(
                            value: cow.id,
                            child: Text('${cow.name} (${cow.id})'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      final cow = cows.firstWhere((c) => c.id == value);
                      setState(() {
                        _selectedCowId = value;
                        _prefillFromCow(cow);
                      });
                    },
                  ),
                ),

                const SizedBox(height: 12),

                if (selectedCow != null)
                  _SelectedCowSnapshot(cow: selectedCow),

                const SizedBox(height: 12),

                _SectionCard(
                  title: '2. Breeding inputs',
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _breedCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Breed',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Breed is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _parityCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Parity',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse((value ?? '').trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter a valid parity';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _heiferOrCow,
                                decoration: const InputDecoration(
                                  labelText: 'Animal type',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'heifer',
                                    child: Text('Heifer'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'cow',
                                    child: Text('Cow'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _heiferOrCow = value);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _pregnancyStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Pregnancy status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'open',
                                    child: Text('Open'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'pregnant',
                                    child: Text('Pregnant'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _pregnancyStatus = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _daysPostpartumCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Days postpartum',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse((value ?? '').trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter a valid value';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _healthStatus,
                                decoration: const InputDecoration(
                                  labelText: 'Health status',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'stable',
                                    child: Text('Stable'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'monitoring',
                                    child: Text('Monitoring'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'sick',
                                    child: Text('Sick'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _healthStatus = value);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _inseminationCountCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Insemination count',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse((value ?? '').trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter a valid count';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _conceptionFailuresCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Conception failures',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse((value ?? '').trim());
                                  if (parsed == null || parsed < 0) {
                                    return 'Enter a valid count';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        DropdownButtonFormField<String>(
                          value: _breedingGoal,
                          decoration: const InputDecoration(
                            labelText: 'Breeding goal',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'balanced',
                              child: Text('Balanced'),
                            ),
                            DropdownMenuItem(
                              value: 'fertility',
                              child: Text('Improve fertility'),
                            ),
                            DropdownMenuItem(
                              value: 'safer_calving',
                              child: Text('Safer calving'),
                            ),
                            DropdownMenuItem(
                              value: 'health',
                              child: Text('Better daughter health'),
                            ),
                            DropdownMenuItem(
                              value: 'udder',
                              child: Text('Udder traits'),
                            ),
                            DropdownMenuItem(
                              value: 'inbreeding',
                              child: Text('Avoid inbreeding'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _breedingGoal = value);
                          },
                        ),
                        const SizedBox(height: 16),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Clinical / risk flags',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: LivTheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        SwitchListTile(
                          value: _feverFlag,
                          onChanged: (value) => setState(() => _feverFlag = value),
                          title: const Text('Fever flag'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          value: _lamenessFlag,
                          onChanged: (value) =>
                              setState(() => _lamenessFlag = value),
                          title: const Text('Lameness flag'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          value: _mastitisHistory,
                          onChanged: (value) =>
                              setState(() => _mastitisHistory = value),
                          title: const Text('Mastitis history'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          value: _medicationOngoing,
                          onChanged: (value) =>
                              setState(() => _medicationOngoing = value),
                          title: const Text('Medication ongoing'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        SwitchListTile(
                          value: _previousCalvingDifficulty,
                          onChanged: (value) => setState(
                            () => _previousCalvingDifficulty = value,
                          ),
                          title: const Text('Previous calving difficulty'),
                          contentPadding: EdgeInsets.zero,
                        ),

                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () => _generateRecommendation(cows),
                            icon: const Icon(Icons.auto_awesome),
                            label: const Text('Generate recommendation'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                if (_result != null) ...[
                  _EligibilityCard(result: _result!),
                  const SizedBox(height: 12),
                  _RiskFlagsCard(result: _result!),
                  const SizedBox(height: 12),
                  _FinalChoiceCard(
                    result: _result!,
                    goalLabel: _goalLabel(_result!.goal),
                  ),
                  const SizedBox(height: 12),
                  _TopCandidatesCard(result: _result!),
                ],
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: LivTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
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
            child,
          ],
        ),
      ),
    );
  }
}

class _SelectedCowSnapshot extends StatelessWidget {
  final Cow cow;

  const _SelectedCowSnapshot({
    required this.cow,
  });

  String _statusColorLabel(String status) {
    final s = status.toLowerCase();
    if (s == 'healthy') return 'Healthy';
    return status;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: LivTheme.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cow snapshot',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: LivTheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MiniInfoChip(label: 'Cow', value: cow.name),
                _MiniInfoChip(label: 'ID', value: cow.id),
                _MiniInfoChip(label: 'Breed', value: cow.breed),
                _MiniInfoChip(label: 'Parity', value: '${cow.parity}'),
                _MiniInfoChip(
                  label: 'Health',
                  value: _statusColorLabel(cow.healthStatus),
                ),
                _MiniInfoChip(
                  label: 'Conception',
                  value:
                      '${(cow.fertility.conceptionRate * 100).toStringAsFixed(0)}%',
                ),
                _MiniInfoChip(
                  label: 'BCS',
                  value: cow.fertility.bodyConditionScore.toStringAsFixed(1),
                ),
                _MiniInfoChip(
                  label: 'Inbreeding',
                  value: cow.fertility.inbreedingRisk,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniInfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LivTheme.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: LivTheme.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: LivTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

class _EligibilityCard extends StatelessWidget {
  final BreedingRecommendationResult result;

  const _EligibilityCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final ok = result.eligibleNow;
    final color = ok ? LivTheme.ok : LivTheme.danger;

    return Card(
      color: color.withOpacity(0.08),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color.withOpacity(0.35)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              ok ? Icons.check_circle : Icons.warning_amber_rounded,
              color: color,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ok ? 'Eligible now' : 'Not eligible now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.eligibilityReason,
                    style: const TextStyle(
                      color: LivTheme.text,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RiskFlagsCard extends StatelessWidget {
  final BreedingRecommendationResult result;

  const _RiskFlagsCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Risk flags',
      child: result.riskFlags.isEmpty
          ? const Text(
              'No major risk flags detected from the provided inputs.',
              style: TextStyle(color: LivTheme.muted),
            )
          : Column(
              children: result.riskFlags
                  .map(
                    (flag) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: LivTheme.line),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.flag_outlined,
                            color: LivTheme.gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              flag,
                              style: const TextStyle(
                                color: LivTheme.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
    );
  }
}

class _FinalChoiceCard extends StatelessWidget {
  final BreedingRecommendationResult result;
  final String goalLabel;

  const _FinalChoiceCard({
    required this.result,
    required this.goalLabel,
  });

  @override
  Widget build(BuildContext context) {
    final choice = result.finalChoice;

    return _SectionCard(
      title: 'Final recommendation',
      child: choice == null
          ? const Text(
              'No final sire was selected from the current candidate pool.',
              style: TextStyle(color: LivTheme.muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
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
                      const Text(
                        'Best sire match',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${choice.name} (${choice.shortCode})',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Match score: ${choice.matchScore.toStringAsFixed(1)} / 100',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Goal: $goalLabel',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  result.finalSummary,
                  style: const TextStyle(
                    color: LivTheme.text,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniInfoChip(
                      label: 'Fertility index',
                      value: choice.metrics.fertilityIndex.toStringAsFixed(1),
                    ),
                    _MiniInfoChip(
                      label: 'DPR',
                      value: choice.metrics.daughterPregnancyRate.toStringAsFixed(1),
                    ),
                    _MiniInfoChip(
                      label: 'Calving ease',
                      value: choice.metrics.sireCalvingEase.toStringAsFixed(1),
                    ),
                    _MiniInfoChip(
                      label: 'Stillbirth',
                      value: choice.metrics.sireStillbirth.toStringAsFixed(1),
                    ),
                    _MiniInfoChip(
                      label: 'SCS',
                      value: choice.metrics.somaticCellScore.toStringAsFixed(2),
                    ),
                    _MiniInfoChip(
                      label: 'Livability',
                      value: choice.metrics.livability.toStringAsFixed(1),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Why this sire?',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: LivTheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                ...choice.reasons.map(
                  (reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.check_circle_outline,
                          color: LivTheme.ok,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _TopCandidatesCard extends StatelessWidget {
  final BreedingRecommendationResult result;

  const _TopCandidatesCard({
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Top candidates',
      child: result.topCandidates.isEmpty
          ? const Text(
              'No candidates available.',
              style: TextStyle(color: LivTheme.muted),
            )
          : Column(
              children: result.topCandidates.asMap().entries.map((entry) {
                final index = entry.key + 1;
                final candidate = entry.value;

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: LivTheme.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 15,
                            backgroundColor: LivTheme.primary.withOpacity(0.10),
                            child: Text(
                              '$index',
                              style: const TextStyle(
                                color: LivTheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${candidate.name} (${candidate.shortCode})',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: LivTheme.primary,
                              ),
                            ),
                          ),
                          Text(
                            '${candidate.matchScore.toStringAsFixed(1)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: LivTheme.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _MiniInfoChip(
                            label: 'FI',
                            value: candidate.metrics.fertilityIndex.toStringAsFixed(1),
                          ),
                          _MiniInfoChip(
                            label: 'CCR',
                            value: candidate.metrics.cowConceptionRate.toStringAsFixed(1),
                          ),
                          _MiniInfoChip(
                            label: 'HCR',
                            value: candidate.metrics.heiferConceptionRate.toStringAsFixed(1),
                          ),
                          _MiniInfoChip(
                            label: 'SCE',
                            value: candidate.metrics.sireCalvingEase.toStringAsFixed(1),
                          ),
                          _MiniInfoChip(
                            label: 'PL',
                            value: candidate.metrics.productiveLife.toStringAsFixed(1),
                          ),
                          _MiniInfoChip(
                            label: 'Udder',
                            value: candidate.metrics.udderComposite.toStringAsFixed(2),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...candidate.reasons.map(
                        (reason) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• '),
                              Expanded(child: Text(reason)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
    );
  }
}