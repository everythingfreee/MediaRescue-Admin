import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class InstallationModel {
  final String installationId;
  final String appVersion;
  final String androidVersion;
  final String deviceModel;
  final String? fcmToken;
  final DateTime? lastAppOpen;
  final DateTime? updatedAt;

  const InstallationModel({
    required this.installationId,
    required this.appVersion,
    required this.androidVersion,
    required this.deviceModel,
    this.fcmToken,
    this.lastAppOpen,
    this.updatedAt,
  });

  bool get hasFcmToken => fcmToken != null && fcmToken!.trim().isNotEmpty;

  bool get isActiveInLast30Days {
    if (lastAppOpen == null) return false;
    final now = DateTime.now();
    return now.difference(lastAppOpen!).inDays <= 30;
  }

  String get lastSeenFormatted {
    if (lastAppOpen == null) return 'Never';
    final now = DateTime.now();
    final difference = now.difference(lastAppOpen!);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy HH:mm').format(lastAppOpen!);
    }
  }

  factory InstallationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value);
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return null;
    }

    return InstallationModel(
      installationId: doc.id.isNotEmpty ? doc.id : (data['installationId'] ?? 'Unknown'),
      appVersion: data['appVersion'] as String? ?? '1.0.0',
      androidVersion: data['androidVersion'] as String? ?? 'Android 10',
      deviceModel: data['deviceModel'] as String? ?? 'Unknown Device',
      fcmToken: data['fcmToken'] as String?,
      lastAppOpen: parseDate(data['lastAppOpen']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'installationId': installationId,
      'appVersion': appVersion,
      'androidVersion': androidVersion,
      'deviceModel': deviceModel,
      'fcmToken': fcmToken,
      'lastAppOpen': lastAppOpen != null ? Timestamp.fromDate(lastAppOpen!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }
}
