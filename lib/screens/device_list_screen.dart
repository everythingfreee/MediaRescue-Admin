import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../models/installation_model.dart';
import '../providers/admin_providers.dart';
import '../theme/glass_theme.dart';
import '../widgets/device_card.dart';
import '../widgets/device_detail_bottom_sheet.dart';

/// The device telemetry explorer: a glass search/filter bar, a glass
/// multi-selection toolbar, and a list of lite-glass device rows.
class DeviceListScreen extends ConsumerStatefulWidget {
  final VoidCallback onNavigateToNotificationScreen;

  const DeviceListScreen({
    super.key,
    required this.onNavigateToNotificationScreen,
  });

  @override
  ConsumerState<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends ConsumerState<DeviceListScreen> {
  final _searchController = TextEditingController();
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = <String>{};
  bool _isBatchDeleting = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectionMode(String initialId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(initialId);
    });
  }

  void _exitSelectionMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleItemSelection(String id, bool selected) {
    HapticFeedback.selectionClick();
    setState(() {
      if (selected) {
        _selectedIds.add(id);
      } else {
        _selectedIds.remove(id);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  void _selectAll(List<InstallationModel> currentList) {
    HapticFeedback.lightImpact();
    setState(() {
      if (_selectedIds.length == currentList.length) {
        _selectedIds.clear();
        _isSelectionMode = false;
      } else {
        _selectedIds.clear();
        _selectedIds.addAll(currentList.map((e) => e.installationId));
      }
    });
  }

  Future<void> _handleBatchDelete(List<InstallationModel> currentList) async {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final count = _selectedIds.length;
    final bool? confirm = await showLiquidGlassDialog<bool>(
      context: context,
      builder: (dialogContext) => LiquidGlassAlertDialog(
        icon: const Icon(
          Icons.delete_sweep_rounded,
          color: GlassPalette.iosRed,
          size: 42,
        ),
        title: const Text('Delete Device Records'),
        content: Text(
          'Are you sure you want to permanently delete $count device '
          'telemetry document(s) from Firestore?',
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
            label: 'Delete',
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
      setState(() => _isBatchDeleting = true);
      try {
        final analyticsService = ref.read(analyticsServiceProvider);
        await analyticsService.batchDeleteInstallations(_selectedIds.toList());
        if (!mounted) return;

        showGlassToast(
          context,
          'Successfully deleted $count device record(s)',
          type: GlassToastType.success,
        );
        _exitSelectionMode();
      } catch (e) {
        if (!mounted) return;
        showGlassToast(
          context,
          'Failed to delete records: ${e.toString()}',
          type: GlassToastType.error,
        );
      } finally {
        if (mounted) setState(() => _isBatchDeleting = false);
      }
    }
  }

  void _handleBatchSendPush(List<InstallationModel> currentList) {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final selectedDevices =
        currentList.where((d) => _selectedIds.contains(d.installationId));
    final tokens = selectedDevices
        .where((d) => d.hasFcmToken)
        .map((d) => d.fcmToken!)
        .toList();

    if (tokens.isEmpty) {
      showGlassToast(
        context,
        'None of the selected devices have an active FCM token registered.',
        type: GlassToastType.warning,
      );
      return;
    }

    // Set multiple tokens in push notification provider
    ref.read(pushNotificationProvider.notifier).setMultipleTokens(tokens);

    _exitSelectionMode();
    widget.onNavigateToNotificationScreen();
  }

  void _showDetailBottomSheet(InstallationModel installation) {
    HapticFeedback.lightImpact();
    DeviceDetailBottomSheet.show(
      context: context,
      installation: installation,
      onNavigateToNotificationScreen: widget.onNavigateToNotificationScreen,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = ref.watch(filteredInstallationsProvider);
    final allDevices = ref.watch(installationsStreamProvider).value ?? [];
    final searchQuery = ref.watch(deviceSearchQueryProvider);
    final selectedAppVer = ref.watch(appVersionFilterProvider);
    final selectedAndroidVer = ref.watch(androidVersionFilterProvider);

    final List<String> uniqueAppVersions = allDevices
        .map((e) => e.appVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final List<String> uniqueAndroidVersions = allDevices
        .map((e) => e.androidVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final bool allSelected =
        filteredDevices.isNotEmpty && _selectedIds.length == filteredDevices.length;
    final bool hasFilters = selectedAppVer != null ||
        selectedAndroidVer != null ||
        searchQuery.isNotEmpty;

    final EdgeInsets shellInsets = glassPagePadding(context, horizontal: 16);

    return Column(
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(
            left: shellInsets.left,
            right: shellInsets.right,
            top: shellInsets.top,
            bottom: 10,
          ),
          child: _isSelectionMode
              ? _buildSelectionBar(filteredDevices, allSelected)
              : _buildSearchAndFilters(
                  searchQuery: searchQuery,
                  uniqueAppVersions: uniqueAppVersions,
                  uniqueAndroidVersions: uniqueAndroidVersions,
                  selectedAppVer: selectedAppVer,
                  selectedAndroidVer: selectedAndroidVer,
                  hasFilters: hasFilters,
                ),
        ),

        // Count / hint line
        Padding(
          padding: EdgeInsets.only(
            left: shellInsets.left + 4,
            right: 20,
            bottom: 8,
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  _isSelectionMode
                      ? 'Select devices to delete data or send push notifications'
                      : 'Showing ${filteredDevices.length} of '
                          '${allDevices.length} devices (long press to multi-select)',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: GlassPalette.textTertiary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 10),
              const GlassChip(
                label: 'Real-time Sync',
                icon: Icons.bolt_rounded,
                iconColor: GlassPalette.iosGreen,
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredDevices.isEmpty
              ? _buildEmptyState(shellInsets)
              : ListView.builder(
                  itemCount: filteredDevices.length,
                  padding: EdgeInsets.only(
                    left: shellInsets.left,
                    bottom: shellInsets.bottom + 16,
                  ),
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    final item = filteredDevices[index];
                    final bool isSelected =
                        _selectedIds.contains(item.installationId);

                    return DeviceCard(
                      installation: item,
                      isSelectionMode: _isSelectionMode,
                      isSelected: isSelected,
                      onSelectChanged: (val) {
                        _toggleItemSelection(
                          item.installationId,
                          val ?? false,
                        );
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelectionMode(item.installationId);
                        }
                      },
                      onTap: () => _showDetailBottomSheet(item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  /// The contextual toolbar shown while multi-selection is active.
  Widget _buildSelectionBar(
    List<InstallationModel> filteredDevices,
    bool allSelected,
  ) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      style: GlassStyles.card.copyWith(
        appearance: const LiquidGlassAppearance(
          color: Color(0x3D6366F1),
          // blur: LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
          // shadow: LiquidGlassShadow(blur: 4, opacity: 0.26),
        ),
      ),
      child: Row(
        children: <Widget>[
          GlassIconButton(
            icon: Icons.close_rounded,
            size: 36,
            iconSize: 18,
            tooltip: 'Cancel selection',
            onPressed: _exitSelectionMode,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_selectedIds.length} Selected',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: GlassPalette.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GlassIconButton(
            icon: allSelected
                ? Icons.deselect_rounded
                : Icons.select_all_rounded,
            size: 36,
            iconSize: 18,
            tooltip: allSelected ? 'Deselect All' : 'Select All',
            onPressed: () => _selectAll(filteredDevices),
          ),
          const SizedBox(width: 8),
          GlassIconButton(
            icon: Icons.send_rounded,
            size: 36,
            iconSize: 18,
            color: GlassPalette.iosGreen,
            tooltip: 'Send Push to Selected',
            onPressed: () => _handleBatchSendPush(filteredDevices),
          ),
          const SizedBox(width: 8),
          if (_isBatchDeleting)
            const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            GlassIconButton(
              icon: Icons.delete_forever_rounded,
              size: 36,
              iconSize: 18,
              color: GlassPalette.iosRed,
              tooltip: 'Delete Selected Data',
              onPressed: () => _handleBatchDelete(filteredDevices),
            ),
        ],
      ),
    );
  }

  /// Search field, the two glass selects and the clear-filters affordance.
  Widget _buildSearchAndFilters({
    required String searchQuery,
    required List<String> uniqueAppVersions,
    required List<String> uniqueAndroidVersions,
    required String? selectedAppVer,
    required String? selectedAndroidVer,
    required bool hasFilters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GlassField(
          controller: _searchController,
          hint: 'Search by Installation UUID or Device Model…',
          prefixIcon: Icons.search_rounded,
          onChanged: (val) {
            ref.read(deviceSearchQueryProvider.notifier).state = val;
          },
          suffixIcon: searchQuery.isNotEmpty
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _searchController.clear();
                    ref.read(deviceSearchQueryProvider.notifier).state = '';
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(
                      Icons.clear_rounded,
                      size: 18,
                      color: GlassPalette.textTertiary,
                    ),
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: GlassSelectField<String>(
                label: 'App Version',
                icon: Icons.system_update_rounded,
                placeholder: 'All versions',
                value: selectedAppVer,
                options: uniqueAppVersions
                    .map(
                      (ver) => GlassSelectOption<String>(
                        value: ver,
                        label: 'v$ver',
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  ref.read(appVersionFilterProvider.notifier).state = val;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GlassSelectField<String>(
                label: 'Android OS',
                icon: Icons.android_rounded,
                placeholder: 'All releases',
                value: selectedAndroidVer,
                options: uniqueAndroidVersions
                    .map(
                      (ver) => GlassSelectOption<String>(
                        value: ver,
                        label: ver,
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  ref.read(androidVersionFilterProvider.notifier).state = val;
                },
              ),
            ),
          ],
        ),
        if (hasFilters) ...<Widget>[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: GlassChip(
              label: 'Clear Filters',
              icon: Icons.filter_alt_off_rounded,
              color: GlassTints.selected,
              textColor: GlassPalette.textPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              onTap: () {
                HapticFeedback.lightImpact();
                _searchController.clear();
                ref.read(deviceSearchQueryProvider.notifier).state = '';
                ref.read(appVersionFilterProvider.notifier).state = null;
                ref.read(androidVersionFilterProvider.notifier).state = null;
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState(EdgeInsets shellInsets) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: shellInsets.left + 24,
          right: 24,
          top: 24,
          bottom: shellInsets.bottom + 24,
        ),
        child: const GlassCard(
          padding: EdgeInsets.all(26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.devices_other_rounded,
                size: 54,
                color: GlassPalette.textTertiary,
              ),
              SizedBox(height: 14),
              Text(
                'No matching device records found',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: GlassPalette.textPrimary,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Try adjusting your search query or dropdown filter selection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: GlassPalette.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

