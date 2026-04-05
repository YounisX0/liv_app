import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import '../theme/liv_theme.dart';
import '../widgets/widgets.dart';
import '../models/models.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final pkt = state.latestPacket;

    return Theme(
      data: LivTheme.dark,
      child: Scaffold(
        backgroundColor: LivTheme.darkBg,
        body: RefreshIndicator(
          onRefresh: () async {},
          child: CustomScrollView(
            slivers: [
              // ── Status header ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _LiveDot(active: state.connected),
                          const SizedBox(width: 8),
                          const Text('LIV Gateway Monitor',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: LivTheme.darkAccent,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.1)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text('Real-time sensor telemetry',
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                      const SizedBox(height: 16),

                      // Status strip
                      Row(
                        children: [
                          _StatusPill(label: 'UDP', value: state.udpStatus),
                          const SizedBox(width: 8),
                          _StatusPill(label: 'MQTT', value: state.mqttStatus),
                          const SizedBox(width: 8),
                          _StatusPill(label: 'Last', value: state.lastPacketTime),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Counter row
                      Row(
                        children: [
                          _CountBox(label: 'Packets', value: '${state.totalReceived}'),
                          const SizedBox(width: 8),
                          _CountBox(label: 'Published', value: '${state.totalPublished}'),
                          const SizedBox(width: 8),
                          _CountBox(label: 'Bad JSON', value: '${state.badJson}',
                              danger: state.badJson > 0),
                          const SizedBox(width: 8),
                          _CountBox(label: 'Gateway', value: state.gatewayId),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Metric tiles ───────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                  children: [
                    MetricTile(
                      label: 'Temperature',
                      value: pkt?.tempC != null ? pkt!.tempC!.toStringAsFixed(1) : '--',
                      unit: '°C',
                      sub: 'Body / object',
                      badgeColor: _tempColor(pkt?.tempC),
                    ),
                    MetricTile(
                      label: 'Heart Rate I2C',
                      value: pkt?.hrI2c != null ? pkt!.hrI2c!.toStringAsFixed(0) : '--',
                      unit: 'bpm',
                      sub: 'Ear-clip / I2C',
                      badgeColor: _hrColor(pkt?.hrI2c),
                    ),
                    MetricTile(
                      label: 'SpO₂ I2C',
                      value: pkt?.spo2I2c != null ? pkt!.spo2I2c!.toStringAsFixed(0) : '--',
                      unit: '%',
                      sub: 'Oxygen saturation',
                      badgeColor: _spo2Color(pkt?.spo2I2c),
                    ),
                    MetricTile(
                      label: 'Heart Rate UART',
                      value: pkt?.hrUart != null ? pkt!.hrUart!.toStringAsFixed(0) : '--',
                      unit: 'bpm',
                      sub: 'Backup UART',
                    ),
                    MetricTile(
                      label: 'SpO₂ UART',
                      value: pkt?.spo2Uart != null ? pkt!.spo2Uart!.toStringAsFixed(0) : '--',
                      unit: '%',
                      sub: 'UART channel',
                    ),
                    MetricTile(
                      label: 'Accel Magnitude',
                      value: pkt != null ? pkt.accelMag.toStringAsFixed(2) : '--',
                      unit: 'm/s²',
                      sub: 'From X/Y/Z',
                      badgeColor: LivTheme.darkAccent,
                    ),
                    MetricTile(
                      label: 'Gyro Magnitude',
                      value: pkt != null ? pkt.gyroMag.toStringAsFixed(2) : '--',
                      unit: 'rad/s',
                      sub: 'From X/Y/Z',
                      badgeColor: LivTheme.darkAccent,
                    ),
                    MetricTile(
                      label: 'GPS',
                      value: pkt?.lat != null
                          ? '${pkt!.lat!.toStringAsFixed(4)}'
                          : '--',
                      unit: pkt?.lat != null ? '°N' : '',
                      sub: pkt?.lng != null
                          ? 'Lng: ${pkt!.lng!.toStringAsFixed(4)}'
                          : 'No GPS lock',
                    ),
                  ],
                ),
              ),

              // ── Vitals chart ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _DarkPanel(
                    title: 'Vitals trend',
                    subtitle: 'Temp · HR · SpO₂',
                    child: SizedBox(
                      height: 160,
                      child: _MultiLineChart(
                        series: {
                          'Temp °C': (state.tempHistory, const Color(0xFF31D0AA)),
                          'HR bpm': (state.hrHistory, const Color(0xFF7CC8FF)),
                          'SpO₂ %': (state.spo2History, const Color(0xFFFFA552)),
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Motion chart ───────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _DarkPanel(
                    title: 'Motion trend',
                    subtitle: 'Accel + Gyro magnitude',
                    child: SizedBox(
                      height: 140,
                      child: _MultiLineChart(
                        series: {
                          'Accel m/s²': (state.accelHistory, const Color(0xFFA78BFA)),
                          'Gyro rad/s': (state.gyroHistory, const Color(0xFFF87171)),
                        },
                      ),
                    ),
                  ),
                ),
              ),

              // ── Per-axis values ────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _DarkPanel(
                    title: 'Per-axis motion',
                    subtitle: 'Direct from latest packet',
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.8,
                      children: [
                        _AxisBox('Accel X', pkt?.accelX),
                        _AxisBox('Accel Y', pkt?.accelY),
                        _AxisBox('Accel Z', pkt?.accelZ),
                        _AxisBox('Gyro X', pkt?.gyroX),
                        _AxisBox('Gyro Y', pkt?.gyroY),
                        _AxisBox('Gyro Z', pkt?.gyroZ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Packet feed ────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: _DarkPanel(
                    title: 'Packet feed',
                    subtitle: 'Newest first',
                    child: state.packetFeed.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('Waiting for packets…',
                                style: TextStyle(color: LivTheme.darkMuted, fontSize: 13)),
                          )
                        : Column(
                            children: state.packetFeed
                                .take(10)
                                .map((p) => _PacketRow(packet: p))
                                .toList(),
                          ),
                  ),
                ),
              ),

              // ── Raw JSON ───────────────────────────────────────────────────
              if (pkt != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    child: _DarkPanel(
                      title: 'Latest raw payload',
                      subtitle: 'JSON from device',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0F1A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _fmtPacket(pkt),
                          style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: Color(0xFF31D0AA)),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color? _tempColor(double? v) {
    if (v == null) return null;
    if (v > 39.5) return LivTheme.danger;
    if (v > 39.0) return LivTheme.warn;
    return LivTheme.ok;
  }

  Color? _hrColor(double? v) {
    if (v == null) return null;
    if (v > 110) return LivTheme.danger;
    if (v > 95) return LivTheme.warn;
    return LivTheme.ok;
  }

  Color? _spo2Color(double? v) {
    if (v == null) return null;
    if (v < 90) return LivTheme.danger;
    if (v < 94) return LivTheme.warn;
    return LivTheme.ok;
  }

  String _fmtPacket(TelemetryPacket p) {
    final lines = <String>[];
    if (p.tempC != null) lines.add('  "temp_c": ${p.tempC!.toStringAsFixed(2)}');
    if (p.hrI2c != null) lines.add('  "hr_i2c": ${p.hrI2c!.toStringAsFixed(0)}');
    if (p.spo2I2c != null) lines.add('  "spo2_i2c": ${p.spo2I2c!.toStringAsFixed(0)}');
    if (p.hrUart != null) lines.add('  "hr_uart": ${p.hrUart!.toStringAsFixed(0)}');
    if (p.spo2Uart != null) lines.add('  "spo2_uart": ${p.spo2Uart!.toStringAsFixed(0)}');
    if (p.accelX != null) lines.add('  "accel_x": ${p.accelX!.toStringAsFixed(3)}');
    if (p.accelY != null) lines.add('  "accel_y": ${p.accelY!.toStringAsFixed(3)}');
    if (p.accelZ != null) lines.add('  "accel_z": ${p.accelZ!.toStringAsFixed(3)}');
    if (p.gyroX != null) lines.add('  "gyro_x": ${p.gyroX!.toStringAsFixed(3)}');
    if (p.gyroY != null) lines.add('  "gyro_y": ${p.gyroY!.toStringAsFixed(3)}');
    if (p.gyroZ != null) lines.add('  "gyro_z": ${p.gyroZ!.toStringAsFixed(3)}');
    if (p.lat != null) lines.add('  "lat": ${p.lat!.toStringAsFixed(6)}');
    if (p.lng != null) lines.add('  "lng": ${p.lng!.toStringAsFixed(6)}');
    if (p.cowId.isNotEmpty) lines.add('  "cow_id": "${p.cowId}"');
    if (p.deviceId.isNotEmpty) lines.add('  "device_id": "${p.deviceId}"');
    return '{\n${lines.join(',\n')}\n}';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _LiveDot extends StatefulWidget {
  final bool active;
  const _LiveDot({required this.active});

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.active
              ? Color.lerp(LivTheme.darkAccent, LivTheme.ok, _ctrl.value)
              : LivTheme.danger,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final String value;
  const _StatusPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1F2937)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 9, color: LivTheme.darkMuted)),
            Text(value,
                style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CountBox extends StatelessWidget {
  final String label;
  final String value;
  final bool danger;
  const _CountBox({required this.label, required this.value, this.danger = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: danger ? LivTheme.danger.withOpacity(0.5) : const Color(0xFF1F2937)),
        ),
        child: Column(children: [
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: danger ? LivTheme.danger : Colors.white)),
          Text(label, style: const TextStyle(fontSize: 9, color: LivTheme.darkMuted)),
        ]),
      ),
    );
  }
}

class _DarkPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  const _DarkPanel({required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
              const Spacer(),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: LivTheme.darkMuted)),
            ]),
          ),
          Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 14), child: child),
        ],
      ),
    );
  }
}

class _AxisBox extends StatelessWidget {
  final String label;
  final double? value;
  const _AxisBox(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1A),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, color: LivTheme.darkMuted)),
          const SizedBox(height: 2),
          Text(
            value != null ? value!.toStringAsFixed(2) : '--',
            style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _PacketRow extends StatelessWidget {
  final TelemetryPacket packet;
  const _PacketRow({required this.packet});

  @override
  Widget build(BuildContext context) {
    final t = packet.receivedAt;
    final time =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(color: LivTheme.darkAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(time, style: const TextStyle(fontSize: 11, color: LivTheme.darkMuted, fontFamily: 'monospace')),
          const SizedBox(width: 10),
          if (packet.tempC != null)
            Text('${packet.tempC!.toStringAsFixed(1)}°C',
                style: const TextStyle(fontSize: 11, color: Colors.white)),
          if (packet.hrI2c != null) ...[
            const SizedBox(width: 8),
            Text('${packet.hrI2c!.toStringAsFixed(0)} bpm',
                style: const TextStyle(fontSize: 11, color: Color(0xFF7CC8FF))),
          ],
          if (packet.spo2I2c != null) ...[
            const SizedBox(width: 8),
            Text('${packet.spo2I2c!.toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 11, color: Color(0xFFFFA552))),
          ],
          if (packet.cowId.isNotEmpty) ...[
            const Spacer(),
            Text(packet.cowId,
                style: const TextStyle(fontSize: 10, color: LivTheme.darkMuted)),
          ],
        ],
      ),
    );
  }
}

// ── Multi-line chart ──────────────────────────────────────────────────────────
class _MultiLineChart extends StatelessWidget {
  final Map<String, (List<double>, Color)> series;
  const _MultiLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final allEmpty = series.values.every((e) => e.$1.isEmpty);
    if (allEmpty) {
      return const Center(
        child: Text('Waiting for data…',
            style: TextStyle(color: LivTheme.darkMuted, fontSize: 12)),
      );
    }

    final bars = series.entries.map((entry) {
      final data = entry.value.$1;
      final color = entry.value.$2;
      final spots = data
          .asMap()
          .entries
          .map((e) => FlSpot(e.key.toDouble(), e.value))
          .toList();
      return LineChartBarData(
        spots: spots,
        isCurved: true,
        color: color,
        barWidth: 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: true, color: color.withOpacity(0.08)),
      );
    }).toList();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0xFF1F2937), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 9, color: LivTheme.darkMuted)),
            ),
          ),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: bars,
      ),
    );
  }
}
