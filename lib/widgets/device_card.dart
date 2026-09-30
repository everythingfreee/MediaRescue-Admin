import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/installation_model.dart';
import '../theme/glass_theme.dart';

/// One device in the telemetry list, drawn as a sheet of lite glass.
///
/// Lite glass — not a lens — on purpose: this row repeats down a long,
/// scrolling list, and the shader-free material (frost, tint, lit rim)
/// gives the same look at no backdrop read per row, and none of the
/// scroll-layer quirks a lens inside a scrollable runs into.
class DeviceCard extends StatelessWidget {
  final InstallationModel installation;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const DeviceCard({
    super.key,
    required this.installation,
    required this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

  bool _isOldVersion(String version) {
    final cleanVer = version.replaceAll(RegExp(r'[^0-9.]'), '');
    final parts = cleanVer.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    if (parts.isEmpty) return true;
    if (parts[0] < 1) return true;
    if (parts[0] == 1 && parts.length > 1 && parts[1] < 5) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutdated = _isOldVersion(installation.appVersion);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GlassLiteSurface(
        shape: GlassStyles.liteCardShape,
        color: isSelected ? GlassTints.selected : GlassTints.card,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticFeedback.lightImpact();
            if (isSelectionMode) {
              onSelectChanged?.call(!isSelected);
            } else {
              onTap();
            }
          },
          onLongPress: () {
            HapticFeedback.mediumImpact();
            onLongPress?.call();
          },
          child: Row(
            children: <Widget>[
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: GlassCheckbox(
                    value: isSelected,
                    onChanged: onSelectChanged,
                  ),
                )
              else
                const GlassLiteSurface(
                  shape: GlassStyles.liteChipShape,
                  color: GlassTints.selected,
                  margin: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: Icon(
                        Icons.phone_android_rounded,
                        color: GlassPalette.textPrimary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              Expanded(child: _DeviceDetails(installation: installation, isOutdated: isOutdated)),
              const SizedBox(width: 8),
              if (!isSelectionMode)
                const Icon(
                  Icons.chevron_right_rounded,
                  color: GlassPalette.textTertiary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The model name, status dot, version chips and last-seen line.
class _DeviceDetails extends StatelessWidget {
  const _DeviceDetails({required this.installation, required this.isOutdated});

  final InstallationModel installation;
  final bool isOutdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                installation.deviceModel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlassPalette.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(left: 8),
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: installation.hasFcmToken
                    ? GlassPalette.iosGreen
                    : GlassPalette.iosGray,
                boxShadow: installation.hasFcmToken
                    ? <BoxShadow>[
                        BoxShadow(
                          color:
                              GlassPalette.iosGreen.withValues(alpha: 0.5),
                          blurRadius: 6,
                          spreadRadius: 0.5,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Row(
          children: <Widget>[
            Flexible(
              child: GlassChip(
                label: installation.androidVersion,
                textColor: GlassPalette.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: GlassChip(
                label: 'v${installation.appVersion}',
                icon: isOutdated ? Icons.warning_amber_rounded : null,
                color: isOutdated ? const Color(0x33F59E0B) : GlassTints.chip,
                iconColor: GlassPalette.amber,
                textColor: isOutdated
                    ? const Color(0xFFF3C77B)
                    : GlassPalette.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: <Widget>[
            const Icon(
              Icons.access_time_rounded,
              size: 13,
              color: GlassPalette.textTertiary,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                'Last seen ${installation.lastSeenFormatted}',
                style: const TextStyle(
                  fontSize: 11,
                  color: GlassPalette.textTertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

