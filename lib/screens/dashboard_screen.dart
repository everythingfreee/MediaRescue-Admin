import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';
import '../widgets/chart_card.dart';
import '../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  final VoidCallback onNavigateToDeviceList;

  const DashboardScreen({
    super.key,
    required this.onNavigateToDeviceList,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final analyticsSummary = ref.watch(analyticsSummaryProvider);
    final installationsAsync = ref.watch(installationsStreamProvider);

    return Scaffold(
      body: SafeArea(
        child: installationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load Firestore telemetry data',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    err.toString(),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (installations) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dashboard Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Analytics Overview',
                                      style: theme.textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Real-time MediaRescue telemetry & FCM metrics',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              if (!isNarrow)
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.devices_rounded, size: 18),
                                  label: const Text('View All Devices'),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    onNavigateToDeviceList();
                                  },
                                ),
                            ],
                          ),
                          if (isNarrow) ...[
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.devices_rounded, size: 18),
                                label: const Text('View All Devices'),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  onNavigateToDeviceList();
                                },
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // Stat Cards Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      if (isMobile) {
                        return Column(
                          children: [
                            StatCard(
                              title: 'Total Installations',
                              value: '${analyticsSummary.totalDevices}',
                              subtitle: 'Recorded device telemetry docs',
                              icon: Icons.smartphone_rounded,
                              iconColor: const Color(0xFF6366F1),
                            ),
                            const SizedBox(height: 12),
                            StatCard(
                              title: 'Active Users (30d)',
                              value: '${analyticsSummary.activeUsers30Days}',
                              subtitle: 'Active app opens in 30 days',
                              icon: Icons.person_pin_circle_rounded,
                              iconColor: const Color(0xFF10B981),
                            ),
                            const SizedBox(height: 12),
                            StatCard(
                              title: 'Active FCM Tokens',
                              value: '${analyticsSummary.activeFcmTokens}',
                              subtitle: 'Devices ready for push notifications',
                              icon: Icons.notifications_active_rounded,
                              iconColor: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      } else {
                        return Row(
                          children: [
                            Expanded(
                              child: StatCard(
                                title: 'Total Installations',
                                value: '${analyticsSummary.totalDevices}',
                                subtitle: 'Recorded device telemetry docs',
                                icon: Icons.smartphone_rounded,
                                iconColor: const Color(0xFF6366F1),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Active Users (30d)',
                                value: '${analyticsSummary.activeUsers30Days}',
                                subtitle: 'Active app opens in 30 days',
                                icon: Icons.person_pin_circle_rounded,
                                iconColor: const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: StatCard(
                                title: 'Active FCM Tokens',
                                value: '${analyticsSummary.activeFcmTokens}',
                                subtitle: 'Devices ready for push notifications',
                                icon: Icons.notifications_active_rounded,
                                iconColor: const Color(0xFFF59E0B),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Analytical Charts Grid
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 900;
                      if (isMobile) {
                        return Column(
                          children: [
                            SizedBox(
                              height: 360,
                              child: ChartCard(
                                title: 'App Version Distribution',
                                subtitle: 'Installed versions breakdown across devices',
                                child: PieChartDistributionWidget(
                                  dataMap: analyticsSummary.appVersionDistribution,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 360,
                              child: ChartCard(
                                title: 'Android Version Distribution',
                                subtitle: 'Android OS releases running MediaRescue',
                                child: PieChartDistributionWidget(
                                  dataMap: analyticsSummary.androidVersionDistribution,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 360,
                              child: ChartCard(
                                title: 'Top Device Models',
                                subtitle: 'Most common hardware devices',
                                child: BarChartTopModelsWidget(
                                  dataMap: analyticsSummary.topDeviceModels,
                                ),
                              ),
                            ),
                          ],
                        );
                      } else {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 360,
                                    child: ChartCard(
                                      title: 'App Version Distribution',
                                      subtitle: 'Installed versions breakdown across devices',
                                      child: PieChartDistributionWidget(
                                        dataMap: analyticsSummary.appVersionDistribution,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: SizedBox(
                                    height: 360,
                                    child: ChartCard(
                                      title: 'Android Version Distribution',
                                      subtitle: 'Android OS releases running MediaRescue',
                                      child: PieChartDistributionWidget(
                                        dataMap: analyticsSummary.androidVersionDistribution,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 360,
                              child: ChartCard(
                                title: 'Top Device Models',
                                subtitle: 'Most common hardware devices registered in Firestore',
                                child: BarChartTopModelsWidget(
                                  dataMap: analyticsSummary.topDeviceModels,
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
