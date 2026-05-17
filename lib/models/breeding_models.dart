class BreedingInput {
  final String cowId;
  final String breed;
  final int parity;
  final String heiferOrCow;
  final int daysPostpartum;
  final int inseminationCount;
  final int conceptionFailures;
  final String pregnancyStatus;
  final String healthStatus;
  final bool feverFlag;
  final bool lamenessFlag;
  final bool mastitisHistory;
  final bool medicationOngoing;
  final bool previousCalvingDifficulty;
  final String breedingGoal;

  const BreedingInput({
    required this.cowId,
    required this.breed,
    required this.parity,
    required this.heiferOrCow,
    required this.daysPostpartum,
    required this.inseminationCount,
    required this.conceptionFailures,
    required this.pregnancyStatus,
    required this.healthStatus,
    required this.feverFlag,
    required this.lamenessFlag,
    required this.mastitisHistory,
    required this.medicationOngoing,
    required this.previousCalvingDifficulty,
    required this.breedingGoal,
  });

  BreedingInput copyWith({
    String? cowId,
    String? breed,
    int? parity,
    String? heiferOrCow,
    int? daysPostpartum,
    int? inseminationCount,
    int? conceptionFailures,
    String? pregnancyStatus,
    String? healthStatus,
    bool? feverFlag,
    bool? lamenessFlag,
    bool? mastitisHistory,
    bool? medicationOngoing,
    bool? previousCalvingDifficulty,
    String? breedingGoal,
  }) {
    return BreedingInput(
      cowId: cowId ?? this.cowId,
      breed: breed ?? this.breed,
      parity: parity ?? this.parity,
      heiferOrCow: heiferOrCow ?? this.heiferOrCow,
      daysPostpartum: daysPostpartum ?? this.daysPostpartum,
      inseminationCount: inseminationCount ?? this.inseminationCount,
      conceptionFailures: conceptionFailures ?? this.conceptionFailures,
      pregnancyStatus: pregnancyStatus ?? this.pregnancyStatus,
      healthStatus: healthStatus ?? this.healthStatus,
      feverFlag: feverFlag ?? this.feverFlag,
      lamenessFlag: lamenessFlag ?? this.lamenessFlag,
      mastitisHistory: mastitisHistory ?? this.mastitisHistory,
      medicationOngoing: medicationOngoing ?? this.medicationOngoing,
      previousCalvingDifficulty:
          previousCalvingDifficulty ?? this.previousCalvingDifficulty,
      breedingGoal: breedingGoal ?? this.breedingGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cowId': cowId,
      'breed': breed,
      'parity': parity,
      'heiferOrCow': heiferOrCow,
      'daysPostpartum': daysPostpartum,
      'inseminationCount': inseminationCount,
      'conceptionFailures': conceptionFailures,
      'pregnancyStatus': pregnancyStatus,
      'healthStatus': healthStatus,
      'feverFlag': feverFlag,
      'lamenessFlag': lamenessFlag,
      'mastitisHistory': mastitisHistory,
      'medicationOngoing': medicationOngoing,
      'previousCalvingDifficulty': previousCalvingDifficulty,
      'breedingGoal': breedingGoal,
    };
  }

  factory BreedingInput.fromJson(Map<String, dynamic> json) {
    return BreedingInput(
      cowId: (json['cowId'] ?? '').toString(),
      breed: (json['breed'] ?? '').toString(),
      parity: (json['parity'] ?? 0) as int,
      heiferOrCow: (json['heiferOrCow'] ?? 'cow').toString(),
      daysPostpartum: (json['daysPostpartum'] ?? 0) as int,
      inseminationCount: (json['inseminationCount'] ?? 0) as int,
      conceptionFailures: (json['conceptionFailures'] ?? 0) as int,
      pregnancyStatus: (json['pregnancyStatus'] ?? 'open').toString(),
      healthStatus: (json['healthStatus'] ?? 'stable').toString(),
      feverFlag: (json['feverFlag'] ?? false) as bool,
      lamenessFlag: (json['lamenessFlag'] ?? false) as bool,
      mastitisHistory: (json['mastitisHistory'] ?? false) as bool,
      medicationOngoing: (json['medicationOngoing'] ?? false) as bool,
      previousCalvingDifficulty:
          (json['previousCalvingDifficulty'] ?? false) as bool,
      breedingGoal: (json['breedingGoal'] ?? 'balanced').toString(),
    );
  }

  factory BreedingInput.initial() {
    return const BreedingInput(
      cowId: 'COW-021',
      breed: 'Holstein',
      parity: 2,
      heiferOrCow: 'cow',
      daysPostpartum: 78,
      inseminationCount: 2,
      conceptionFailures: 1,
      pregnancyStatus: 'open',
      healthStatus: 'stable',
      feverFlag: false,
      lamenessFlag: false,
      mastitisHistory: false,
      medicationOngoing: false,
      previousCalvingDifficulty: false,
      breedingGoal: 'balanced',
    );
  }
}

class RichSireMetrics {
  final double tpi;
  final double nmDollar;
  final double productiveLife;
  final double livability;
  final double fertilityIndex;
  final double daughterPregnancyRate;
  final double cowConceptionRate;
  final double heiferConceptionRate;
  final double sireCalvingEase;
  final double daughterCalvingEase;
  final double sireStillbirth;
  final double daughterStillbirth;
  final double somaticCellScore;
  final double mastitisResistance;
  final double metritisResistance;
  final double ketosisResistance;
  final double feetLegsScore;
  final double udderComposite;
  final double bodyComposite;
  final double milkLbs;
  final double fatLbs;
  final double proteinLbs;

  const RichSireMetrics({
    required this.tpi,
    required this.nmDollar,
    required this.productiveLife,
    required this.livability,
    required this.fertilityIndex,
    required this.daughterPregnancyRate,
    required this.cowConceptionRate,
    required this.heiferConceptionRate,
    required this.sireCalvingEase,
    required this.daughterCalvingEase,
    required this.sireStillbirth,
    required this.daughterStillbirth,
    required this.somaticCellScore,
    required this.mastitisResistance,
    required this.metritisResistance,
    required this.ketosisResistance,
    required this.feetLegsScore,
    required this.udderComposite,
    required this.bodyComposite,
    required this.milkLbs,
    required this.fatLbs,
    required this.proteinLbs,
  });

  Map<String, double> toMetricMap() {
    return {
      'fertilityIndex': fertilityIndex,
      'daughterPregnancyRate': daughterPregnancyRate,
      'cowConceptionRate': cowConceptionRate,
      'heiferConceptionRate': heiferConceptionRate,
      'sireCalvingEase': sireCalvingEase,
      'sireStillbirth': sireStillbirth,
      'livability': livability,
      'somaticCellScore': somaticCellScore,
      'udderComposite': udderComposite,
      'feetLegsScore': feetLegsScore,
      'productiveLife': productiveLife,
      'nm\$': nmDollar,
      'milkLbs': milkLbs,
    };
  }
}

class RichSireProfile {
  final String id;
  final String name;
  final String shortCode;
  final String breed;
  final String source;
  final String sourceUrl;
  final RichSireMetrics metrics;

  const RichSireProfile({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.breed,
    required this.source,
    required this.sourceUrl,
    required this.metrics,
  });
}

class BreedingCandidate {
  final String id;
  final String name;
  final String shortCode;
  final String breed;
  final String source;
  final String sourceUrl;
  final RichSireMetrics metrics;
  final double matchScore;
  final List<String> reasons;

  const BreedingCandidate({
    required this.id,
    required this.name,
    required this.shortCode,
    required this.breed,
    required this.source,
    required this.sourceUrl,
    required this.metrics,
    required this.matchScore,
    required this.reasons,
  });

  factory BreedingCandidate.fromProfile({
    required RichSireProfile sire,
    required double matchScore,
    required List<String> reasons,
  }) {
    return BreedingCandidate(
      id: sire.id,
      name: sire.name,
      shortCode: sire.shortCode,
      breed: sire.breed,
      source: sire.source,
      sourceUrl: sire.sourceUrl,
      metrics: sire.metrics,
      matchScore: matchScore,
      reasons: reasons,
    );
  }
}

class BreedingRecommendationResult {
  final bool eligibleNow;
  final String eligibilityReason;
  final String goal;
  final List<String> riskFlags;
  final List<BreedingCandidate> topCandidates;
  final BreedingCandidate? finalChoice;
  final String finalSummary;
  final int candidatePoolSize;
  final DateTime generatedAt;
  final BreedingInput input;

  const BreedingRecommendationResult({
    required this.eligibleNow,
    required this.eligibilityReason,
    required this.goal,
    required this.riskFlags,
    required this.topCandidates,
    required this.finalChoice,
    required this.finalSummary,
    required this.candidatePoolSize,
    required this.generatedAt,
    required this.input,
  });
}

class BreedingEligibilityResult {
  final bool eligibleNow;
  final String reason;

  const BreedingEligibilityResult({
    required this.eligibleNow,
    required this.reason,
  });
}

class BreedingWeights {
  final double fertility;
  final double dpr;
  final double conception;
  final double calvingEase;
  final double stillbirth;
  final double livability;
  final double somaticCell;
  final double udder;
  final double feetLegs;
  final double productiveLife;

  const BreedingWeights({
    required this.fertility,
    required this.dpr,
    required this.conception,
    required this.calvingEase,
    required this.stillbirth,
    required this.livability,
    required this.somaticCell,
    required this.udder,
    required this.feetLegs,
    required this.productiveLife,
  });

  BreedingWeights copyWith({
    double? fertility,
    double? dpr,
    double? conception,
    double? calvingEase,
    double? stillbirth,
    double? livability,
    double? somaticCell,
    double? udder,
    double? feetLegs,
    double? productiveLife,
  }) {
    return BreedingWeights(
      fertility: fertility ?? this.fertility,
      dpr: dpr ?? this.dpr,
      conception: conception ?? this.conception,
      calvingEase: calvingEase ?? this.calvingEase,
      stillbirth: stillbirth ?? this.stillbirth,
      livability: livability ?? this.livability,
      somaticCell: somaticCell ?? this.somaticCell,
      udder: udder ?? this.udder,
      feetLegs: feetLegs ?? this.feetLegs,
      productiveLife: productiveLife ?? this.productiveLife,
    );
  }
}