import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../providers/admin_providers.dart';
import '../theme/glass_theme.dart';
import 'dashboard_screen.dart';
import 'device_list_screen.dart';
import 'notification_screen.dart';

/// Shell geometry, shared between the scaffold and the pages' padding.
const double _kAppBarHeight = 58;
const double _kAppBarMargin = 6;
const double _kTabBarHeight = 64;
const double _kTabBarMargin = 20;
const double _kRailWidth = 66;

/// Width at which the bottom tab bar gives way to a glass side rail.
const double _kWideBreakpoint = 800;

/// The three destinations, shared by the tab bar and the wide-screen rail.
const List<LiquidGlassTabBarItem> kNavigationTabs = <LiquidGlassTabBarItem>[
  LiquidGlassTabBarItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    label: 'Dashboard',
  ),
  LiquidGlassTabBarItem(
    icon: Icons.phone_android_outlined,
    selectedIcon: Icons.phone_android_rounded,
    label: 'Devices',
  ),
  LiquidGlassTabBarItem(
    icon: Icons.send_outlined,
    selectedIcon: Icons.send_rounded,
    label: 'FCM Push',
  ),
];

const LiquidGlassTabItemStyle kNavigationTabItemStyle =
    LiquidGlassTabItemStyle(
  selectedColor: Colors.white,
  unselectedColor: Color(0xB3FFFFFF),
  iconSize: 23,
  underGlassIconSize: 26,
  labelFontSize: 10.5,
  underGlassLabelFontSize: 11.5,
);

/// The refracting morph pill where the shader can run (Impeller); a soft
/// sliding highlight elsewhere, so a Skia device never pays for the tab
/// bar's second capture.
const LiquidGlassTabPillStyle kNavigationTabPillStyle =
    LiquidGlassTabPillStyle(
  mode: LiquidGlassPillMode.impellerOnly,
  animated: true,
  // // blur: LiquidGlassBlur(sigmaX: 0, sigmaY: 0),
  growHeight: 16,
  distortion: 0.13,
  distortionWidth: 22,
  rest: GlassStyles.pillRest,
  glassStyle: GlassStyles.pillGlass,
);

/// The app shell: a [LiquidGlassScaffold] owning one glass pipeline, with
/// a floating glass app bar, the iOS-style tab bar (or side rail), and the
/// three pages refracting behind all of it.
class MainNavigationScreen extends ConsumerStatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  ConsumerState<MainNavigationScreen> createState() =>
      _MainNavigationScreenState();
}

class _MainNavigationScreenState extends ConsumerState<MainNavigationScreen> {
  int _selectedIndex = 0;

  void _onSelectItem(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _confirmSignOut() async {
    HapticFeedback.lightImpact();
    final authService = ref.read(adminAuthServiceProvider);

    final bool? confirm = await showLiquidGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => LiquidGlassAlertDialog(
        icon: const Icon(
          Icons.logout_rounded,
          color: GlassPalette.iosRed,
          size: 38,
        ),
        title: const Text('Sign Out'),
        content: const Text(
          'Are you sure you want to sign out of MediaRescue Admin?',
          textAlign: TextAlign.center,
        ),
        actions: <Widget>[
          LiquidGlassButton(
            label: 'Cancel',
            height: 44,
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.of(dialogContext).pop(false);
            },
          ),
          LiquidGlassButton(
            label: 'Sign Out',
            height: 44,
            style: LiquidGlassButton.defaultStyle.copyWith(
              appearance: const LiquidGlassAppearance(
                color: GlassTints.accentRed,
              ),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.of(dialogContext).pop(true);
            },
          ),
        ],
      ),
    );

    if (confirm == true) {
      await authService.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final String adminEmail =
        ref.watch(currentAdminUserProvider).value?.email ?? '';

    final List<Widget> pages = <Widget>[
      DashboardScreen(
        onNavigateToDeviceList: () => _onSelectItem(1),
      ),
      DeviceListScreen(
        onNavigateToNotificationScreen: () => _onSelectItem(2),
      ),
      const NotificationScreen(),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWide = constraints.maxWidth >= _kWideBreakpoint;
        final bool compactBar = constraints.maxWidth < 600;
        final double safeTop = mq.padding.top;
        final double safeBottom = mq.padding.bottom;

        // Room the floating chrome takes, handed to the pages so their
        // scrollables start clear of it while still sliding underneath.
        final double shellTop = safeTop + _kAppBarHeight + _kAppBarMargin + 12;
        final double shellBottom = isWide
            ? safeBottom + 28
            : safeBottom + _kTabBarMargin + _kTabBarHeight + 12;
        final double shellLeft = isWide ? _kRailWidth + 34 : 0;

        final double appBarWidth = math.min(constraints.maxWidth - 24, 620);
        final double tabBarWidth = math.min(constraints.maxWidth - 48, 340);

        return LiquidGlassScaffold(
          appBarTopMargin: _kAppBarMargin,
          adaptivity: const LiquidGlassScaffoldAdaptivity(kAdminAdaptivity),
          // Wide screens get a floating rail of glass buttons instead of
          // the bottom capsule — one shared backdrop read for all three.
          lenses: isWide
              ? <Widget>[
                  Positioned(
                    left: 12,
                    top: shellTop,
                    bottom: shellBottom,
                    child: _GlassSideRail(
                      selectedIndex: _selectedIndex,
                      onSelect: _onSelectItem,
                    ),
                  ),
                ]
              : const <Widget>[],
          appBar: LiquidGlassAppBar(
            width: appBarWidth,
            height: _kAppBarHeight,
            centerTitle: false,
            style: GlassStyles.bar,
            foregroundColor: GlassPalette.textPrimary,
            touch: const LiquidGlassTouch.flexing(LiquidGlassFlex.subtle()),
            leading: const _AdminLogo(),
            title: Text(
              compactBar ? 'MediaRescue' : 'MediaRescue Admin',
              style: const TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            actions: <Widget>[
              if (adminEmail.isNotEmpty)
                if (compactBar)
                  GlassIconButton(
                    icon: Icons.verified_user_rounded,
                    size: 36,
                    iconSize: 18,
                    color: GlassPalette.iosGreen,
                    tooltip: adminEmail,
                    onPressed: () => showGlassToast(
                      context,
                      'Signed in as $adminEmail',
                    ),
                  )
                else
                  _AdminBadge(email: adminEmail),
              GlassIconButton(
                icon: Icons.logout_rounded,
                tooltip: 'Sign Out',
                size: 38,
                iconSize: 18,
                onPressed: _confirmSignOut,
              ),
            ],
          ),
          bottomNavigationBar: isWide
              ? null
              : LiquidGlassTabBar(
                  items: kNavigationTabs,
                  selectedIndex: _selectedIndex,
                  onChanged: _onSelectItem,
                  width: tabBarWidth,
                  height: _kTabBarHeight,
                  margin: const EdgeInsets.only(bottom: _kTabBarMargin),
                  itemPadding: 6,
                  style: GlassStyles.tabBar,
                  itemStyle: kNavigationTabItemStyle,
                  // The refracting morph pill where the shader can run
                  // (Impeller); a soft sliding highlight elsewhere, so a
                  // Skia device never pays for a second capture.
                  pillStyle: kNavigationTabPillStyle,
                ),
          body: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const GlassBackdrop(),
              GlassShellInsets(
                top: shellTop,
                bottom: shellBottom,
                left: shellLeft,
                // A transparent Scaffold under the pixels: it paints
                // nothing (so the glass still sees the backdrop), but it
                // gives every page the `Material` ancestor its text fields
                // need, hosts the glass toasts, and reflows the content
                // when a keyboard opens.
                child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: IndexedStack(
                    index: _selectedIndex,
                    children: pages,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The little glass tile holding the app's shield glyph.
class _AdminLogo extends StatelessWidget {
  const _AdminLogo();

  @override
  Widget build(BuildContext context) {
    return const GlassLiteSurface(
      shape: GlassStyles.liteChipShape,
      color: GlassTints.selected,
      padding: EdgeInsets.all(6),
      child: Icon(
        Icons.admin_panel_settings_rounded,
        size: 19,
        color: GlassPalette.textPrimary,
      ),
    );
  }
}

/// The signed-in admin's email, as a glass badge.
class _AdminBadge extends StatelessWidget {
  const _AdminBadge({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 190),
      child: GlassLiteSurface(
        shape: GlassStyles.liteCircleShape,
        color: GlassTints.chip,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.verified_user_rounded,
              size: 14,
              color: GlassPalette.iosGreen,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                email,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: GlassPalette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The wide-screen navigation rail: glass tiles sharing **one** backdrop
/// read through [LiquidGlassBatch], since they are a toolbar of lenses.
class _GlassSideRail extends StatelessWidget {
  const _GlassSideRail({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const List<_RailEntry> _entries = <_RailEntry>[
    _RailEntry(icon: Icons.dashboard_rounded, label: 'Dash'),
    _RailEntry(icon: Icons.phone_android_rounded, label: 'Devices'),
    _RailEntry(icon: Icons.send_rounded, label: 'Push'),
  ];

  @override
  Widget build(BuildContext context) {
    return LiquidGlassBatch(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int i = 0; i < _entries.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: _GlassRailButton(
                entry: _entries[i],
                selected: i == selectedIndex,
                onTap: () => onSelect(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _RailEntry {
  const _RailEntry({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _GlassRailButton extends StatelessWidget {
  const _GlassRailButton({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final _RailEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color tint = selected ? Colors.white : GlassPalette.textSecondary;

    return LiquidGlassLens(
      style: selected ? GlassStyles.railItemSelected : GlassStyles.railItem,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: SizedBox(
          width: _kRailWidth,
          height: 62,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(entry.icon, size: 21, color: tint),
              const SizedBox(height: 3),
              Text(
                entry.label,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: tint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

