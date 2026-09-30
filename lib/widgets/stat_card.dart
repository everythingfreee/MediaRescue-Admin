import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../theme/glass_theme.dart';

/// A summary metric on a real sheet of liquid glass: the glass refracts the
/// page behind it and — because it carries a touch spec — gently deforms
/// under a finger.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color? backgroundColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      touch: const LiquidGlassTouch.flexing(LiquidGlassFlex.subtle()),
      style: backgroundColor == null
          ? GlassStyles.card
          : GlassStyles.card.copyWith(
              appearance: GlassStyles.card.appearance.copyWith(
                color: backgroundColor,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: GlassPalette.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              // The metric's glyph in its own little tinted sheet.
              GlassLiteSurface(
                shape: GlassStyles.liteChipShape,
                color: iconColor.withValues(alpha: 0.20),
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: iconColor, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: GlassPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              height: 1.3,
              color: Color(0x99FFFFFF),
            ),
          ),
        ],
      ),
    );
  }
}
