import 'package:flutter/material.dart';
import '../theme/liv_theme.dart';
import '../models/models.dart';

// ── Health status badge ───────────────────────────────────────────────────────
class HealthBadge extends StatelessWidget {
  final String status;
  const HealthBadge(this.status, {super.key});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg = Colors.white;
    switch (status) {
      case 'Healthy':
        bg = LivTheme.ok;
        break;
      case 'Heat Stress':
        bg = LivTheme.warn;
        fg = Colors.black87;
        break;
      case 'Low SpO2':
        bg = LivTheme.danger;
        break;
      case 'Fever':
        bg = const Color(0xFFDC2626);
        break;
      default:
        bg = LivTheme.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ── Alert severity icon ───────────────────────────────────────────────────────
class AlertIcon extends StatelessWidget {
  final String severity;
  const AlertIcon(this.severity, {super.key});

  @override
  Widget build(BuildContext context) {
    final color = severity == 'danger'
        ? LivTheme.danger
        : severity == 'warning'
            ? LivTheme.warn
            : LivTheme.accent;
    final icon = severity == 'danger'
        ? Icons.error_rounded
        : severity == 'warning'
            ? Icons.warning_amber_rounded
            : Icons.info_rounded;
    return Icon(icon, color: color, size: 20);
  }
}

// ── KPI card ──────────────────────────────────────────────────────────────────
class KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final String? hint;
  final Color? valueColor;
  const KpiCard({super.key, required this.label, required this.value, this.hint, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: LivTheme.muted, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? LivTheme.primary)),
            if (hint != null)
              Text(hint!, style: const TextStyle(fontSize: 11, color: LivTheme.muted)),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  const SectionHeader({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: LivTheme.primary)),
                if (subtitle != null)
                  Text(subtitle!, style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Demo banner ───────────────────────────────────────────────────────────────
class DemoBanner extends StatelessWidget {
  const DemoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: LivTheme.gold.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LivTheme.gold.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.science_outlined, color: LivTheme.gold, size: 18),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Demo mode — connect to a LIV gateway in Settings to see live data.',
              style: TextStyle(color: LivTheme.gold, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trait bar ─────────────────────────────────────────────────────────────────
class TraitBar extends StatelessWidget {
  final String label;
  final double value; // 0–10
  const TraitBar({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = (value / 10).clamp(0.0, 1.0);
    Color barColor = pct > 0.75 ? LivTheme.ok : pct > 0.5 ? LivTheme.accent : LivTheme.warn;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: LivTheme.muted)),
              Text(value.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: LivTheme.line,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Metric tile (for gateway screen) ─────────────────────────────────────────
class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final String sub;
  final Color? badgeColor;
  final Color? cardColor;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.sub = '',
    this.badgeColor,
    this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor ?? const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF99ADCF), fontWeight: FontWeight.w500)),
              if (badgeColor != null)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                ),
            ],
          ),
          const SizedBox(height: 6),
          RichText(
            text: TextSpan(
              text: value,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.white),
              children: [
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF99ADCF)),
                )
              ],
            ),
          ),
          if (sub.isNotEmpty)
            Text(sub, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B))),
        ],
      ),
    );
  }
}
