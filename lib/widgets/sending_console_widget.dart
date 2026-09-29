import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_payload.dart';

class SendingConsoleWidget extends StatelessWidget {
  final PushNotificationState state;
  final VoidCallback onClearLogs;

  const SendingConsoleWidget({
    super.key,
    required this.state,
    required this.onClearLogs,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('HH:mm:ss');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Console Header
            Row(
              children: [
                Icon(
                  Icons.terminal_rounded,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Live Dispatch Console Log',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),

                // Clear button
                if (state.logs.isNotEmpty)
                  TextButton.icon(
                    onPressed: state.isSending ? null : onClearLogs,
                    icon: const Icon(Icons.delete_outline_rounded, size: 16),
                    label: const Text('Clear'),
                  ),
              ],
            ),
            const SizedBox(height: 8),

            // Metrics Progress Bar & Counts
            Row(
              children: [
                _buildBadge(
                  context,
                  label: 'Successes: ${state.successCount}',
                  color: Colors.greenAccent.shade700,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 8),
                _buildBadge(
                  context,
                  label: 'Failures: ${state.failureCount}',
                  color: Colors.redAccent.shade700,
                  textColor: Colors.white,
                ),
                const Spacer(),
                if (state.isSending)
                  Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dispatching...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Log Console Body
            Container(
              height: 180,
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E), // Dark terminal background
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: state.logs.isEmpty
                  ? Center(
                      child: Text(
                        'Console idle. Click "Send Notification" to dispatch.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: state.logs.length,
                      itemBuilder: (context, index) {
                        final log = state.logs[index];
                        final timeStr = timeFormat.format(log.timestamp);
                        final color = log.isSuccess
                            ? Colors.greenAccent.shade200
                            : Colors.redAccent.shade200;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.0),
                          child: RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                height: 1.3,
                              ),
                              children: [
                                TextSpan(
                                  text: '[$timeStr] ',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                TextSpan(
                                  text: '${log.targetId}: ',
                                  style: TextStyle(
                                    color: Colors.cyanAccent.shade200,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: log.message,
                                  style: TextStyle(color: color),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context, {
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}
