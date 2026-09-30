import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../providers/admin_providers.dart';
import '../services/analytics_service.dart';
import '../theme/glass_theme.dart';
import '../widgets/chart_card.dart';
import '../widgets/stat_card.dart';

/// The analytics overview, now a page of floating glass cards over the
/// liquid backdrop instead of a Material scaffold with flat cards.
class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToDeviceList;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDeviceList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsSummary = ref.watch(analyticsSummaryProvider);
    final installationsAsync = ref.watch(installationsStreamProvider);
    final EdgeInsets pagePadding = glassPagePadding(
      context,
      horizontal: 20,
      extraBottom: 16,
    );

    return installationsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: GlassPalette.indigo),
      ),
      error: (err, stack) => Center(
        child: SingleChildScrollView(
          padding: pagePadding,
          child: GlassCard(
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(
                  Icons.error_outline_rounded,
                  color: GlassPalette.iosRed,
                  size: 42,
                ),
                const SizedBox(height: 14),
                const Text(
                  'Failed to load Firestore telemetry data',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: GlassPalette.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    color: GlassPalette.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (installations) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: pagePadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const GlassPageTitle(
                title: 'Analytics Overview',
                subtitle: 'Real-time MediaRescue telemetry & FCM metrics',
              ),
              const SizedBox(height: 18),
              _MetricsAndShortcut(
                analyticsSummary: analyticsSummary,
                onNavigateToDeviceList: onNavigateToDeviceList,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The three summary metrics, the device-list shortcut, and the charts —
/// kept in one widget so both layouts share a single source of truth.
class _MetricsAndShortcut extends StatelessWidget {
  const _MetricsAndShortcut({
    required this.analyticsSummary,
    required this.onNavigateToDeviceList,
  });

  final AnalyticsSummary analyticsSummary;
  final VoidCallback onNavigateToDeviceList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 700;

            final StatCard totalCard = StatCard(
              title: 'Total Installations',
              value: '${analyticsSummary.totalDevices}',
              subtitle: 'Recorded device telemetry docs',
              icon: Icons.smartphone_rounded,
              iconColor: GlassPalette.indigo,
            );
            final StatCard usersCard = StatCard(
              title: 'Active Users (30d)',
              value: '${analyticsSummary.activeUsers30Days}',
              subtitle: 'Active app opens in 30 days',
              icon: Icons.person_pin_circle_rounded,
              iconColor: GlassPalette.emerald,
            );
            final StatCard tokensCard = StatCard(
              title: 'Active FCM Tokens',
              value: '${analyticsSummary.activeFcmTokens}',
              subtitle: 'Devices ready for push notifications',
              icon: Icons.notifications_active_rounded,
              iconColor: GlassPalette.amber,
            );

            if (isMobile) {
              return Column(
                children: <Widget>[
                  totalCard,
                  const SizedBox(height: 14),
                  usersCard,
                  const SizedBox(height: 14),
                  tokensCard,
                ],
              );
            }

            return Row(
              children: <Widget>[
                Expanded(child: totalCard),
                const SizedBox(width: 14),
                Expanded(child: usersCard),
                const SizedBox(width: 14),
                Expanded(child: tokensCard),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 700) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Align(
                alignment: Alignment.centerRight,
                child: LiquidGlassButton(
                  icon: Icons.devices_rounded,
                  label: 'View All Devices',
                  height: 44,
                  fontSize: 14,
                  iconSize: 18,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  touch: const LiquidGlassTouch.flexing(
                    LiquidGlassFlex.subtle(),
                  ),
                  style: LiquidGlassButton.defaultStyle.copyWith(
                    appearance: const LiquidGlassAppearance(
                      color: GlassTints.accentBlue,
                      // blur: LiquidGlassBlur(sigmaX: 3, sigmaY: 3),
                      // shadow: LiquidGlassShadow(blur: 4, opacity: 0.26),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onNavigateToDeviceList();
                  },
                ),
              ),
            );
          },
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final bool isMobile = constraints.maxWidth < 900;
            final Widget appVersionChart = SizedBox(
              height: 360,
              child: ChartCard(
                title: 'App Version Distribution',
                subtitle: 'Installed versions breakdown across devices',
                child: PieChartDistributionWidget(
                  dataMap: analyticsSummary.appVersionDistribution,
                ),
              ),
            );
            final Widget androidChart = SizedBox(
              height: 360,
              child: ChartCard(
                title: 'Android Version Distribution',
                subtitle: 'Android OS releases running MediaRescue',
                child: PieChartDistributionWidget(
                  dataMap: analyticsSummary.androidVersionDistribution,
                ),
              ),
            );
            final Widget modelsChart = SizedBox(
              height: 360,
              child: ChartCard(
                title: 'Top Device Models',
                subtitle:
                    'Most common hardware devices registered in Firestore',
                child: BarChartTopModelsWidget(
                  dataMap: analyticsSummary.topDeviceModels,
                ),
              ),
            );

            if (isMobile) {
              return Column(
                children: <Widget>[
                  appVersionChart,
                  const SizedBox(height: 16),
                  androidChart,
                  const SizedBox(height: 16),
                  modelsChart,
                ],
              );
            }

            return Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(child: appVersionChart),
                    const SizedBox(width: 16),
                    Expanded(child: androidChart),
                  ],
                ),
                const SizedBox(height: 16),
                modelsChart,
              ],
            );
          },
        ),
      ],
    );
  }
}

