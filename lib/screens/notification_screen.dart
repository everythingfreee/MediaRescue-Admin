import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_payload.dart';
import '../providers/admin_providers.dart';
import '../widgets/key_value_editor.dart';
import '../widgets/sending_console_widget.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  final _imageController = TextEditingController();
  final _tokenController = TextEditingController();
  final _topicController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(pushNotificationProvider);
      _syncControllersFromState(state);
    });
  }

  void _syncControllersFromState(PushNotificationState state) {
    if (_titleController.text != state.title) {
      _titleController.text = state.title;
    }
    if (_bodyController.text != state.body) {
      _bodyController.text = state.body;
    }
    if (_imageController.text != state.imageUrl) {
      _imageController.text = state.imageUrl;
    }
    if (_tokenController.text != state.individualToken) {
      _tokenController.text = state.individualToken;
    }
    if (_topicController.text != state.topicName) {
      _topicController.text = state.topicName;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _imageController.dispose();
    _tokenController.dispose();
    _topicController.dispose();
    super.dispose();
  }

  Widget _buildAudienceOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required AudienceTargetType type,
    required AudienceTargetType currentType,
    required bool isSending,
    required ValueChanged<AudienceTargetType> onSelect,
  }) {
    final theme = Theme.of(context);
    final isSelected = type == currentType;

    return InkWell(
      onTap: isSending
          ? null
          : () {
              HapticFeedback.selectionClick();
              onSelect(type);
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(pushNotificationProvider);
    final notifier = ref.read(pushNotificationProvider.notifier);
    final installations = ref.watch(installationsStreamProvider).value ?? [];

    // Automatically sync controllers whenever pushNotificationProvider state updates (e.g. from DeviceList selection)
    ref.listen<PushNotificationState>(pushNotificationProvider, (previous, next) {
      _syncControllersFromState(next);
    });

    final uniqueAppVersions = installations
        .map((e) => e.appVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final uniqueAndroidVersions = installations
        .map((e) => e.androidVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    // Calculate count of tokens entered in Option D
    final rawTokens = notificationState.individualToken.trim();
    final parsedTokenCount = rawTokens.isEmpty
        ? 0
        : rawTokens
            .split(RegExp(r'[\s,]+'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .length;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FCM Push Notification Center',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Dispatch serverless client-side FCM v1 push & topic notifications',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),

              // Card 1: Target Audience Selector
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '1. Select Target Audience',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Option A: All
                      _buildAudienceOptionTile(
                        context: context,
                        title: 'Option A: Broadcast to ALL active devices',
                        subtitle: 'Target all ${installations.where((i) => i.hasFcmToken).length} active FCM tokens',
                        type: AudienceTargetType.all,
                        currentType: notificationState.targetType,
                        isSending: notificationState.isSending,
                        onSelect: (type) => notifier.setTargetType(type),
                      ),

                      // Option B: Segment Filter
                      _buildAudienceOptionTile(
                        context: context,
                        title: 'Option B: Segmented Target (App / Android Version)',
                        subtitle: 'Target specific software or OS release build',
                        type: AudienceTargetType.segment,
                        currentType: notificationState.targetType,
                        isSending: notificationState.isSending,
                        onSelect: (type) => notifier.setTargetType(type),
                      ),

                      if (notificationState.targetType == AudienceTargetType.segment)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0, right: 16.0, top: 8.0, bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ChoiceChip(
                                    label: const Text('By App Version'),
                                    selected: notificationState.selectedSegmentType ==
                                        SegmentType.appVersion,
                                    onSelected: (selected) {
                                      HapticFeedback.selectionClick();
                                      if (selected) {
                                        notifier.setSelectedSegmentType(SegmentType.appVersion);
                                      }
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  ChoiceChip(
                                    label: const Text('By Android OS'),
                                    selected: notificationState.selectedSegmentType ==
                                        SegmentType.androidVersion,
                                    onSelected: (selected) {
                                      HapticFeedback.selectionClick();
                                      if (selected) {
                                        notifier.setSelectedSegmentType(SegmentType.androidVersion);
                                      }
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              DropdownButton<String>(
                                value: notificationState.segmentValue,
                                hint: Text(
                                  notificationState.selectedSegmentType == SegmentType.appVersion
                                      ? 'Select target App Version'
                                      : 'Select target Android Version',
                                ),
                                isExpanded: true,
                                items: (notificationState.selectedSegmentType == SegmentType.appVersion
                                        ? uniqueAppVersions
                                        : uniqueAndroidVersions)
                                    .map(
                                      (val) => DropdownMenuItem(
                                        value: val,
                                        child: Text(
                                          notificationState.selectedSegmentType ==
                                                  SegmentType.appVersion
                                              ? 'v$val'
                                              : val,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (val) {
                                  HapticFeedback.selectionClick();
                                  notifier.setSegmentValue(val);
                                },
                              ),
                            ],
                          ),
                        ),

                      // Option C: Topic Target
                      _buildAudienceOptionTile(
                        context: context,
                        title: 'Option C: FCM Topic Broadcast',
                        subtitle: 'Send to subscribed FCM topic (e.g., all_users, updates)',
                        type: AudienceTargetType.topic,
                        currentType: notificationState.targetType,
                        isSending: notificationState.isSending,
                        onSelect: (type) => notifier.setTargetType(type),
                      ),

                      if (notificationState.targetType == AudienceTargetType.topic)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0, right: 16.0, top: 8.0, bottom: 12.0),
                          child: TextField(
                            controller: _topicController,
                            enabled: !notificationState.isSending,
                            onChanged: (val) => notifier.setTopicName(val),
                            decoration: const InputDecoration(
                              labelText: 'Topic Name',
                              hintText: 'e.g., all_users, announcements, or updates',
                              prefixIcon: Icon(Icons.topic_rounded),
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),

                      // Option D: Multiple / Individual Tokens Target
                      _buildAudienceOptionTile(
                        context: context,
                        title: 'Option D: Custom / Multiple Devices Target',
                        subtitle: 'Target specific device token(s) (supports single or multiple tokens)',
                        type: AudienceTargetType.individual,
                        currentType: notificationState.targetType,
                        isSending: notificationState.isSending,
                        onSelect: (type) => notifier.setTargetType(type),
                      ),

                      if (notificationState.targetType == AudienceTargetType.individual)
                        Padding(
                          padding: const EdgeInsets.only(left: 32.0, right: 16.0, top: 8.0, bottom: 12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _tokenController,
                                enabled: !notificationState.isSending,
                                maxLines: 3,
                                onChanged: (val) => notifier.setIndividualToken(val),
                                decoration: InputDecoration(
                                  labelText: 'FCM Device Tokens (Separated by newlines or commas)',
                                  hintText: 'Paste single or multiple FCM tokens here...',
                                  prefixIcon: const Icon(Icons.vpn_key_rounded),
                                  border: const OutlineInputBorder(),
                                  isDense: true,
                                  suffixIcon: _tokenController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear_rounded),
                                          onPressed: () {
                                            HapticFeedback.lightImpact();
                                            _tokenController.clear();
                                            notifier.setIndividualToken('');
                                          },
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Parsed Target Tokens: $parsedTokenCount',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  if (parsedTokenCount > 0)
                                    Text(
                                      'Ready for batch dispatch',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: Colors.greenAccent.shade400,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Card 2: Notification Form Inputs
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '2. Notification Content & Media Payload',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _titleController,
                        enabled: !notificationState.isSending,
                        onChanged: (val) => notifier.setTitle(val),
                        decoration: const InputDecoration(
                          labelText: 'Notification Title',
                          hintText: 'e.g., Important Security Update Available',
                          prefixIcon: Icon(Icons.title_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _bodyController,
                        enabled: !notificationState.isSending,
                        onChanged: (val) => notifier.setBody(val),
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notification Body Message',
                          hintText: 'e.g., Please update MediaRescue to version 1.5.0 for critical fixes.',
                          prefixIcon: Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _imageController,
                        enabled: !notificationState.isSending,
                        onChanged: (val) => notifier.setImageUrl(val),
                        decoration: InputDecoration(
                          labelText: 'Notification Image URL (Optional)',
                          hintText: 'https://example.com/banner.jpg',
                          prefixIcon: const Icon(Icons.image_rounded),
                          border: const OutlineInputBorder(),
                          suffixIcon: notificationState.imageUrl.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    _imageController.clear();
                                    notifier.setImageUrl('');
                                  },
                                )
                              : null,
                        ),
                      ),
                      if (notificationState.imageUrl.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 140,
                            width: double.infinity,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Image.network(
                              notificationState.imageUrl.trim(),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.broken_image_rounded, color: Colors.redAccent),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Failed to load image URL preview',
                                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.redAccent),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      KeyValueEditorWidget(
                        dataPayload: notificationState.dataPayload,
                        onAddKeyValuePair: (k, v) => notifier.addDataKeyValuePair(k, v),
                        onRemoveKey: (k) => notifier.removeDataKey(k),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Card 3: Action Controls & Live Console
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  icon: notificationState.isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(
                    notificationState.isSending ? 'Sending Notifications...' : 'Send Push Notification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: notificationState.isSending
                      ? null
                      : () async {
                          HapticFeedback.mediumImpact();

                          // Sync state with text controller if user typed directly into controller,
                          // OR use current state if controller is empty but state contains selected tokens.
                          final tokenText = _tokenController.text.trim().isNotEmpty
                              ? _tokenController.text
                              : notificationState.individualToken;
                          notifier.setIndividualToken(tokenText);

                          final topicText = _topicController.text.trim().isNotEmpty
                              ? _topicController.text
                              : notificationState.topicName;
                          notifier.setTopicName(topicText);

                          notifier.setTitle(_titleController.text);
                          notifier.setBody(_bodyController.text);
                          notifier.setImageUrl(_imageController.text);

                          await notifier.dispatchPushNotification();
                        },
                ),
              ),
              const SizedBox(height: 20),

              SendingConsoleWidget(
                state: notificationState,
                onClearLogs: () {
                  HapticFeedback.lightImpact();
                  notifier.resetLogs();
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
