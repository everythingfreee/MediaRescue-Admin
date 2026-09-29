import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FcmSendResult {
  final String target; // token or topic name
  final bool isSuccess;
  final String? messageId;
  final String? errorMessage;

  FcmSendResult({
    required this.target,
    required this.isSuccess,
    this.messageId,
    this.errorMessage,
  });
}

class FcmV1Service {
  static const List<String> _scopes = [
    'https://www.googleapis.com/auth/firebase.messaging',
  ];

  String? _projectId;
  ServiceAccountCredentials? _credentials;
  AccessCredentials? _accessCredentials;
  final http.Client _httpClient;

  FcmV1Service({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  /// Loads and parses service_account.json from rootBundle
  Future<void> _ensureCredentialsLoaded() async {
    if (_credentials != null && _projectId != null) return;

    try {
      final jsonString = await rootBundle.loadString('assets/service_account.json');
      final jsonMap = json.decode(jsonString) as Map<String, dynamic>;

      _projectId = jsonMap['project_id'] as String?;
      if (_projectId == null || _projectId!.isEmpty) {
        throw Exception('service_account.json missing "project_id" field.');
      }

      _credentials = ServiceAccountCredentials.fromJson(jsonMap);
    } catch (e) {
      throw Exception('Failed to load assets/service_account.json: $e');
    }
  }

  /// Obtains or reuses a valid OAuth 2.0 access token
  Future<String> getAccessToken() async {
    await _ensureCredentialsLoaded();

    if (_accessCredentials != null &&
        _accessCredentials!.accessToken.expiry.isAfter(
          DateTime.now().add(const Duration(minutes: 5)),
        )) {
      return _accessCredentials!.accessToken.data;
    }

    try {
      _accessCredentials = await obtainAccessCredentialsViaServiceAccount(
        _credentials!,
        _scopes,
        _httpClient,
      );
      return _accessCredentials!.accessToken.data;
    } catch (e) {
      throw Exception('Failed to obtain OAuth 2.0 token for FCM v1: $e');
    }
  }

  /// Sends a single FCM v1 push notification to a device token OR a topic
  Future<FcmSendResult> sendNotification({
    String? fcmToken,
    String? topic,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? dataPayload,
  }) async {
    final targetLabel = fcmToken ?? (topic != null ? 'topic/$topic' : 'Unknown');

    try {
      if (fcmToken == null && topic == null) {
        return FcmSendResult(
          target: targetLabel,
          isSuccess: false,
          errorMessage: 'Either fcmToken or topic must be provided.',
        );
      }

      await _ensureCredentialsLoaded();
      final accessToken = await getAccessToken();
      final url = Uri.parse('https://fcm.googleapis.com/v1/projects/$_projectId/messages:send');

      final Map<String, dynamic> messageMap = {};

      if (fcmToken != null && fcmToken.isNotEmpty) {
        messageMap['token'] = fcmToken;
      } else if (topic != null && topic.isNotEmpty) {
        // Clean topic name if user entered '/topics/foo'
        final cleanTopic = topic.replaceFirst(RegExp(r'^/?topics/'), '');
        messageMap['topic'] = cleanTopic;
      }

      final Map<String, String> notificationMap = {};
      if (title.isNotEmpty) notificationMap['title'] = title;
      if (body.isNotEmpty) notificationMap['body'] = body;
      if (imageUrl != null && imageUrl.trim().isNotEmpty) {
        notificationMap['image'] = imageUrl.trim();
      }

      if (notificationMap.isNotEmpty) {
        messageMap['notification'] = notificationMap;
      }

      if (dataPayload != null && dataPayload.isNotEmpty) {
        messageMap['data'] = dataPayload;
      }

      final bodyJson = json.encode({'message': messageMap});

      final response = await _httpClient.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: bodyJson,
      );

      if (response.statusCode == 200) {
        final respData = json.decode(response.body) as Map<String, dynamic>;
        final messageId = respData['name'] as String?;
        return FcmSendResult(
          target: targetLabel,
          isSuccess: true,
          messageId: messageId,
        );
      } else {
        final errorMsg = 'HTTP ${response.statusCode}: ${response.body}';
        return FcmSendResult(
          target: targetLabel,
          isSuccess: false,
          errorMessage: errorMsg,
        );
      }
    } catch (e) {
      return FcmSendResult(
        target: targetLabel,
        isSuccess: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Batch dispatches push notifications to multiple FCM tokens asynchronously
  Stream<FcmSendResult> sendBatchNotifications({
    required List<String> fcmTokens,
    required String title,
    required String body,
    String? imageUrl,
    Map<String, String>? dataPayload,
    int concurrencyLimit = 5,
  }) async* {
    final cleanTokens = fcmTokens.where((t) => t.trim().isNotEmpty).toList();
    if (cleanTokens.isEmpty) return;

    for (int i = 0; i < cleanTokens.length; i += concurrencyLimit) {
      final chunk = cleanTokens.sublist(
        i,
        (i + concurrencyLimit > cleanTokens.length) ? cleanTokens.length : i + concurrencyLimit,
      );

      final futures = chunk.map(
        (token) => sendNotification(
          fcmToken: token,
          title: title,
          body: body,
          imageUrl: imageUrl,
          dataPayload: dataPayload,
        ),
      );

      final results = await Future.wait(futures);
      for (final res in results) {
        yield res;
      }

      if (i + concurrencyLimit < cleanTokens.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  void dispose() {
    _httpClient.close();
  }
}
