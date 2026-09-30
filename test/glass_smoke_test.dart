import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:mediarescueadmin/screens/dashboard_screen.dart';
import 'package:mediarescueadmin/screens/device_list_screen.dart';
import 'package:mediarescueadmin/screens/login_screen.dart';
import 'package:mediarescueadmin/screens/main_navigation_screen.dart';
import 'package:mediarescueadmin/screens/notification_screen.dart';
import 'package:mediarescueadmin/theme/glass_theme.dart';
import 'package:mediarescueadmin/widgets/device_card.dart';
import 'package:mediarescueadmin/widgets/stat_card.dart';

import 'glass_test_helpers.dart';

/// A page laid over the glass backdrop, the way the shell composes them:
/// the real `LiquidGlassScaffold` paints the body inside a transparent
/// `Material`, so the harness does too.
Widget page(Widget child) => Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const GlassBackdrop(),
          child,
        ],
      ),
    );

void main() {
  testWidgets('glass atoms render', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      hostApp(
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const GlassBackdrop(),
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: <Widget>[
                    const GlassCard(
                      touch:  LiquidGlassTouch.flexing(
                        LiquidGlassFlex.subtle(),
                      ),
                      child:  Text('glass card'),
                    ),
                    const SizedBox(height: 16),
                    const GlassChip(label: 'chip', icon: Icons.bolt_rounded),
                    const SizedBox(height: 16),
                    const GlassIconButton(icon: Icons.logout_rounded),
                    const SizedBox(height: 16),
                    const GlassCheckbox(value: true),
                    const SizedBox(height: 16),
                    const GlassField(
                      hint: 'search',
                      prefixIcon: Icons.search_rounded,
                    ),
                    const SizedBox(height: 16),
                    GlassSelectField<String>(
                      label: 'App Version',
                      value: '1.5.0',
                      options: const <GlassSelectOption<String>>[
                        GlassSelectOption<String>(
                          value: '1.5.0',
                          label: 'v1.5.0',
                        ),
                      ],
                      onChanged: (_) {},
                    ),
                    const SizedBox(height: 16),
                    const StatCard(
                      title: 'Total Installations',
                      value: '3',
                      subtitle: 'Recorded device telemetry docs',
                      icon: Icons.smartphone_rounded,
                      iconColor: GlassPalette.indigo,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('glass card'), findsOneWidget);
    expect(find.text('chip'), findsOneWidget);
    expect(find.text('v1.5.0'), findsOneWidget);
  });

  testWidgets('login screen renders the glass CTA', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(hostApp(const LoginScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('MediaRescue Admin'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
  });

  testWidgets('dashboard renders glass stat cards and charts', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      hostApp(page(DashboardScreen(onNavigateToDeviceList: () {}))),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Analytics Overview'), findsOneWidget);
    expect(find.byType(StatCard), findsNWidgets(3));
    expect(find.text('Total Installations'), findsOneWidget);
  });

  testWidgets('device list renders rows, filters and multi-select',
      (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(
      hostApp(page(DeviceListScreen(onNavigateToNotificationScreen: () {}))),
    );
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(DeviceCard), findsNWidgets(3));
    expect(find.text('App Version'), findsOneWidget);

    // Long-press enters multi-selection mode.
    await tester.longPress(find.byType(DeviceCard).first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('1 Selected'), findsOneWidget);
  });

  testWidgets('notification centre renders every glass card', (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(hostApp(page(const NotificationScreen())));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('FCM Push Center'), findsOneWidget);
    expect(find.text('Target Audience'), findsOneWidget);
    expect(find.text('Notification Content'), findsOneWidget);
    expect(find.text('Send Push Notification'), findsOneWidget);
  });

  testWidgets('shell builds the glass app bar and tab bar on a phone',
      (tester) async {
    usePhoneViewport(tester);
    await tester.pumpWidget(hostApp(const MainNavigationScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(LiquidGlassScaffold), findsOneWidget);
    expect(find.byType(LiquidGlassAppBar), findsOneWidget);
    expect(find.byType(LiquidGlassTabBar), findsOneWidget);
    expect(find.text('Dashboard'), findsWidgets);

    // Switching tabs swaps the page under the glass.
    await tester.tap(find.text('Devices').first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.byType(DeviceCard), findsNWidgets(3));
  });

  testWidgets('glass toast shows without a ScaffoldMessenger error',
      (tester) async {
    useTabletViewport(tester);
    await tester.pumpWidget(hostApp(const MainNavigationScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    // The admin badge in the app bar raises a toast from inside the shell.
    await tester.tap(find.byTooltip('admin@mediarescue.app'));
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Signed in as admin@mediarescue.app'), findsOneWidget);
  });

  testWidgets('shell swaps the tab bar for a glass rail when wide',
      (tester) async {
    useTabletViewport(tester);
    await tester.pumpWidget(hostApp(const MainNavigationScreen()));
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.byType(LiquidGlassTabBar), findsNothing);
    expect(find.text('Dash'), findsOneWidget);

    await tester.tap(find.text('Push'));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    expect(find.text('FCM Push Center'), findsOneWidget);
  });
}
