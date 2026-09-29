import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/installation_model.dart';
import '../providers/admin_providers.dart';
import '../widgets/device_card.dart';
import '../widgets/device_detail_bottom_sheet.dart';

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
  final Set<String> _selectedIds = {};
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 44),
        title: const Text('Delete Device Records'),
        content: Text(
          'Are you sure you want to permanently delete $count device telemetry document(s) from Firestore?',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deleted $count device record(s)'),
            backgroundColor: Colors.greenAccent.shade700,
          ),
        );
        _exitSelectionMode();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete records: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      } finally {
        if (mounted) setState(() => _isBatchDeleting = false);
      }
    }
  }

  void _handleBatchSendPush(List<InstallationModel> currentList) {
    if (_selectedIds.isEmpty) return;
    HapticFeedback.mediumImpact();

    final selectedDevices = currentList.where((d) => _selectedIds.contains(d.installationId));
    final tokens = selectedDevices
        .where((d) => d.hasFcmToken)
        .map((d) => d.fcmToken!)
        .toList();

    if (tokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('None of the selected devices have an active FCM token registered.'),
          backgroundColor: Colors.amber,
        ),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DeviceDetailBottomSheet(
          installation: installation,
          onNavigateToNotificationScreen: widget.onNavigateToNotificationScreen,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredDevices = ref.watch(filteredInstallationsProvider);
    final allDevices = ref.watch(installationsStreamProvider).value ?? [];
    final searchQuery = ref.watch(deviceSearchQueryProvider);
    final selectedAppVer = ref.watch(appVersionFilterProvider);
    final selectedAndroidVer = ref.watch(androidVersionFilterProvider);

    final uniqueAppVersions = allDevices
        .map((e) => e.appVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final uniqueAndroidVersions = allDevices
        .map((e) => e.androidVersion)
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    final allSelected = filteredDevices.isNotEmpty && _selectedIds.length == filteredDevices.length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Contextual Header when in Multi-Selection Mode
            if (_isSelectionMode)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: _exitSelectionMode,
                      tooltip: 'Cancel selection',
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedIds.length} Selected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),

                    // Select All Toggle
                    IconButton(
                      icon: Icon(
                        allSelected ? Icons.deselect_rounded : Icons.select_all_rounded,
                      ),
                      tooltip: allSelected ? 'Deselect All' : 'Select All',
                      onPressed: () => _selectAll(filteredDevices),
                    ),

                    // Push Action
                    IconButton(
                      icon: const Icon(Icons.send_rounded),
                      tooltip: 'Send Push to Selected',
                      color: theme.colorScheme.primary,
                      onPressed: () => _handleBatchSendPush(filteredDevices),
                    ),

                    // Delete Action
                    IconButton(
                      icon: _isBatchDeleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.delete_forever_rounded),
                      tooltip: 'Delete Selected Data',
                      color: Colors.redAccent,
                      onPressed: _isBatchDeleting ? null : () => _handleBatchDelete(filteredDevices),
                    ),
                  ],
                ),
              )
            else
              // Standard Search & Filter Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(deviceSearchQueryProvider.notifier).state = val;
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by Installation UUID or Device Model...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        suffixIcon: searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded),
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  _searchController.clear();
                                  ref.read(deviceSearchQueryProvider.notifier).state = '';
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          DropdownButton<String?>(
                            value: selectedAppVer,
                            hint: const Text('App Version: All'),
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('App Version: All'),
                              ),
                              ...uniqueAppVersions.map(
                                (ver) => DropdownMenuItem<String?>(
                                  value: ver,
                                  child: Text('v$ver'),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              ref.read(appVersionFilterProvider.notifier).state = val;
                            },
                          ),
                          const SizedBox(width: 16),

                          DropdownButton<String?>(
                            value: selectedAndroidVer,
                            hint: const Text('Android OS: All'),
                            underline: const SizedBox.shrink(),
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Android OS: All'),
                              ),
                              ...uniqueAndroidVersions.map(
                                (ver) => DropdownMenuItem<String?>(
                                  value: ver,
                                  child: Text(ver),
                                ),
                              ),
                            ],
                            onChanged: (val) {
                              HapticFeedback.selectionClick();
                              ref.read(androidVersionFilterProvider.notifier).state = val;
                            },
                          ),
                          const SizedBox(width: 16),

                          if (selectedAppVer != null || selectedAndroidVer != null || searchQuery.isNotEmpty)
                            TextButton.icon(
                              icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                              label: const Text('Clear Filters'),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                _searchController.clear();
                                ref.read(deviceSearchQueryProvider.notifier).state = '';
                                ref.read(appVersionFilterProvider.notifier).state = null;
                                ref.read(androidVersionFilterProvider.notifier).state = null;
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const Divider(height: 1),

            // Count Info Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _isSelectionMode
                          ? 'Select devices to delete data or send push notifications'
                          : 'Showing ${filteredDevices.length} of ${allDevices.length} devices (Long press to multi-select)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Real-time Sync',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.greenAccent.shade400,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            // Device Telemetry List
            Expanded(
              child: filteredDevices.isEmpty
                  ? Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.devices_other_rounded,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No matching device records found',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search query or dropdown filter selection.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filteredDevices.length,
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final item = filteredDevices[index];
                        final isSelected = _selectedIds.contains(item.installationId);

                        return DeviceCard(
                          installation: item,
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onSelectChanged: (val) {
                            _toggleItemSelection(item.installationId, val ?? false);
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
        ),
      ),
    );
  }
}
