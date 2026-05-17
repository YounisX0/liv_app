import 'dart:math' as math;

import '../models/breeding_models.dart';

class BreedingRecommenderService {
  const BreedingRecommenderService();

  BreedingRecommendationResult generateRecommendation({
    required BreedingInput input,
    required List<RichSireProfile> sires,
  }) {
    final normalizedInput = normalizeInput(input);
    final eligibility = evaluateEligibility(normalizedInput);
    final riskFlags = buildRiskFlags(normalizedInput);

    if (!eligibility.eligibleNow) {
      return BreedingRecommendationResult(
        eligibleNow: false,
        eligibilityReason: eligibility.reason,
        goal: normalizeGoal(normalizedInput.breedingGoal),
        riskFlags: riskFlags,
        topCandidates: const [],
        finalChoice: null,
        finalSummary: buildIneligibleSummary(normalizedInput, eligibility.reason),
        candidatePoolSize: 0,
        generatedAt: DateTime.now(),
        input: normalizedInput,
      );
    }

    final goal = normalizeGoal(normalizedInput.breedingGoal);
    final filtered = filterCandidates(normalizedInput, sires);
    final usable = filtered.isNotEmpty ? filtered : sires;
    final ranges = buildRanges(usable);
    final weights = getWeights(goal, normalizedInput);

    final ranked = usable.map((sire) {
      final fertilityBlend = _buildFertilityBlend(usable, sire, ranges);

      final score = weightedAverage([
        WeightedScore(
          score: fertilityBlend,
          weight: weights.fertility + weights.dpr + weights.conception,
        ),
        WeightedScore(
          score: scoreLowerBetter(
            sire.metrics.sireCalvingEase,
            ranges['sireCalvingEase']!,
          ),
          weight: weights.calvingEase,
        ),
        WeightedScore(
          score: scoreLowerBetter(
            sire.metrics.sireStillbirth,
            ranges['sireStillbirth']!,
          ),
          weight: weights.stillbirth,
        ),
        WeightedScore(
          score: scoreHigherBetter(
            sire.metrics.livability,
            ranges['livability']!,
          ),
          weight: weights.livability,
        ),
        WeightedScore(
          score: scoreLowerBetter(
            sire.metrics.somaticCellScore,
            ranges['somaticCellScore']!,
          ),
          weight: weights.somaticCell,
        ),
        WeightedScore(
          score: scoreHigherBetter(
            sire.metrics.udderComposite,
            ranges['udderComposite']!,
          ),
          weight: weights.udder,
        ),
        WeightedScore(
          score: scoreHigherBetter(
            sire.metrics.feetLegsScore,
            ranges['feetLegsScore']!,
          ),
          weight: weights.feetLegs,
        ),
        WeightedScore(
          score: scoreHigherBetter(
            sire.metrics.productiveLife,
            ranges['productiveLife']!,
          ),
          weight: weights.productiveLife,
        ),
      ]);

      return BreedingCandidate.fromProfile(
        sire: sire,
        matchScore: double.parse(score.toStringAsFixed(2)),
        reasons: explainCandidate(normalizedInput, sire),
      );
    }).toList()
      ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    final finalChoice = ranked.isNotEmpty ? ranked.first : null;

    return BreedingRecommendationResult(
      eligibleNow: true,
      eligibilityReason: eligibility.reason,
      goal: goal,
      riskFlags: riskFlags,
      topCandidates: ranked.take(3).toList(),
      finalChoice: finalChoice,
      finalSummary: buildFinalSummary(
        cow: normalizedInput,
        finalChoice: finalChoice,
        goal: goal,
      ),
      candidatePoolSize: usable.length,
      generatedAt: DateTime.now(),
      input: normalizedInput,
    );
  }

  BreedingInput normalizeInput(BreedingInput input) {
    var parity = math.max(0, input.parity);
    var daysPostpartum = math.max(0, input.daysPostpartum);
    var inseminationCount = math.max(0, input.inseminationCount);
    var conceptionFailures = math.max(0, input.conceptionFailures);

    var heiferOrCow = input.heiferOrCow.trim().toLowerCase();
    if (heiferOrCow != 'heifer' && heiferOrCow != 'cow') {
      heiferOrCow = parity == 0 ? 'heifer' : 'cow';
    }

    if (heiferOrCow == 'heifer' && parity > 0) {
      heiferOrCow = 'cow';
    }

    var previousCalvingDifficulty = input.previousCalvingDifficulty;
    if (heiferOrCow == 'heifer') {
      daysPostpartum = 0;
      previousCalvingDifficulty = false;
    }

    if (conceptionFailures > inseminationCount) {
      if (inseminationCount == 0 && conceptionFailures > 0) {
        inseminationCount = conceptionFailures;
      } else {
        conceptionFailures = inseminationCount;
      }
    }

    var pregnancyStatus = input.pregnancyStatus.trim().toLowerCase();
    if (pregnancyStatus != 'open' && pregnancyStatus != 'pregnant') {
      pregnancyStatus = 'open';
    }

    var healthStatus = input.healthStatus.trim().toLowerCase();
    if (healthStatus != 'stable' &&
        healthStatus != 'monitoring' &&
        healthStatus != 'sick') {
      healthStatus = 'stable';
    }

    if ((input.feverFlag || input.medicationOngoing) && healthStatus == 'stable') {
      healthStatus = 'sick';
    }

    var breedingGoal = normalizeGoal(input.breedingGoal);

    if (healthStatus == 'sick' && breedingGoal == 'balanced') {
      breedingGoal = 'health';
    }

    if (previousCalvingDifficulty && breedingGoal == 'balanced') {
      breedingGoal = 'safer_calving';
    }

    if (conceptionFailures >= 2 && breedingGoal == 'balanced') {
      breedingGoal = 'fertility';
    }

    return input.copyWith(
      parity: parity,
      heiferOrCow: heiferOrCow,
      daysPostpartum: daysPostpartum,
      inseminationCount: inseminationCount,
      conceptionFailures: conceptionFailures,
      pregnancyStatus: pregnancyStatus,
      healthStatus: healthStatus,
      previousCalvingDifficulty: previousCalvingDifficulty,
      breedingGoal: breedingGoal,
    );
  }

  String normalizeGoal(String goal) {
    final value = goal.trim().toLowerCase();

    if (value == 'improve fertility' || value == 'fertility') {
      return 'fertility';
    }
    if (value == 'safer calving' || value == 'calving' || value == 'safer_calving') {
      return 'safer_calving';
    }
    if (value == 'better daughter health' || value == 'health') {
      return 'health';
    }
    if (value == 'udder traits' || value == 'udder') {
      return 'udder';
    }
    if (value == 'avoid inbreeding' || value == 'inbreeding') {
      return 'inbreeding';
    }
    return 'balanced';
  }

  BreedingWeights getWeights(String goal, BreedingInput cow) {
    var base = const BreedingWeights(
      fertility: 0.27,
      dpr: 0.16,
      conception: 0.12,
      calvingEase: 0.18,
      stillbirth: 0.07,
      livability: 0.07,
      somaticCell: 0.05,
      udder: 0.04,
      feetLegs: 0.02,
      productiveLife: 0.02,
    );

    switch (goal) {
      case 'fertility':
        base = base.copyWith(
          fertility: 0.34,
          dpr: 0.20,
          conception: 0.16,
          calvingEase: 0.12,
          stillbirth: 0.05,
        );
        break;
      case 'safer_calving':
        base = base.copyWith(
          fertility: 0.18,
          dpr: 0.10,
          conception: 0.10,
          calvingEase: 0.30,
          stillbirth: 0.14,
          livability: 0.08,
        );
        break;
      case 'health':
        base = base.copyWith(
          fertility: 0.20,
          dpr: 0.10,
          conception: 0.08,
          calvingEase: 0.15,
          stillbirth: 0.07,
          livability: 0.14,
          somaticCell: 0.12,
          productiveLife: 0.08,
        );
        break;
      case 'udder':
        base = base.copyWith(
          fertility: 0.18,
          dpr: 0.10,
          conception: 0.08,
          calvingEase: 0.12,
          stillbirth: 0.06,
          livability: 0.08,
          somaticCell: 0.12,
          udder: 0.18,
          feetLegs: 0.05,
          productiveLife: 0.03,
        );
        break;
      case 'inbreeding':
        base = base.copyWith(
          fertility: 0.22,
          dpr: 0.12,
          conception: 0.10,
          calvingEase: 0.16,
          stillbirth: 0.08,
          livability: 0.08,
          somaticCell: 0.08,
          udder: 0.06,
          feetLegs: 0.05,
          productiveLife: 0.05,
        );
        break;
      default:
        break;
    }

    if (cow.heiferOrCow.toLowerCase() == 'heifer') {
      base = base.copyWith(
        calvingEase: base.calvingEase + 0.08,
        stillbirth: base.stillbirth + 0.03,
        fertility: base.fertility - 0.05,
        dpr: base.dpr - 0.03,
        conception: base.conception - 0.03,
      );
    }

    if (cow.conceptionFailures >= 2) {
      base = base.copyWith(
        fertility: base.fertility + 0.06,
        dpr: base.dpr + 0.04,
        conception: base.conception + 0.04,
        calvingEase: base.calvingEase - 0.05,
        stillbirth: base.stillbirth - 0.03,
      );
    }

    if (cow.mastitisHistory) {
      base = base.copyWith(
        somaticCell: base.somaticCell + 0.08,
        udder: base.udder + 0.04,
        fertility: base.fertility - 0.06,
        dpr: base.dpr - 0.03,
        productiveLife: base.productiveLife - 0.03,
      );
    }

    return base;
  }

  List<String> buildRiskFlags(BreedingInput cow) {
    final flags = <String>[];

    if (cow.conceptionFailures >= 2) {
      flags.add(
        'Repeated conception failures: prioritize stronger fertility sires.',
      );
    }
    if (cow.previousCalvingDifficulty) {
      flags.add(
        'Previous calving difficulty: avoid sires with weaker calving ease or higher stillbirth rates.',
      );
    }
    if (cow.mastitisHistory) {
      flags.add(
        'Mastitis history: favor sires with better udder health and lower somatic cell score.',
      );
    }
    if (cow.lamenessFlag) {
      flags.add(
        'Lameness flag: review locomotion and insemination timing carefully.',
      );
    }
    if (cow.heiferOrCow.toLowerCase() == 'heifer') {
      flags.add('Heifer profile detected: calving ease is weighted more heavily.');
    }
    if (cow.healthStatus.toLowerCase() == 'monitoring') {
      flags.add(
        'Health monitoring status: recommendation should be interpreted cautiously.',
      );
    }
    if (cow.pregnancyStatus.toLowerCase() == 'pregnant') {
      flags.add(
        'Pregnancy detected: breeding recommendation should be deferred.',
      );
    }
    if (cow.breedingGoal == 'inbreeding') {
      flags.add(
        'Pedigree review is still required because this rule engine does not compute genomic inbreeding directly.',
      );
    }

    return flags;
  }

  BreedingEligibilityResult evaluateEligibility(BreedingInput cow) {
    if (cow.pregnancyStatus.toLowerCase() == 'pregnant') {
      return const BreedingEligibilityResult(
        eligibleNow: false,
        reason: 'Cow is already pregnant.',
      );
    }

    if (cow.healthStatus.toLowerCase() == 'sick') {
      return const BreedingEligibilityResult(
        eligibleNow: false,
        reason: 'Cow health is not stable enough for breeding recommendation.',
      );
    }

    if (cow.feverFlag) {
      return const BreedingEligibilityResult(
        eligibleNow: false,
        reason: 'Fever flag is active; postpone breeding until health stabilizes.',
      );
    }

    if (cow.medicationOngoing) {
      return const BreedingEligibilityResult(
        eligibleNow: false,
        reason:
            'Medication/treatment is ongoing; breeding should be reviewed by a vet first.',
      );
    }

    if (cow.heiferOrCow.toLowerCase() == 'cow' && cow.daysPostpartum < 45) {
      return const BreedingEligibilityResult(
        eligibleNow: false,
        reason: 'Days postpartum are too low for a confident recommendation.',
      );
    }

    return const BreedingEligibilityResult(
      eligibleNow: true,
      reason: 'Cow is eligible for breeding recommendation under current inputs.',
    );
  }

  List<RichSireProfile> filterCandidates(
    BreedingInput cow,
    List<RichSireProfile> sires,
  ) {
    return sires.where((sire) {
      if (cow.previousCalvingDifficulty && sire.metrics.sireStillbirth > 4.6) {
        return false;
      }

      if (cow.heiferOrCow.toLowerCase() == 'heifer' &&
          sire.metrics.sireCalvingEase > 1.8) {
        return false;
      }

      if (cow.conceptionFailures >= 2 && sire.metrics.fertilityIndex < 0) {
        return false;
      }

      if (cow.conceptionFailures >= 3 && sire.metrics.daughterPregnancyRate < 0) {
        return false;
      }

      if (cow.mastitisHistory && sire.metrics.somaticCellScore > 3.1) {
        return false;
      }

      return true;
    }).toList();
  }

  List<String> explainCandidate(BreedingInput cow, RichSireProfile sire) {
    final reasons = <String>[];

    if (sire.metrics.fertilityIndex >= 0.8) {
      reasons.add('strong fertility index');
    }
    if (sire.metrics.daughterPregnancyRate >= 0.5) {
      reasons.add('good daughter pregnancy rate');
    }
    if (sire.metrics.sireCalvingEase <= 1.5) {
      reasons.add('easy-calving profile');
    }
    if (sire.metrics.sireStillbirth <= 4.0) {
      reasons.add('lower stillbirth risk');
    }
    if (sire.metrics.somaticCellScore < 3.0) {
      reasons.add('favorable udder health / somatic cell score');
    }
    if (sire.metrics.livability >= 0.5) {
      reasons.add('strong livability support');
    }

    if (cow.heiferOrCow == 'heifer' && sire.metrics.sireCalvingEase <= 1.5) {
      reasons.add('well suited for heifer mating due to safer calving profile');
    }

    if (cow.previousCalvingDifficulty && sire.metrics.sireCalvingEase <= 1.5) {
      reasons.add('safer option for previous calving difficulty');
    }

    if (cow.mastitisHistory && sire.metrics.somaticCellScore < 3.0) {
      reasons.add('fits mastitis-history caution');
    }

    if (cow.conceptionFailures >= 2 &&
        (sire.metrics.fertilityIndex >= 0.8 ||
            sire.metrics.daughterPregnancyRate >= 0.5)) {
      reasons.add('supports a repeat-breeder style fertility strategy');
    }

    if (cow.breedingGoal == 'udder' && sire.metrics.udderComposite >= 0.8) {
      reasons.add('supports udder improvement goal');
    }

    if (cow.breedingGoal == 'health' &&
        sire.metrics.livability >= 0.5 &&
        sire.metrics.somaticCellScore < 3.0) {
      reasons.add('supports daughter health and survivability focus');
    }

    if (cow.breedingGoal == 'inbreeding') {
      reasons.add('balanced functional profile, but pedigree review is still required');
    }

    if (reasons.isEmpty) {
      reasons.add('balanced overall profile for this cow');
    }

    return reasons;
  }

  String buildIneligibleSummary(BreedingInput cow, String reason) {
    if (cow.pregnancyStatus == 'pregnant') {
      return 'This cow is already pregnant, so breeding should not be recommended again at this stage.';
    }
    if (cow.feverFlag) {
      return 'Breeding is blocked because an active fever signal suggests the cow should recover before insemination planning.';
    }
    if (cow.medicationOngoing) {
      return 'Breeding is blocked because treatment is still ongoing and veterinary review should come first.';
    }
    if (cow.healthStatus == 'sick') {
      return 'Breeding is blocked because the current health condition is not stable enough for a reliable recommendation.';
    }
    if (cow.heiferOrCow == 'cow' && cow.daysPostpartum < 45) {
      return 'Breeding is blocked because the postpartum window is still too early for a confident recommendation.';
    }
    return reason;
  }

  String buildFinalSummary({
    required BreedingInput cow,
    required BreedingCandidate? finalChoice,
    required String goal,
  }) {
    if (finalChoice == null) {
      return 'No suitable sire was found from the current sample catalog for this cow under the present breeding conditions.';
    }

    if (cow.heiferOrCow == 'heifer' || goal == 'safer_calving') {
      return '${finalChoice.shortCode} is recommended because its calving-ease and stillbirth profile make it a safer match for this case.';
    }

    if (cow.conceptionFailures >= 2 || goal == 'fertility') {
      return '${finalChoice.shortCode} is recommended because this case needs stronger fertility support, and this sire provides one of the best fertility-oriented profiles in the current catalog.';
    }

    if (cow.mastitisHistory || goal == 'udder') {
      return '${finalChoice.shortCode} is recommended because this case benefits from stronger udder-health emphasis and better somatic-cell control.';
    }

    if (goal == 'health' || cow.healthStatus == 'monitoring') {
      return '${finalChoice.shortCode} is recommended because this case benefits from a more conservative health-oriented profile with stronger survivability support.';
    }

    if (goal == 'inbreeding') {
      return '${finalChoice.shortCode} is the best balanced functional match in the current catalog, but pedigree review is still required because direct inbreeding calculation is outside this rule engine.';
    }

    return '${finalChoice.shortCode} is the best current match for this cow based on the selected breeding goal and the present reproductive inputs.';
  }

  double _buildFertilityBlend(
    List<RichSireProfile> usable,
    RichSireProfile sire,
    Map<String, MetricRange> ranges,
  ) {
    final blendedValues = usable
        .map(
          (x) =>
              ((x.metrics.cowConceptionRate) + (x.metrics.heiferConceptionRate)) /
              2,
        )
        .toList();

    final blendedRange = MetricRange(
      min: blendedValues.reduce(math.min),
      max: blendedValues.reduce(math.max),
    );

    return scoreHigherBetter(
              sire.metrics.fertilityIndex,
              ranges['fertilityIndex']!,
            ) *
            0.5 +
        scoreHigherBetter(
              sire.metrics.daughterPregnancyRate,
              ranges['daughterPregnancyRate']!,
            ) *
            0.3 +
        scoreHigherBetter(
              (sire.metrics.cowConceptionRate + sire.metrics.heiferConceptionRate) /
                  2,
              blendedRange,
            ) *
            0.2;
  }

  Map<String, MetricRange> buildRanges(List<RichSireProfile> candidates) {
    const keys = [
      'fertilityIndex',
      'daughterPregnancyRate',
      'cowConceptionRate',
      'heiferConceptionRate',
      'sireCalvingEase',
      'sireStillbirth',
      'livability',
      'somaticCellScore',
      'udderComposite',
      'feetLegsScore',
      'productiveLife',
      'nm\$',
      'milkLbs',
    ];

    final ranges = <String, MetricRange>{};

    for (final key in keys) {
      final values = candidates
          .map((candidate) => _metricValue(candidate, key))
          .whereType<double>()
          .toList();

      ranges[key] = MetricRange(
        min: values.reduce(math.min),
        max: values.reduce(math.max),
      );
    }

    return ranges;
  }

  double _metricValue(RichSireProfile sire, String key) {
    switch (key) {
      case 'fertilityIndex':
        return sire.metrics.fertilityIndex;
      case 'daughterPregnancyRate':
        return sire.metrics.daughterPregnancyRate;
      case 'cowConceptionRate':
        return sire.metrics.cowConceptionRate;
      case 'heiferConceptionRate':
        return sire.metrics.heiferConceptionRate;
      case 'sireCalvingEase':
        return sire.metrics.sireCalvingEase;
      case 'sireStillbirth':
        return sire.metrics.sireStillbirth;
      case 'livability':
        return sire.metrics.livability;
      case 'somaticCellScore':
        return sire.metrics.somaticCellScore;
      case 'udderComposite':
        return sire.metrics.udderComposite;
      case 'feetLegsScore':
        return sire.metrics.feetLegsScore;
      case 'productiveLife':
        return sire.metrics.productiveLife;
      case 'nm\$':
        return sire.metrics.nmDollar;
      case 'milkLbs':
        return sire.metrics.milkLbs;
      default:
        return 0;
    }
  }

  double scoreHigherBetter(double value, MetricRange range) {
    if (range.max == range.min) return 50;
    return clampTo100(((value - range.min) / (range.max - range.min)) * 100);
  }

  double scoreLowerBetter(double value, MetricRange range) {
    if (range.max == range.min) return 50;
    return clampTo100(((range.max - value) / (range.max - range.min)) * 100);
  }

  double weightedAverage(List<WeightedScore> items) {
    final totalWeight =
        items.fold<double>(0, (sum, item) => sum + item.weight);
    if (totalWeight == 0) return 0;

    final weighted =
        items.fold<double>(0, (sum, item) => sum + item.score * item.weight);
    return weighted / totalWeight;
  }

  double clampTo100(double value) {
    return math.max(0, math.min(100, value));
  }
}

class MetricRange {
  final double min;
  final double max;

  const MetricRange({
    required this.min,
    required this.max,
  });
}

class WeightedScore {
  final double score;
  final double weight;

  const WeightedScore({
    required this.score,
    required this.weight,
  });
}