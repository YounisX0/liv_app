import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';
import 'breeding_screen.dart';

class CowProfileScreen extends StatelessWidget {
  final String cowId;
  const CowProfileScreen({super.key, required this.cowId});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final cow = state.cows.where((c) => c.id == cowId).firstOrNull;
    final device = cow != null
        ? state.devices.where((d) => d.id == cow.deviceId).firstOrNull
        : null;

    if (cow == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cow not found')),
        body: const Center(child: Text('Could not load cow data.')),
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
          TextButton.icon(
            icon: const Icon(Icons.favorite_outlined, size: 18),
            label: const Text('Breeding'),
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => BreedingScreen(selectedCowId: cow.id))),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header card ─────────────────────────────────────────────────
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
                          Row(children: [
                            Text(cow.name,
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.w800, color: LivTheme.primary)),
                            const SizedBox(width: 8),
                            HealthBadge(cow.healthStatus),
                          ]),
                          const SizedBox(height: 4),
                          Text('${cow.breed}  ·  ${cow.ageYears.toStringAsFixed(1)} yrs  ·  Parity ${cow.parity}',
                              style: const TextStyle(fontSize: 13, color: LivTheme.muted)),
                          Text('Device: ${cow.deviceId}',
                              style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Vitals grid ─────────────────────────────────────────────────
            const SectionHeader(title: 'Live vitals'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.7,
              children: [
                KpiCard(
                  label: 'Temperature',
                  value: '${cow.vitals.tempC.toStringAsFixed(1)}°C',
                  valueColor: cow.vitals.tempC > 39.5 ? LivTheme.danger : LivTheme.ok,
                ),
                KpiCard(
                  label: 'Heart rate',
                  value: '${cow.vitals.hrBpm.toInt()} bpm',
                  valueColor: cow.vitals.hrBpm > 100 ? LivTheme.warn : LivTheme.text,
                ),
                KpiCard(
                  label: 'SpO₂',
                  value: '${cow.vitals.spO2.toInt()}%',
                  valueColor: cow.vitals.spO2 < 92 ? LivTheme.danger : LivTheme.ok,
                ),
                KpiCard(
                  label: 'Activity',
                  value: '${cow.vitals.activity.toInt()}%',
                ),
              ],
            ),

            // ── Temp trend chart ────────────────────────────────────────────
            const SectionHeader(title: 'Temperature trend'),
            Card(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
                child: SizedBox(
                  height: 150,
                  child: _VitalsChart(history: cow.vitalsHistory),
                ),
              ),
            ),

            // ── Device info ─────────────────────────────────────────────────
            if (device != null) ...[
              const SectionHeader(title: 'IoT device'),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _InfoRow('Device ID', device.id),
                      _InfoRow('Status', device.status,
                          valueColor: device.status == 'Online' ? LivTheme.ok : LivTheme.danger),
                      _InfoRow('Battery', '${device.battery}%',
                          valueColor: device.battery < 30 ? LivTheme.danger : null),
                      _InfoRow('Signal', '${device.signal} dBm'),
                      _InfoRow('Last packet', '${device.lastPacketSecAgo}s ago'),
                    ],
                  ),
                ),
              ),
            ],

            // ── Fertility ───────────────────────────────────────────────────
            const SectionHeader(title: 'Fertility data'),
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
                        child: const Row(
                          children: [
                            Text('🌸', style: TextStyle(fontSize: 18)),
                            SizedBox(width: 8),
                            Text('In fertile window — breeding recommended',
                                style: TextStyle(color: LivTheme.gold, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    _InfoRow('Last estrus', '$daysAgo days ago'),
                    _InfoRow('Predicted in', '${cow.fertility.predictedEstrusInDays} days'),
                    _InfoRow('Cycle length', '${cow.fertility.cycleLengthDays} days'),
                    _InfoRow('Conception rate', '${(cow.fertility.conceptionRate * 100).toStringAsFixed(0)}%'),
                    _InfoRow('Body condition', cow.fertility.bodyConditionScore.toStringAsFixed(1)),
                    _InfoRow('Inbreeding risk', cow.fertility.inbreedingRisk),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
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
          Text(value,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? LivTheme.text)),
        ],
      ),
    );
  }
}

class _VitalsChart extends StatelessWidget {
  final List<double> history;
  const _VitalsChart({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: LivTheme.muted)));
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
              getTitlesWidget: (v, _) =>
                  Text(v.toStringAsFixed(1), style: const TextStyle(fontSize: 9, color: LivTheme.muted)),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
              color: LivTheme.accent.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
