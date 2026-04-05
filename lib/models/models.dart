// ─── models.dart ──────────────────────────────────────────────────────────────
// Mirrors the initialState() and server payloads from the web app.

class Vitals {
  final double tempC;
  final double hrBpm;
  final double spO2;
  final double activity;

  const Vitals({
    this.tempC = 38.5,
    this.hrBpm = 78,
    this.spO2 = 96,
    this.activity = 60,
  });

  factory Vitals.fromJson(Map<String, dynamic> j) => Vitals(
        tempC: (j['tempC'] ?? 38.5).toDouble(),
        hrBpm: (j['hrBpm'] ?? 78).toDouble(),
        spO2: (j['spO2'] ?? 96).toDouble(),
        activity: (j['activity'] ?? 60).toDouble(),
      );
}

class Fertility {
  final String lastEstrusDate;
  final int predictedEstrusInDays;
  final int cycleLengthDays;
  final double conceptionRate;
  final double bodyConditionScore;
  final String inbreedingRisk;

  const Fertility({
    this.lastEstrusDate = '',
    this.predictedEstrusInDays = 21,
    this.cycleLengthDays = 21,
    this.conceptionRate = 0.5,
    this.bodyConditionScore = 3.0,
    this.inbreedingRisk = 'Low',
  });

  factory Fertility.fromJson(Map<String, dynamic> j) => Fertility(
        lastEstrusDate: j['lastEstrusDate'] ?? '',
        predictedEstrusInDays: (j['predictedEstrusInDays'] ?? 21).toInt(),
        cycleLengthDays: (j['cycleLengthDays'] ?? 21).toInt(),
        conceptionRate: (j['conceptionRate'] ?? 0.5).toDouble(),
        bodyConditionScore: (j['bodyConditionScore'] ?? 3.0).toDouble(),
        inbreedingRisk: j['inbreedingRisk'] ?? 'Low',
      );
}

class Cow {
  final String id;
  final String name;
  final String breed;
  final double ageYears;
  final int parity;
  final String deviceId;
  final String healthStatus;
  final String lastSeen;
  final Vitals vitals;
  final List<double> vitalsHistory;
  final Fertility fertility;

  const Cow({
    required this.id,
    required this.name,
    this.breed = '',
    this.ageYears = 0,
    this.parity = 0,
    this.deviceId = '',
    this.healthStatus = 'Healthy',
    this.lastSeen = '',
    this.vitals = const Vitals(),
    this.vitalsHistory = const [],
    this.fertility = const Fertility(),
  });

  factory Cow.fromJson(Map<String, dynamic> j) => Cow(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        breed: j['breed'] ?? '',
        ageYears: (j['ageYears'] ?? 0).toDouble(),
        parity: (j['parity'] ?? 0).toInt(),
        deviceId: j['deviceId'] ?? '',
        healthStatus: j['healthStatus'] ?? 'Healthy',
        lastSeen: j['lastSeen'] ?? '',
        vitals: j['vitals'] != null ? Vitals.fromJson(j['vitals']) : const Vitals(),
        vitalsHistory: j['vitalsHistory'] != null
            ? List<double>.from(
                (j['vitalsHistory'] as List).map((e) => (e['v'] ?? e).toDouble()))
            : [],
        fertility: j['fertility'] != null
            ? Fertility.fromJson(j['fertility'])
            : const Fertility(),
      );

  bool get isFertilityReady {
    final bad = ['Fever', 'Heat Stress', 'Low SpO2'].contains(healthStatus);
    if (bad) return false;
    if (fertility.lastEstrusDate.isEmpty) return false;
    final last = DateTime.tryParse(fertility.lastEstrusDate);
    if (last == null) return false;
    final daysAgo = DateTime.now().difference(last).inDays;
    final estrusWindow = daysAgo <= 2 || fertility.predictedEstrusInDays <= 1;
    final bcsOk = fertility.bodyConditionScore >= 2.5;
    return estrusWindow && bcsOk;
  }
}

class Device {
  final String id;
  final int battery;
  final int signal;
  final int lastPacketSecAgo;
  final String status;

  const Device({
    required this.id,
    this.battery = 100,
    this.signal = -70,
    this.lastPacketSecAgo = 0,
    this.status = 'Online',
  });

  factory Device.fromJson(Map<String, dynamic> j) => Device(
        id: j['id'] ?? '',
        battery: (j['battery'] ?? 100).toInt(),
        signal: (j['signal'] ?? -70).toInt(),
        lastPacketSecAgo: (j['lastPacketSecAgo'] ?? 0).toInt(),
        status: j['status'] ?? 'Online',
      );
}

class SireTraits {
  final double fertility;
  final double diseaseResistance;
  final double temperament;
  final double milkYield;
  final double calvingEase;

  const SireTraits({
    this.fertility = 7,
    this.diseaseResistance = 7,
    this.temperament = 7,
    this.milkYield = 7,
    this.calvingEase = 7,
  });

  factory SireTraits.fromJson(Map<String, dynamic> j) => SireTraits(
        fertility: (j['fertility'] ?? 7).toDouble(),
        diseaseResistance: (j['diseaseResistance'] ?? 7).toDouble(),
        temperament: (j['temperament'] ?? 7).toDouble(),
        milkYield: (j['milkYield'] ?? 7).toDouble(),
        calvingEase: (j['calvingEase'] ?? 7).toDouble(),
      );

  double get average =>
      (fertility + diseaseResistance + temperament + milkYield + calvingEase) / 5;
}

class Sire {
  final String id;
  final String name;
  final String semenBatch;
  final SireTraits traits;
  final String notes;

  const Sire({
    required this.id,
    required this.name,
    this.semenBatch = '',
    this.traits = const SireTraits(),
    this.notes = '',
  });

  factory Sire.fromJson(Map<String, dynamic> j) => Sire(
        id: j['id'] ?? '',
        name: j['name'] ?? '',
        semenBatch: j['semenBatch'] ?? '',
        traits: j['traits'] != null ? SireTraits.fromJson(j['traits']) : const SireTraits(),
        notes: j['notes'] ?? '',
      );

  double breedingScore(Cow cow) {
    double score = traits.average;
    if (cow.healthStatus == 'Healthy') score += 0.3;
    if (cow.fertility.bodyConditionScore >= 3.0) score += 0.2;
    if (cow.fertility.inbreedingRisk == 'High') score -= 1.5;
    if (cow.fertility.inbreedingRisk == 'Medium') score -= 0.7;
    return score.clamp(0, 10);
  }
}

class FarmAlert {
  final String id;
  final String severity; // danger | warning | info
  final String title;
  final String cowId;
  final String createdAt;
  final String details;

  const FarmAlert({
    required this.id,
    this.severity = 'info',
    this.title = '',
    this.cowId = '',
    this.createdAt = '',
    this.details = '',
  });

  factory FarmAlert.fromJson(Map<String, dynamic> j) => FarmAlert(
        id: j['id'] ?? '',
        severity: j['severity'] ?? 'info',
        title: j['title'] ?? '',
        cowId: j['cowId'] ?? '',
        createdAt: j['createdAt'] ?? '',
        details: j['details'] ?? '',
      );
}

// ─── Gateway / Telemetry packet ────────────────────────────────────────────────
class TelemetryPacket {
  final double? tempC;
  final double? hrI2c;
  final double? spo2I2c;
  final double? hrUart;
  final double? spo2Uart;
  final double? accelX;
  final double? accelY;
  final double? accelZ;
  final double? gyroX;
  final double? gyroY;
  final double? gyroZ;
  final double? lat;
  final double? lng;
  final String cowId;
  final String deviceId;
  final DateTime receivedAt;

  TelemetryPacket({
    this.tempC,
    this.hrI2c,
    this.spo2I2c,
    this.hrUart,
    this.spo2Uart,
    this.accelX,
    this.accelY,
    this.accelZ,
    this.gyroX,
    this.gyroY,
    this.gyroZ,
    this.lat,
    this.lng,
    this.cowId = '',
    this.deviceId = '',
    DateTime? receivedAt,
  }) : receivedAt = receivedAt ?? DateTime.now();

  factory TelemetryPacket.fromJson(Map<String, dynamic> j) => TelemetryPacket(
        tempC: j['temp_c'] != null ? (j['temp_c']).toDouble() : null,
        hrI2c: j['hr_i2c'] != null ? (j['hr_i2c']).toDouble() : null,
        spo2I2c: j['spo2_i2c'] != null ? (j['spo2_i2c']).toDouble() : null,
        hrUart: j['hr_uart'] != null ? (j['hr_uart']).toDouble() : null,
        spo2Uart: j['spo2_uart'] != null ? (j['spo2_uart']).toDouble() : null,
        accelX: j['accel_x'] != null ? (j['accel_x']).toDouble() : null,
        accelY: j['accel_y'] != null ? (j['accel_y']).toDouble() : null,
        accelZ: j['accel_z'] != null ? (j['accel_z']).toDouble() : null,
        gyroX: j['gyro_x'] != null ? (j['gyro_x']).toDouble() : null,
        gyroY: j['gyro_y'] != null ? (j['gyro_y']).toDouble() : null,
        gyroZ: j['gyro_z'] != null ? (j['gyro_z']).toDouble() : null,
        lat: j['lat'] != null ? (j['lat']).toDouble() : null,
        lng: j['lng'] != null ? (j['lng']).toDouble() : null,
        cowId: j['cow_id'] ?? '',
        deviceId: j['device_id'] ?? '',
      );

  double get accelMag {
    final x = accelX ?? 0;
    final y = accelY ?? 0;
    final z = accelZ ?? 0;
    return _mag(x, y, z);
  }

  double get gyroMag {
    final x = gyroX ?? 0;
    final y = gyroY ?? 0;
    final z = gyroZ ?? 0;
    return _mag(x, y, z);
  }

  double _mag(double x, double y, double z) =>
      (x * x + y * y + z * z) > 0
          ? (x * x + y * y + z * z) < 1e20
              ? (x * x + y * y + z * z) > 0
                  ? _sqrt(x * x + y * y + z * z)
                  : 0
              : 0
          : 0;

  double _sqrt(double v) {
    if (v <= 0) return 0;
    double x = v;
    for (int i = 0; i < 20; i++) x = (x + v / x) / 2;
    return x;
  }
}

// ─── Demo seed data (mirrors initialState() in cloud.html) ────────────────────
class DemoData {
  static List<Cow> cows() {
    final now = DateTime.now();
    day(int d) => now.subtract(Duration(days: d)).toIso8601String();

    return [
      Cow(
        id: 'COW-101',
        name: 'Daisy',
        breed: 'Holstein',
        ageYears: 4.2,
        parity: 2,
        deviceId: 'DEV-77A',
        healthStatus: 'Healthy',
        lastSeen: now.toIso8601String(),
        vitals: const Vitals(tempC: 38.7, hrBpm: 78, spO2: 96, activity: 62),
        vitalsHistory: List.generate(40, (i) => 38.4 + (i % 3) * 0.2),
        fertility: Fertility(
          lastEstrusDate: day(1),
          predictedEstrusInDays: 0,
          cycleLengthDays: 21,
          conceptionRate: 0.52,
          bodyConditionScore: 3.0,
          inbreedingRisk: 'Low',
        ),
      ),
      Cow(
        id: 'COW-202',
        name: 'Luna',
        breed: 'Jersey',
        ageYears: 3.6,
        parity: 1,
        deviceId: 'DEV-12K',
        healthStatus: 'Heat Stress',
        lastSeen: now.toIso8601String(),
        vitals: const Vitals(tempC: 40.1, hrBpm: 112, spO2: 93, activity: 80),
        vitalsHistory: List.generate(40, (i) => 39.2 + (i % 4) * 0.3),
        fertility: Fertility(
          lastEstrusDate: day(9),
          predictedEstrusInDays: 2,
          cycleLengthDays: 21,
          conceptionRate: 0.41,
          bodyConditionScore: 2.4,
          inbreedingRisk: 'Medium',
        ),
      ),
      Cow(
        id: 'COW-303',
        name: 'Ruby',
        breed: 'Brown Swiss',
        ageYears: 5.1,
        parity: 3,
        deviceId: 'DEV-9QX',
        healthStatus: 'Healthy',
        lastSeen: now.toIso8601String(),
        vitals: const Vitals(tempC: 38.9, hrBpm: 84, spO2: 95, activity: 55),
        vitalsHistory: List.generate(40, (i) => 38.6 + (i % 5) * 0.14),
        fertility: Fertility(
          lastEstrusDate: day(16),
          predictedEstrusInDays: 5,
          cycleLengthDays: 21,
          conceptionRate: 0.58,
          bodyConditionScore: 3.3,
          inbreedingRisk: 'Low',
        ),
      ),
      Cow(
        id: 'COW-404',
        name: 'Mila',
        breed: 'Holstein',
        ageYears: 2.9,
        parity: 0,
        deviceId: 'DEV-88Z',
        healthStatus: 'Low SpO2',
        lastSeen: now.toIso8601String(),
        vitals: const Vitals(tempC: 39.1, hrBpm: 98, spO2: 89, activity: 40),
        vitalsHistory: List.generate(40, (i) => 38.9 + (i % 6) * 0.13),
        fertility: Fertility(
          lastEstrusDate: day(2),
          predictedEstrusInDays: 0,
          cycleLengthDays: 21,
          conceptionRate: 0.35,
          bodyConditionScore: 2.7,
          inbreedingRisk: 'High',
        ),
      ),
    ];
  }

  static List<Device> devices() => [
        const Device(id: 'DEV-77A', battery: 86, signal: -74, lastPacketSecAgo: 8, status: 'Online'),
        const Device(id: 'DEV-12K', battery: 43, signal: -89, lastPacketSecAgo: 15, status: 'Online'),
        const Device(id: 'DEV-9QX', battery: 67, signal: -80, lastPacketSecAgo: 11, status: 'Online'),
        const Device(id: 'DEV-88Z', battery: 28, signal: -92, lastPacketSecAgo: 22, status: 'Online'),
      ];

  static List<Sire> sires() => [
        Sire(
          id: 'SIRE-A1',
          name: 'Atlas Prime',
          semenBatch: 'AT-PR-204',
          traits: const SireTraits(
              fertility: 8.2, diseaseResistance: 8.8, temperament: 7.2, milkYield: 7.6, calvingEase: 7.9),
          notes: 'Balanced sire. Strong fertility and health traits.',
        ),
        Sire(
          id: 'SIRE-B7',
          name: 'Boreal King',
          semenBatch: 'BR-KG-881',
          traits: const SireTraits(
              fertility: 6.9, diseaseResistance: 9.2, temperament: 6.4, milkYield: 8.9, calvingEase: 6.2),
          notes: 'High milk yield & disease resistance. Moderate calving ease.',
        ),
        Sire(
          id: 'SIRE-C3',
          name: 'Calm Meadow',
          semenBatch: 'CM-MD-319',
          traits: const SireTraits(
              fertility: 7.6, diseaseResistance: 7.4, temperament: 9.1, milkYield: 6.8, calvingEase: 8.6),
          notes: 'Excellent temperament and calving ease. Great for young cows.',
        ),
      ];

  static List<FarmAlert> alerts() {
    final now = DateTime.now();
    return [
      FarmAlert(
        id: 'a1',
        severity: 'warning',
        title: 'Heat stress risk',
        cowId: 'COW-202',
        createdAt: now.subtract(const Duration(minutes: 12)).toIso8601String(),
        details: 'Temp elevated and activity pattern indicates heat stress. Recommend cooling & hydration.',
      ),
      FarmAlert(
        id: 'a2',
        severity: 'danger',
        title: 'Low SpO₂ detected',
        cowId: 'COW-404',
        createdAt: now.subtract(const Duration(minutes: 25)).toIso8601String(),
        details: 'SpO₂ dropped below safe threshold. Check ear sensor placement & assess respiratory health.',
      ),
    ];
  }
}
