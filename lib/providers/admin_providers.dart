import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user_model.dart';
import '../models/installation_model.dart';
import '../models/notification_payload.dart';
import '../services/admin_auth_service.dart';
import '../services/analytics_service.dart';
import '../services/fcm_v1_service.dart';

// Service Providers
final adminAuthServiceProvider = Provider<AdminAuthService>((ref) {
  return AdminAuthService();
});

final fcmV1ServiceProvider = Provider<FcmV1Service>((ref) {
  final service = FcmV1Service();
  ref.onDispose(() => service.dispose());
  return service;
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

// Auth Stream & Admin User Provider
final authStateStreamProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(adminAuthServiceProvider);
  return authService.authStateChanges;
});

final currentAdminUserProvider = FutureProvider<AdminUserModel?>((ref) async {
  final authUser = ref.watch(authStateStreamProvider).value;
  if (authUser == null) return null;
  final authService = ref.read(adminAuthServiceProvider);
  return await authService.verifyCurrentAdminStatus();
});

// Gated Installations Stream Provider:
// Only subscribes to Firestore installations collection after currentAdminUserProvider
// is fully loaded and verified as active, preventing permission_denied errors on initial sign-in.
final installationsStreamProvider = StreamProvider<List<InstallationModel>>((ref) {
  final adminUserAsync = ref.watch(currentAdminUserProvider);

  return adminUserAsync.when(
    data: (adminUser) {
      if (adminUser != null && adminUser.active) {
        final analyticsService = ref.watch(analyticsServiceProvider);
        return analyticsService.getInstallationsStream();
      }
      return Stream.value(<InstallationModel>[]);
    },
    loading: () => Stream.value(<InstallationModel>[]),
    error: (_, __) => Stream.value(<InstallationModel>[]),
  );
});

// Computed Analytics Summary Provider
final analyticsSummaryProvider = Provider<AnalyticsSummary>((ref) {
  final installations = ref.watch(installationsStreamProvider).value ?? [];
  final analyticsService = ref.watch(analyticsServiceProvider);
  return analyticsService.computeAnalytics(installations);
});

// Filter States
final deviceSearchQueryProvider = StateProvider<String>((ref) => '');
final appVersionFilterProvider = StateProvider<String?>((ref) => null);
final androidVersionFilterProvider = StateProvider<String?>((ref) => null);

// Filtered Installations Provider
final filteredInstallationsProvider = Provider<List<InstallationModel>>((ref) {
  final installations = ref.watch(installationsStreamProvider).value ?? [];
  final query = ref.watch(deviceSearchQueryProvider).trim().toLowerCase();
  final appVerFilter = ref.watch(appVersionFilterProvider);
  final androidVerFilter = ref.watch(androidVersionFilterProvider);

  return installations.where((item) {
    if (query.isNotEmpty) {
      final matchesId = item.installationId.toLowerCase().contains(query);
      final matchesModel = item.deviceModel.toLowerCase().contains(query);
      if (!matchesId && !matchesModel) return false;
    }

    if (appVerFilter != null && appVerFilter.isNotEmpty) {
      if (item.appVersion != appVerFilter) return false;
    }

    if (androidVerFilter != null && androidVerFilter.isNotEmpty) {
      if (item.androidVersion != androidVerFilter) return false;
    }

    return true;
  }).toList();
});

// Push Notification State Notifier
class PushNotificationNotifier extends StateNotifier<PushNotificationState> {
  final FcmV1Service _fcmService;
  final Ref _ref;

  PushNotificationNotifier(this._fcmService, this._ref)
      : super(const PushNotificationState());

  void setTargetType(AudienceTargetType type) {
    state = state.copyWith(targetType: type);
  }

  void setSelectedSegmentType(SegmentType type) {
    state = state.copyWith(selectedSegmentType: type, segmentValue: null);
  }

  void setSegmentValue(String? val) {
    state = state.copyWith(segmentValue: val);
  }

  void setIndividualToken(String token) {
    state = state.copyWith(individualToken: token);
  }

  void setMultipleTokens(List<String> tokens) {
    final joined = tokens.where((t) => t.trim().isNotEmpty).join('\n');
    state = state.copyWith(
      targetType: AudienceTargetType.individual,
      individualToken: joined,
    );
  }

  void setTopicName(String topic) {
    state = state.copyWith(topicName: topic);
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setBody(String body) {
    state = state.copyWith(body: body);
  }

  void setImageUrl(String imageUrl) {
    state = state.copyWith(imageUrl: imageUrl);
  }

  void setDataPayload(Map<String, String> payload) {
    state = state.copyWith(dataPayload: Map.from(payload));
  }

  void addDataKeyValuePair(String key, String value) {
    if (key.trim().isEmpty) return;
    final updatedMap = Map<String, String>.from(state.dataPayload);
    updatedMap[key.trim()] = value.trim();
    state = state.copyWith(dataPayload: updatedMap);
  }

  void removeDataKey(String key) {
    final updatedMap = Map<String, String>.from(state.dataPayload);
    updatedMap.remove(key);
    state = state.copyWith(dataPayload: updatedMap);
  }

  void resetLogs() {
    state = state.copyWith(
      logs: [],
      successCount: 0,
      failureCount: 0,
      isSending: false,
    );
  }

  Future<void> dispatchPushNotification() async {
    if (state.title.trim().isEmpty && state.body.trim().isEmpty) {
      _addLog('System', false, 'Validation Error: Title or Body must not be empty.');
      return;
    }

    // Handle Topic Targeting
    if (state.targetType == AudienceTargetType.topic) {
      final topic = state.topicName.trim();
      if (topic.isEmpty) {
        _addLog('System', false, 'Validation Error: Topic name is empty.');
        return;
      }

      state = state.copyWith(
        isSending: true,
        successCount: 0,
        failureCount: 0,
        logs: [
          NotificationLogEntry(
            timestamp: DateTime.now(),
            targetId: 'Topic Dispatch',
            isSuccess: true,
            message: 'Sending to topic "/topics/$topic"...',
          ),
        ],
      );

      final result = await _fcmService.sendNotification(
        topic: topic,
        title: state.title.trim(),
        body: state.body.trim(),
        imageUrl: state.imageUrl.trim(),
        dataPayload: state.dataPayload,
      );

      if (result.isSuccess) {
        _addLog('topics/$topic', true, 'Topic message published! Message ID: ${result.messageId}');
        state = state.copyWith(isSending: false, successCount: 1);
      } else {
        _addLog('topics/$topic', false, 'Topic message failed: ${result.errorMessage}');
        state = state.copyWith(isSending: false, failureCount: 1);
      }
      return;
    }

    // Handle Device Token Targeting (All, Segment, Individual/Multiple Tokens)
    final installations = _ref.read(installationsStreamProvider).value ?? [];
    List<String> targetTokens = [];

    switch (state.targetType) {
      case AudienceTargetType.all:
        targetTokens = installations
            .where((i) => i.hasFcmToken)
            .map((i) => i.fcmToken!)
            .toList();
        break;
      case AudienceTargetType.segment:
        if (state.segmentValue == null || state.segmentValue!.isEmpty) {
          _addLog('System', false, 'Validation Error: No segment target selected.');
          return;
        }
        if (state.selectedSegmentType == SegmentType.appVersion) {
          targetTokens = installations
              .where((i) => i.hasFcmToken && i.appVersion == state.segmentValue)
              .map((i) => i.fcmToken!)
              .toList();
        } else {
          targetTokens = installations
              .where((i) => i.hasFcmToken && i.androidVersion == state.segmentValue)
              .map((i) => i.fcmToken!)
              .toList();
        }
        break;
      case AudienceTargetType.individual:
        final rawInput = state.individualToken.trim();
        if (rawInput.isEmpty) {
          _addLog('System', false, 'Validation Error: FCM token list is empty.');
          return;
        }
        targetTokens = rawInput
            .split(RegExp(r'[\s,]+'))
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toSet()
            .toList();
        break;
      case AudienceTargetType.topic:
        break;
    }

    if (targetTokens.isEmpty) {
      _addLog('System', false, 'No active FCM tokens found for the selected audience segment.');
      return;
    }

    state = state.copyWith(
      isSending: true,
      successCount: 0,
      failureCount: 0,
      logs: [
        NotificationLogEntry(
          timestamp: DateTime.now(),
          targetId: 'Batch Init',
          isSuccess: true,
          message: 'Starting dispatch to ${targetTokens.length} targeted token(s)...',
        ),
      ],
    );

    int successes = 0;
    int failures = 0;

    await for (final result in _fcmService.sendBatchNotifications(
      fcmTokens: targetTokens,
      title: state.title.trim(),
      body: state.body.trim(),
      imageUrl: state.imageUrl.trim(),
      dataPayload: state.dataPayload,
    )) {
      if (result.isSuccess) {
        successes++;
        _addLog(
          result.target.length > 15 ? '${result.target.substring(0, 15)}...' : result.target,
          true,
          'Sent successfully. Message ID: ${result.messageId}',
        );
      } else {
        failures++;
        _addLog(
          result.target.length > 15 ? '${result.target.substring(0, 15)}...' : result.target,
          false,
          'Failed to send: ${result.errorMessage}',
        );
      }

      state = state.copyWith(
        successCount: successes,
        failureCount: failures,
      );
    }

    _addLog('Batch Finish', true, 'Dispatch complete! Success: $successes, Failures: $failures');
    state = state.copyWith(isSending: false);
  }

  void _addLog(String targetId, bool isSuccess, String message) {
    final newEntry = NotificationLogEntry(
      timestamp: DateTime.now(),
      targetId: targetId,
      isSuccess: isSuccess,
      message: message,
    );
    state = state.copyWith(
      logs: [newEntry, ...state.logs],
    );
  }
}

final pushNotificationProvider =
    StateNotifierProvider<PushNotificationNotifier, PushNotificationState>((ref) {
  final fcmService = ref.watch(fcmV1ServiceProvider);
  return PushNotificationNotifier(fcmService, ref);
});
