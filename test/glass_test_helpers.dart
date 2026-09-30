import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mediarescueadmin/models/admin_user_model.dart';
import 'package:mediarescueadmin/models/installation_model.dart';
import 'package:mediarescueadmin/providers/admin_providers.dart';
import 'package:mediarescueadmin/services/analytics_service.dart';

/// Fake telemetry so the pages have something to lay out without Firebase.
final List<InstallationModel> fakeDevices = <InstallationModel>[
  InstallationModel(
    installationId: 'a1b2c3d4-0000-1111-2222-333344445555',
    appVersion: '1.5.0',
    androidVersion: 'Android 14',
    deviceModel: 'Google Pixel 8 Pro',
    fcmToken: 'token-one',
    lastAppOpen: DateTime.now().subtract(const Duration(minutes: 5)),
    updatedAt: DateTime.now(),
  ),
  InstallationModel(
    installationId: 'b2c3d4e5-0000-1111-2222-333344445555',
    appVersion: '1.2.0',
    androidVersion: 'Android 12',
    deviceModel: 'Samsung Galaxy S21',
    fcmToken: 'token-two',
    lastAppOpen: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now(),
  ),
  InstallationModel(
    installationId: 'c3d4e5f6-0000-1111-2222-333344445555',
    appVersion: '1.5.0',
    androidVersion: 'Android 14',
    deviceModel: 'Xiaomi 13',
    lastAppOpen: DateTime.now().subtract(const Duration(days: 40)),
    updatedAt: DateTime.now(),
  ),
];

List<Override> appOverrides() => <Override>[
      currentAdminUserProvider.overrideWith(
        (ref) async => const AdminUserModel(
          email: 'admin@mediarescue.app',
          active: true,
          role: 'super_admin',
        ),
      ),
      installationsStreamProvider.overrideWith(
        (ref) => Stream<List<InstallationModel>>.value(fakeDevices),
      ),
      // Bypass the Firestore-backed service: compute the summary straight
      // from the fake telemetry.
      analyticsSummaryProvider.overrideWith(
        (ref) => AnalyticsSummary.fromInstallations(fakeDevices),
      ),
    ];

Widget hostApp(Widget child) => ProviderScope(
      overrides: appOverrides(),
      child: MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: child,
      ),
    );

void usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2340);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

void useTabletViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}
