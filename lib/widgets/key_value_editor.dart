import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../theme/glass_theme.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Custom Key-Value Data Payload (FCM Data)',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: GlassPalette.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Pass custom data properties to client application '
          '(e.g., action: update_alert)',
          style: TextStyle(
            fontSize: 11.5,
            height: 1.35,
            color: GlassPalette.textTertiary,
          ),
        ),
        const SizedBox(height: 14),

        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: GlassField(
                controller: _keyController,
                label: 'Key',
                hint: 'action',
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GlassField(
                controller: _valueController,
                label: 'Value',
                hint: 'update_alert',
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 1),
              child: LiquidGlassButton(
                icon: Icons.add_rounded,
                height: 46,
                width: 54,
                padding: EdgeInsets.zero,
                iconSize: 20,
                touch: const LiquidGlassTouch.flexing(LiquidGlassFlex.subtle()),
                style: LiquidGlassButton.defaultStyle.copyWith(
                  appearance: const LiquidGlassAppearance(
                    color: GlassTints.accentBlue,
                    // blur: LiquidGlassBlur(sigmaX: 3, sigmaY: 3),
                  ),
                ),
                onPressed: _handleAdd,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        if (widget.dataPayload.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.dataPayload.entries.map((entry) {
              return GlassChip(
                label: '${entry.key}: "${entry.value}"',
                icon: Icons.cancel_rounded,
                iconColor: GlassPalette.textTertiary,
                color: GlassTints.selected,
                textColor: GlassPalette.textPrimary,
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                onTap: () {
                  HapticFeedback.lightImpact();
                  widget.onRemoveKey(entry.key);
                },
              );
            }).toList(),
          )
        else
          const Text(
            'No key-value pairs added',
            style: TextStyle(
              fontSize: 11.5,
              fontStyle: FontStyle.italic,
              color: GlassPalette.textTertiary,
            ),
          ),
      ],
    );
  }
}

