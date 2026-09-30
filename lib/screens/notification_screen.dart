import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../models/notification_payload.dart';
import '../providers/admin_providers.dart';
import '../theme/glass_theme.dart';
import '../widgets/key_value_editor.dart';
import '../widgets/sending_console_widget.dart';

/// The FCM push centre: audience selection, the content payload, the
/// dispatch action and the live console — every block on its own sheet of
/// liquid glass.
class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() =>
      _NotificationScreenState();
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

  /// One selectable audience row, drawn as its own sheet of glass.
  Widget _buildAudienceOptionTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required AudienceTargetType type,
    required AudienceTargetType currentType,
    required bool isSending,
    required ValueChanged<AudienceTargetType> onSelect,
  }) {
    final bool isSelected = type == currentType;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: isSending
            ? null
            : () {
                HapticFeedback.selectionClick();
                onSelect(type);
              },
        child: GlassLiteSurface(
          shape: GlassStyles.liteRowShape,
          color: isSelected ? GlassTints.selected : GlassTints.card,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? GlassPalette.indigo.withValues(alpha: 0.9)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? GlassPalette.indigo
                        : GlassPalette.textTertiary,
                    width: 1.4,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.circle,
                        size: 9,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? GlassPalette.textPrimary
                            : GlassPalette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.35,
                        color: GlassPalette.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(pushNotificationProvider);
    final notifier = ref.read(pushNotificationProvider.notifier);

    // Mirror state changes (e.g. the device sheet pre-filling a token) into
    // the controllers. Done through a listener rather than during build, so
    // the field never has its text rewritten mid-frame.
    ref.listen<PushNotificationState>(pushNotificationProvider,
        (previous, next) {
      _syncControllersFromState(next);
    });

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: glassPagePadding(context, horizontal: 20, extraBottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const GlassPageTitle(
            title: 'FCM Push Center',
            subtitle: 'Compose and dispatch Notification v1 messages',
          ),
          const SizedBox(height: 18),
          _buildAudienceCard(notificationState, notifier),
          const SizedBox(height: 16),
          _buildContentCard(notificationState, notifier),
          const SizedBox(height: 18),
          _buildSendButton(notificationState, notifier),
          const SizedBox(height: 18),
          SendingConsoleWidget(
            state: notificationState,
            onClearLogs: () {
              HapticFeedback.lightImpact();
              notifier.resetLogs();
            },
          ),
        ],
      ),
    );
  }

  /// Card 1 — who the message goes to.
  Widget _buildAudienceCard(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            index: '1',
            title: 'Target Audience',
            subtitle: 'Choose which devices receive this notification',
          ),
          const SizedBox(height: 12),
          _buildAudienceOptionTile(
            context: context,
            title: 'Option A: Broadcast to All Devices',
            subtitle: 'Sends to every registered FCM token in Firestore',
            type: AudienceTargetType.all,
            currentType: notificationState.targetType,
            isSending: notificationState.isSending,
            onSelect: (type) => notifier.setTargetType(type),
          ),
          _buildAudienceOptionTile(
            context: context,
            title: 'Option B: Segment by App or Android Version',
            subtitle: 'Filter the audience by a specific release',
            type: AudienceTargetType.segment,
            currentType: notificationState.targetType,
            isSending: notificationState.isSending,
            onSelect: (type) => notifier.setTargetType(type),
          ),
          if (notificationState.targetType == AudienceTargetType.segment)
            _buildSegmentSelector(notificationState, notifier),
          _buildAudienceOptionTile(
            context: context,
            title: 'Option C: Send to an FCM Topic',
            subtitle: 'Topics like all_users or updates (client subscribed)',
            type: AudienceTargetType.topic,
            currentType: notificationState.targetType,
            isSending: notificationState.isSending,
            onSelect: (type) => notifier.setTargetType(type),
          ),
          if (notificationState.targetType == AudienceTargetType.topic)
            _buildTopicField(notificationState, notifier),
          _buildAudienceOptionTile(
            context: context,
            title: 'Option D: Target Multiple Custom Tokens',
            subtitle: 'Comma, space or newline separated FCM tokens',
            type: AudienceTargetType.individual,
            currentType: notificationState.targetType,
            isSending: notificationState.isSending,
            onSelect: (type) => notifier.setTargetType(type),
          ),
          if (notificationState.targetType == AudienceTargetType.individual)
            _buildTokenField(notificationState, notifier),
        ],
      ),
    );
  }

  /// The App-version / Android-version switch and its value picker, shown
  /// under Option B.
  Widget _buildSegmentSelector(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    final analytics = ref.watch(analyticsSummaryProvider);
    final bool byApp =
        notificationState.selectedSegmentType == SegmentType.appVersion;
    final List<String> values = (byApp
            ? analytics.appVersionDistribution.keys
            : analytics.androidVersionDistribution.keys)
        .toList()
      ..sort();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: GlassChip(
                  label: 'By App Version',
                  color: byApp ? GlassTints.selected : GlassTints.chip,
                  textColor:
                      byApp ? GlassPalette.textPrimary : GlassPalette.textSecondary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onTap: () =>
                      notifier.setSelectedSegmentType(SegmentType.appVersion),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassChip(
                  label: 'By Android OS',
                  color: byApp ? GlassTints.chip : GlassTints.selected,
                  textColor:
                      byApp ? GlassPalette.textSecondary : GlassPalette.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  onTap: () => notifier
                      .setSelectedSegmentType(SegmentType.androidVersion),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GlassSelectField<String>(
            label: byApp ? 'Target App Version' : 'Target Android Version',
            icon: byApp ? Icons.system_update_rounded : Icons.android_rounded,
            placeholder: 'Choose a release…',
            value: notificationState.segmentValue,
            options: values
                .map(
                  (value) => GlassSelectOption<String>(
                    value: value,
                    label: byApp ? 'v$value' : value,
                  ),
                )
                .toList(),
            onChanged: (val) => notifier.setSegmentValue(val),
          ),
        ],
      ),
    );
  }

  /// The topic name field, shown under Option C.
  Widget _buildTopicField(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: GlassField(
        controller: _topicController,
        label: 'FCM Topic Name',
        hint: 'all_users',
        prefixIcon: Icons.tag_rounded,
        onChanged: (val) => notifier.setTopicName(val),
      ),
    );
  }

  /// The token list field with its live parsed count, shown under Option D.
  Widget _buildTokenField(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    final parsedTokens = notificationState.individualToken
        .split(RegExp(r'[\s,]+'))
        .where((t) => t.trim().isNotEmpty)
        .toSet();

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GlassField(
            controller: _tokenController,
            label: 'FCM Token(s)',
            hint: 'token1, token2, token3…',
            prefixIcon: Icons.vpn_key_rounded,
            maxLines: 4,
            onChanged: (val) => notifier.setIndividualToken(val),
          ),
          const SizedBox(height: 10),
          GlassChip(
            label: '${parsedTokens.length} token(s) parsed',
            icon: Icons.check_circle_rounded,
            iconColor: parsedTokens.isEmpty
                ? GlassPalette.textTertiary
                : GlassPalette.iosGreen,
          ),
        ],
      ),
    );
  }

  /// Card 2 — the notification's content, media and data payload.
  Widget _buildContentCard(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionHeader(
            index: '2',
            title: 'Notification Content',
            subtitle: 'Title, body, image and the custom data payload',
          ),
          const SizedBox(height: 16),
          GlassField(
            controller: _titleController,
            label: 'Notification Title',
            hint: 'MediaRescue Update Available',
            prefixIcon: Icons.title_rounded,
            onChanged: (val) => notifier.setTitle(val),
          ),
          const SizedBox(height: 12),
          GlassField(
            controller: _bodyController,
            label: 'Notification Body',
            hint: 'A new version of MediaRescue is available to download.',
            prefixIcon: Icons.notes_rounded,
            maxLines: 4,
            onChanged: (val) => notifier.setBody(val),
          ),
          const SizedBox(height: 12),
          GlassField(
            controller: _imageController,
            label: 'Notification Image URL (optional)',
            hint: 'https://example.com/banner.png',
            prefixIcon: Icons.image_rounded,
            onChanged: (val) => notifier.setImageUrl(val),
          ),
          if (notificationState.imageUrl.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 14),
            _buildImagePreview(notificationState.imageUrl.trim()),
          ],
          const SizedBox(height: 20),
          KeyValueEditorWidget(
            dataPayload: notificationState.dataPayload,
            onAddKeyValuePair: (k, v) =>
                notifier.addDataKeyValuePair(k, v),
            onRemoveKey: (k) => notifier.removeDataKey(k),
          ),
        ],
      ),
    );
  }

  /// The live network preview of the banner image.
  Widget _buildImagePreview(String url) {
    return GlassLiteSurface(
      shape: GlassStyles.liteCardShape,
      color: const Color(0x14000000),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Banner Preview',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: GlassPalette.textTertiary,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 150,
                alignment: Alignment.center,
                color: const Color(0x1AFFFFFF),
                child: const Text(
                  'Unable to load image preview',
                  style: TextStyle(
                    fontSize: 12,
                    color: GlassPalette.textTertiary,
                  ),
                ),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return const SizedBox(
                  height: 150,
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Card 3 — the dispatch action.
  Widget _buildSendButton(
    PushNotificationState notificationState,
    PushNotificationNotifier notifier,
  ) {
    return SizedBox(
      width: double.infinity,
      child: LiquidGlassButton(
        height: 54,
        fontSize: 15.5,
        iconSize: 20,
        padding: EdgeInsets.zero,
        touch: const LiquidGlassTouch.flexing(LiquidGlassFlex()),
        style: LiquidGlassButton.defaultStyle.copyWith(
          appearance: const LiquidGlassAppearance(
            color: GlassTints.accentBlue,
            // // blur: LiquidGlassBlur(sigmaX: 4, sigmaY: 4),
            // shadow: LiquidGlassShadow(blur: 5, opacity: 0.30),
          ),
        ),
        onPressed: notificationState.isSending
            ? null
            : () async {
                HapticFeedback.mediumImpact();

                // Sync state with the text controllers if the user typed
                // directly into them, OR keep the current state when a
                // controller is empty but the state holds selected tokens.
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (notificationState.isSending)
              const SizedBox(
                width: 19,
                height: 19,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
                ),
              )
            else
              const Icon(Icons.send_rounded, size: 20),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                notificationState.isSending
                    ? 'Sending Notifications…'
                    : 'Send Push Notification',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A numbered card heading: a tinted glass index badge, a title and a
/// subtitle line.
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.index,
    required this.title,
    required this.subtitle,
  });

  final String index;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        GlassLiteSurface(
          shape: GlassStyles.liteChipShape,
          color: GlassTints.selected,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          child: Text(
            index,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: GlassPalette.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlassPalette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: GlassPalette.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

