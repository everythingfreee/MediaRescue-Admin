import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyValueEditorWidget extends StatefulWidget {
  final Map<String, String> dataPayload;
  final Function(String key, String value) onAddKeyValuePair;
  final Function(String key) onRemoveKey;

  const KeyValueEditorWidget({
    super.key,
    required this.dataPayload,
    required this.onAddKeyValuePair,
    required this.onRemoveKey,
  });

  @override
  State<KeyValueEditorWidget> createState() => _KeyValueEditorWidgetState();
}

class _KeyValueEditorWidgetState extends State<KeyValueEditorWidget> {
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();

  void _handleAdd() {
    final k = _keyController.text.trim();
    final v = _valueController.text.trim();
    if (k.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onAddKeyValuePair(k, v);
      _keyController.clear();
      _valueController.clear();
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Key-Value Data Payload (FCM Data)',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Pass custom data properties to client application (e.g., action: update_alert)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),

        // Input Fields Row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _keyController,
                decoration: const InputDecoration(
                  labelText: 'Key',
                  hintText: 'e.g., action',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _valueController,
                decoration: const InputDecoration(
                  labelText: 'Value',
                  hintText: 'e.g., update_alert',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _handleAdd,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
              child: const Icon(Icons.add_rounded),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Added Key-Value Chips
        if (widget.dataPayload.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.dataPayload.entries.map((entry) {
              return Chip(
                avatar: Icon(Icons.data_object_rounded, size: 16, color: theme.colorScheme.primary),
                label: Text(
                  '${entry.key}: "${entry.value}"',
                  style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                deleteIcon: const Icon(Icons.cancel_rounded, size: 18),
                onDeleted: () {
                  HapticFeedback.lightImpact();
                  widget.onRemoveKey(entry.key);
                },
                backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No key-value pairs added',
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
      ],
    );
  }
}
