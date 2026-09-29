enum AudienceTargetType {
  all,
  segment,
  individual,
  topic,
}

enum SegmentType {
  appVersion,
  androidVersion,
}

class NotificationLogEntry {
  final DateTime timestamp;
  final String targetId;
  final bool isSuccess;
  final String message;

  NotificationLogEntry({
    required this.timestamp,
    required this.targetId,
    required this.isSuccess,
    required this.message,
  });
}

class PushNotificationState {
  final AudienceTargetType targetType;
  final SegmentType selectedSegmentType;
  final String? segmentValue;
  final String individualToken;
  final String topicName;
  final String title;
  final String body;
  final String imageUrl;
  final Map<String, String> dataPayload;
  final bool isSending;
  final int successCount;
  final int failureCount;
  final List<NotificationLogEntry> logs;

  const PushNotificationState({
    this.targetType = AudienceTargetType.all,
    this.selectedSegmentType = SegmentType.appVersion,
    this.segmentValue,
    this.individualToken = '',
    this.topicName = 'all_users',
    this.title = '',
    this.body = '',
    this.imageUrl = '',
    this.dataPayload = const {},
    this.isSending = false,
    this.successCount = 0,
    this.failureCount = 0,
    this.logs = const [],
  });

  PushNotificationState copyWith({
    AudienceTargetType? targetType,
    SegmentType? selectedSegmentType,
    String? segmentValue,
    String? individualToken,
    String? topicName,
    String? title,
    String? body,
    String? imageUrl,
    Map<String, String>? dataPayload,
    bool? isSending,
    int? successCount,
    int? failureCount,
    List<NotificationLogEntry>? logs,
  }) {
    return PushNotificationState(
      targetType: targetType ?? this.targetType,
      selectedSegmentType: selectedSegmentType ?? this.selectedSegmentType,
      segmentValue: segmentValue ?? this.segmentValue,
      individualToken: individualToken ?? this.individualToken,
      topicName: topicName ?? this.topicName,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      dataPayload: dataPayload ?? this.dataPayload,
      isSending: isSending ?? this.isSending,
      successCount: successCount ?? this.successCount,
      failureCount: failureCount ?? this.failureCount,
      logs: logs ?? this.logs,
    );
  }
}
