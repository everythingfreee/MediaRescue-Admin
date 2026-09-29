import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/installation_model.dart';
import '../models/notification_payload.dart';
import '../providers/admin_providers.dart';

class DeviceDetailBottomSheet extends ConsumerWidget {
  final InstallationModel installation;
  final VoidCallback onNavigateToNotificationScreen;

  const DeviceDetailBottomSheet({
    super.key,
    required this.installation,
    required this.onNavigateToNotificationScreen,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final maxModalHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxModalHeight),
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 16.0,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle indicator bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Header Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.phonelink_setup_rounded, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        installation.deviceModel,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'ID: ${installation.installationId}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontFamily: 'monospace',
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  tooltip: 'Copy Installation ID',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Clipboard.setData(ClipboardData(text: installation.installationId));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Installation ID copied to clipboard')),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 32),

            // Metadata Grid
            _buildDetailRow(
              context,
              icon: Icons.android_rounded,
              label: 'Android OS Version',
              value: installation.androidVersion,
            ),
            _buildDetailRow(
              context,
              icon: Icons.system_update_rounded,
              label: 'MediaRescue App Version',
              value: 'v${installation.appVersion}',
            ),
            _buildDetailRow(
              context,
              icon: Icons.history_rounded,
              label: 'Last App Open',
              value: installation.lastAppOpen != null
                  ? '${dateFormat.format(installation.lastAppOpen!)} (${installation.lastSeenFormatted})'
                  : 'Never',
            ),
            _buildDetailRow(
              context,
              icon: Icons.update_rounded,
              label: 'Document Updated At',
              value: installation.updatedAt != null
                  ? dateFormat.format(installation.updatedAt!)
                  : 'N/A',
            ),
            const SizedBox(height: 12),

            // FCM Token Section
            Text(
              'FCM Token Diagnostics',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        installation.hasFcmToken
                            ? Icons.check_circle_rounded
                            : Icons.cancel_rounded,
                        color: installation.hasFcmToken ? Colors.greenAccent : Colors.redAccent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        installation.hasFcmToken
                            ? 'FCM Token Registered'
                            : 'No FCM Token Available',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: installation.hasFcmToken
                              ? Colors.greenAccent.shade400
                              : Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                  if (installation.hasFcmToken) ...[
                    const SizedBox(height: 8),
                    SelectableText(
                      installation.fcmToken!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Target Notification Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Send Push Notification to this Device'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: installation.hasFcmToken
                    ? () {
                        HapticFeedback.lightImpact();
                        final notifier = ref.read(pushNotificationProvider.notifier);
                        notifier.setTargetType(AudienceTargetType.individual);
                        notifier.setIndividualToken(installation.fcmToken!);

                        Navigator.of(context).pop();
                        onNavigateToNotificationScreen();
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(
            '$label:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
