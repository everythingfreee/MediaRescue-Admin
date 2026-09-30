import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/notification_payload.dart';
import '../theme/glass_theme.dart';

/// The live dispatch log, on a sheet of real liquid glass with a dark
/// terminal well inside it.
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
    final timeFormat = DateFormat('HH:mm:ss');

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(
                Icons.terminal_rounded,
                color: GlassPalette.textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Live Dispatch Console Log',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GlassPalette.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (state.logs.isNotEmpty)
                TextButton.icon(
                  onPressed: state.isSending ? null : onClearLogs,
                  icon: const Icon(Icons.delete_outline_rounded, size: 16),
                  label: const Text('Clear'),
                  style: TextButton.styleFrom(
                    foregroundColor: GlassPalette.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Flexible(
                child: _buildBadge(
                  label: 'Successes: ${state.successCount}',
                  color: GlassTints.accentGreen,
                  textColor: const Color(0xFFB7F7C9),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: _buildBadge(
                  label: 'Failures: ${state.failureCount}',
                  color: GlassTints.accentRed,
                  textColor: const Color(0xFFFFC4BF),
                ),
              ),
              const Spacer(),
              if (state.isSending)
                const Row(
                  children: <Widget>[
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Dispatching…',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: GlassPalette.textPrimary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          GlassLiteSurface(
            shape: GlassStyles.liteFieldShape,
            color: const Color(0xB3080912),
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: _ConsoleBody(state: state, timeFormat: timeFormat),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge({
    required String label,
    required Color color,
    required Color textColor,
  }) {
    return GlassLiteSurface(
      shape: GlassStyles.liteChipShape,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      child: Text(
        label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

/// The terminal well: idle hint, or the scrolling log lines.
class _ConsoleBody extends StatelessWidget {
  const _ConsoleBody({required this.state, required this.timeFormat});

  final PushNotificationState state;
  final DateFormat timeFormat;

  @override
  Widget build(BuildContext context) {
    if (state.logs.isEmpty) {
      return Center(
        child: Text(
          'Console idle. Click "Send Notification" to dispatch.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      );
    }

    return ListView.builder(
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
              children: <TextSpan>[
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
    );
  }
}
