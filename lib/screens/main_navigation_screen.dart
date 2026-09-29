import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/admin_providers.dart';
import 'dashboard_screen.dart';
import 'device_list_screen.dart';
import 'notification_screen.dart';

class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onSelectItem(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final adminUserAsync = ref.watch(currentAdminUserProvider);
    final authService = ref.read(adminAuthServiceProvider);

    final pages = [
      DashboardScreen(
        onNavigateToDeviceList: () => _onSelectItem(1),
      ),
      DeviceListScreen(
        onNavigateToNotificationScreen: () => _onSelectItem(2),
      ),
      const NotificationScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        elevation: 1,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'MediaRescue Admin',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          // Active Admin User Email Badge
          adminUserAsync.when(
            data: (admin) => admin != null
                ? Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          size: 14,
                          color: Colors.greenAccent.shade400,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            admin.email,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          // Sign Out Button
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              HapticFeedback.lightImpact();
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out of MediaRescue Admin?'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        Navigator.of(context).pop(false);
                      },
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).pop(true);
                      },
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authService.signOut();
              }
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 800;

          if (isWideScreen) {
            return Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: _onSelectItem,
                  labelType: NavigationRailLabelType.all,
                  leading: const SizedBox(height: 12),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard_rounded),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.phone_android_outlined),
                      selectedIcon: Icon(Icons.phone_android_rounded),
                      label: Text('Devices'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.send_outlined),
                      selectedIcon: Icon(Icons.send_rounded),
                      label: Text('FCM Push'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: pages[_selectedIndex]),
              ],
            );
          } else {
            return IndexedStack(
              index: _selectedIndex,
              children: pages,
            );
          }
        },
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final isWideScreen = constraints.maxWidth >= 800;
          if (isWideScreen) return const SizedBox.shrink();

          return NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onSelectItem,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.phone_android_outlined),
                selectedIcon: Icon(Icons.phone_android_rounded),
                label: 'Devices',
              ),
              NavigationDestination(
                icon: Icon(Icons.send_outlined),
                selectedIcon: Icon(Icons.send_rounded),
                label: 'FCM Push',
              ),
            ],
          );
        },
      ),
    );
  }
}
