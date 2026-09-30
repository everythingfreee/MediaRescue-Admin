import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../models/installation_model.dart';
import '../models/notification_payload.dart';
import '../providers/admin_providers.dart';
import '../theme/glass_theme.dart';

/// The device diagnostics inspector — Flutter's modal bottom sheet with the
/// glass put where the filled Material used to be, via
/// [showLiquidGlassSheet].
class DeviceDetailBottomSheet {
  DeviceDetailBottomSheet._();

  /// Presents the diagnostic sheet for [installation].
  static Future<void> show({
    required BuildContext context,
    required InstallationModel installation,
    required VoidCallback onNavigateToNotificationScreen,
  }) async {
    await showLiquidGlassSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      anchor: LiquidGlassSheetAnchor.floating,
      grabber: true,
      header: _DeviceSheetHeader(installation: installation),
      builder: (sheetContext) => _DeviceDetailContent(
        installation: installation,
        onClose: () => Navigator.of(sheetContext).pop(),
        onNavigateToNotificationScreen: onNavigateToNotificationScreen,
      ),
    );
  }
}

/// Model, installation id and the copy shortcut, drawn full-width in the
/// sheet's header slot.
class _DeviceSheetHeader extends StatelessWidget {
  const _DeviceSheetHeader({required this.installation});

  final InstallationModel installation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
      child: Row(
        children: <Widget>[
          const GlassLiteSurface(
            shape: GlassStyles.liteChipShape,
            color: GlassTints.selected,
            padding: EdgeInsets.all(10),
            child: Icon(
              Icons.phonelink_setup_rounded,
              color: GlassPalette.textPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Device Diagnostics',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: GlassPalette.textTertiary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  installation.deviceModel,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: GlassPalette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.copy_rounded,
            size: 38,
            iconSize: 18,
            tooltip: 'Copy Installation ID',
            onPressed: () {
              Clipboard.setData(
                ClipboardData(text: installation.installationId),
              );
              showGlassToast(
                context,
                'Installation ID copied to clipboard',
                type: GlassToastType.success,
              );
            },
          ),
        ],
      ),
    );
  }
}

/// The sheet's body: the metadata rows, the FCM token panel and the
/// targeted-send action.
class _DeviceDetailContent extends ConsumerWidget {
  const _DeviceDetailContent({
    required this.installation,
    required this.onClose,
    required this.onNavigateToNotificationScreen,
  });

  final InstallationModel installation;
  final VoidCallback onClose;
  final VoidCallback onNavigateToNotificationScreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _DeviceDetailRow(
            icon: Icons.android_rounded,
            label: 'Android OS Version',
            value: installation.androidVersion,
          ),
          _DeviceDetailRow(
            icon: Icons.system_update_rounded,
            label: 'MediaRescue App Version',
            value: 'v${installation.appVersion}',
          ),
          _DeviceDetailRow(
            icon: Icons.history_rounded,
            label: 'Last App Open',
            value: installation.lastAppOpen != null
                ? '${dateFormat.format(installation.lastAppOpen!)} '
                    '(${installation.lastSeenFormatted})'
                : 'Never',
          ),
          _DeviceDetailRow(
            icon: Icons.update_rounded,
            label: 'Document Updated At',
            value: installation.updatedAt != null
                ? dateFormat.format(installation.updatedAt!)
                : 'N/A',
          ),
          _DeviceDetailRow(
            icon: Icons.fingerprint_rounded,
            label: 'Installation ID',
            value: installation.installationId,
            monospace: true,
          ),
          const SizedBox(height: 16),
          const Text(
            'FCM Token Diagnostics',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: GlassPalette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          GlassLiteSurface(
            shape: GlassStyles.liteFieldShape,
            color: GlassTints.field,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      installation.hasFcmToken
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      color: installation.hasFcmToken
                          ? GlassPalette.iosGreen
                          : GlassPalette.iosRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        installation.hasFcmToken
                            ? 'FCM Token Registered'
                            : 'No FCM Token Available',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: installation.hasFcmToken
                              ? const Color(0xFF9CF0B4)
                              : const Color(0xFFFFB4AE),
                        ),
                      ),
                    ),
                    if (installation.hasFcmToken)
                      TextButton.icon(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Clipboard.setData(
                            ClipboardData(text: installation.fcmToken!),
                          );
                          showGlassToast(
                            context,
                            'FCM token copied to clipboard',
                            type: GlassToastType.success,
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        label: const Text('Copy'),
                        style: TextButton.styleFrom(
                          foregroundColor: GlassPalette.textSecondary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                if (installation.hasFcmToken) ...<Widget>[
                  const SizedBox(height: 8),
                  SelectableText(
                    installation.fcmToken!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.4,
                      color: GlassPalette.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: LiquidGlassButton(
              icon: Icons.send_rounded,
              height: 50,
              fontSize: 15,
              touch: const LiquidGlassTouch.flexing(LiquidGlassFlex()),
              style: LiquidGlassButton.defaultStyle.copyWith(
                appearance: const LiquidGlassAppearance(
                  color: GlassTints.accentBlue,
                  // blur: LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
                  // shadow: LiquidGlassShadow(blur: 4, opacity: 0.28),
                ),
              ),
              label: 'Send Push Notification to this Device',
              onPressed: installation.hasFcmToken
                  ? () {
                      HapticFeedback.lightImpact();
                      final notifier =
                          ref.read(pushNotificationProvider.notifier);
                      notifier.setTargetType(AudienceTargetType.individual);
                      notifier.setIndividualToken(installation.fcmToken!);

                      onClose();
                      onNavigateToNotificationScreen();
                    }
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// One label/value line in the diagnostics table.
class _DeviceDetailRow extends StatelessWidget {
  const _DeviceDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 17, color: GlassPalette.textTertiary),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: const TextStyle(
              fontSize: 13,
              color: GlassPalette.textTertiary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                fontFamily: monospace ? 'monospace' : null,
                color: GlassPalette.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

