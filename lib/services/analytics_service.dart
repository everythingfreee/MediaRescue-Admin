import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/installation_model.dart';

class AnalyticsSummary {
  final int totalDevices;
  final int activeUsers30Days;
  final int activeFcmTokens;
  final Map<String, int> appVersionDistribution;
  final Map<String, int> androidVersionDistribution;
  final Map<String, int> topDeviceModels;

  const AnalyticsSummary({
    required this.totalDevices,
    required this.activeUsers30Days,
    required this.activeFcmTokens,
    required this.appVersionDistribution,
    required this.androidVersionDistribution,
    required this.topDeviceModels,
  });

  factory AnalyticsSummary.fromInstallations(List<InstallationModel> list) {
    int active30Days = 0;
    int fcmTokens = 0;
    final Map<String, int> appVersions = {};
    final Map<String, int> androidVersions = {};
    final Map<String, int> devices = {};

    for (final item in list) {
      if (item.isActiveInLast30Days) {
        active30Days++;
      }

      if (item.hasFcmToken) {
        fcmTokens++;
      }

      final appVer = item.appVersion.isNotEmpty ? item.appVersion : 'Unknown';
      appVersions[appVer] = (appVersions[appVer] ?? 0) + 1;

      final androidVer = item.androidVersion.isNotEmpty ? item.androidVersion : 'Unknown';
      androidVersions[androidVer] = (androidVersions[androidVer] ?? 0) + 1;

      final model = item.deviceModel.isNotEmpty ? item.deviceModel : 'Unknown';
      devices[model] = (devices[model] ?? 0) + 1;
    }

    return AnalyticsSummary(
      totalDevices: list.length,
      activeUsers30Days: active30Days,
      activeFcmTokens: fcmTokens,
      appVersionDistribution: appVersions,
      androidVersionDistribution: androidVersions,
      topDeviceModels: devices,
    );
  }
}

class AnalyticsService {
  final FirebaseFirestore _firestore;

  AnalyticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Stream of all installation records from Firestore
  Stream<List<InstallationModel>> getInstallationsStream() {
    return _firestore.collection('installations').snapshots().map(
          (snapshot) => snapshot.docs
              .map((doc) => InstallationModel.fromFirestore(doc))
              .toList(),
        );
  }

  /// Computes summary metrics from a given list of installation models
  AnalyticsSummary computeAnalytics(List<InstallationModel> installations) {
    return AnalyticsSummary.fromInstallations(installations);
  }

  /// Delete a single installation document by ID
  Future<void> deleteInstallation(String installationId) async {
    await _firestore.collection('installations').doc(installationId).delete();
  }

  /// Batch delete multiple installation documents by ID list
  Future<void> batchDeleteInstallations(List<String> installationIds) async {
    final batch = _firestore.batch();
    for (final id in installationIds) {
      final ref = _firestore.collection('installations').doc(id);
      batch.delete(ref);
    }
    await batch.commit();
  }
}
