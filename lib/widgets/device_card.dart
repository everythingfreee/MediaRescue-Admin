import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/installation_model.dart';

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
    final theme = Theme.of(context);
    final isOutdated = _isOldVersion(installation.appVersion);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isSelected ? 4 : 1.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.15),
          width: isSelected ? 1.8 : 1.0,
        ),
      ),
      color: isSelected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
          : theme.cardTheme.color,
      child: InkWell(
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
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Selection Checkbox or Device Icon
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      onSelectChanged?.call(val);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                )
              else
                Container(
                  width: 48,
                  height: 48,
                  margin: const EdgeInsets.only(right: 14.0),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.phone_android_rounded,
                    color: theme.colorScheme.primary,
                    size: 26,
                  ),
                ),

              // Device Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            installation.deviceModel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: installation.hasFcmToken
                                ? Colors.greenAccent.shade400
                                : Colors.grey.shade600,
                            boxShadow: installation.hasFcmToken
                                ? [
                                    BoxShadow(
                                      color: Colors.greenAccent.withValues(alpha: 0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            installation.androidVersion,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOutdated
                                ? Colors.amber.shade900.withValues(alpha: 0.3)
                                : theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: isOutdated
                                ? Border.all(color: Colors.amber.shade700, width: 0.8)
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isOutdated) ...[
                                Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber.shade400),
                                const SizedBox(width: 4),
                              ],
                              Text(
                                'v${installation.appVersion}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isOutdated ? Colors.amber.shade300 : theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Last seen ${installation.lastSeenFormatted}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!isSelectionMode)
                Icon(
                  Icons.chevron_right_rounded,
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
