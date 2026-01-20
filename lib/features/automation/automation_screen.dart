import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ledger_master/core/services/sheet_sync_service.dart';
import 'package:ledger_master/core/utils/app_snackbars.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutomationController extends GetxController {
  var selectedPeriod = 'Daily'.obs;
  SheetSyncService get syncService => Get.find<SheetSyncService>();

  // 🗓️ New reactive date range variables
  var fromDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs; // Default: 30 days ago
  var toDate = DateTime.now().obs; // Default: today

  // ⏰ Backup sync timer variables
  var syncHours = 0.obs;
  var syncMinutes = 0.obs;
  var isSyncEnabled = false.obs;

  // Text editing controllers for proper text handling
  final hoursController = TextEditingController();
  final minutesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadSavedPeriod();
    loadSavedDates();
    loadBackupSettings();
  }

  @override
  void onClose() {
    hoursController.dispose();
    minutesController.dispose();
    super.onClose();
  }

  // ─── Period Persistence ────────────────────────────────
  Future<void> loadSavedPeriod() async {
    final prefs = await SharedPreferences.getInstance();
    selectedPeriod.value = prefs.getString('expense_period') ?? 'Daily';
  }

  Future<void> savePeriod(String period) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('expense_period', period);
    selectedPeriod.value = period;
  }

  // ─── Date Range Persistence ────────────────────────────
  Future<void> loadSavedDates() async {
    final prefs = await SharedPreferences.getInstance();

    final fromString = prefs.getString('from_date');
    final toString = prefs.getString('to_date');

    if (fromString != null) {
      fromDate.value = DateTime.parse(fromString);
    }
    if (toString != null) {
      toDate.value = DateTime.parse(toString);
    }
  }

  Future<void> saveDates(DateTime from, DateTime to) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('from_date', from.toIso8601String());
    await prefs.setString('to_date', to.toIso8601String());

    fromDate.value = from;
    toDate.value = to;
  }

  // ─── Backup Sync Settings ──────────────────────────────
  Future<void> loadBackupSettings() async {
    final prefs = await SharedPreferences.getInstance();

    // Load sync settings
    final syncData = prefs.getString('backup_sync_settings');
    if (syncData != null) {
      final map = jsonDecode(syncData) as Map<String, dynamic>;
      syncHours.value = map['hours'] ?? 0;
      syncMinutes.value = map['minutes'] ?? 0;
      isSyncEnabled.value = map['enabled'] ?? false;

      // Update text controllers
      hoursController.text = syncHours.value.toString();
      minutesController.text = syncMinutes.value.toString();
    }
  }

  Future<void> saveBackupSettings({
    required int hours,
    required int minutes,
    required bool enabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    debugPrint('caleld');
    final syncData = jsonEncode({
      'hours': hours,
      'minutes': minutes,
      'enabled': enabled,
    });

    await prefs.setString('backup_sync_settings', syncData);

    syncHours.value = hours;
    syncMinutes.value = minutes;
    isSyncEnabled.value = enabled;

    // Also update sync service settings
    try {
      await syncService.updateSyncSettings({
        'hours': hours,
        'minutes': minutes,
        'enabled': enabled,
      });
    } catch (e) {
      debugPrint('Sync service not found: $e');
    }

    // Show confirmation snackbar
    if (enabled) {
      // Get the formatted time for the snackbar message
      String timeText;
      if (hours == 0 && minutes == 0) {
        timeText = 'Not set (will sync immediately)';
      } else {
        final hoursText = hours > 0 ? '$hours hr${hours > 1 ? 's' : ''}' : '';
        final minutesText = minutes > 0
            ? '$minutes min${minutes > 1 ? 's' : ''}'
            : '';

        if (hoursText.isNotEmpty && minutesText.isNotEmpty) {
          timeText = '$hoursText $minutesText';
        } else if (hoursText.isNotEmpty) {
          timeText = hoursText;
        } else {
          timeText = minutesText;
        }
      }

      AppSnackBars.showSuccess(
        'Backup Sync Enabled',
        'Automatic backup sync is now active.\nInterval: $timeText',
      );
    } else {
      AppSnackBars.showWarning(
        'Backup Sync Disabled',
        'Automatic backup sync has been turned off.',
      );
    }
  }

  // Helper method to handle text input properly
  void updateHours(String value) {
    if (value.isEmpty) {
      syncHours.value = 0;
      hoursController.clear();
      return;
    }

    // Parse the complete value, not individual digits
    final parsed = int.tryParse(value) ?? 0;
    if (parsed >= 0 && parsed <= 24) {
      syncHours.value = parsed;
    } else if (parsed > 24) {
      syncHours.value = 24;
      hoursController.text = '24';
    }
  }

  void updateMinutes(String value) {
    if (value.isEmpty) {
      syncMinutes.value = 0;
      minutesController.clear();
      return;
    }

    final parsed = int.tryParse(value) ?? 0;
    if (parsed >= 0 && parsed <= 59) {
      syncMinutes.value = parsed;
    } else if (parsed > 59) {
      syncMinutes.value = 59;
      minutesController.text = '59';
    }
  }

  String get formattedSyncTime {
    if (syncHours.value == 0 && syncMinutes.value == 0) {
      return 'Not set';
    }

    final hoursText = syncHours.value > 0
        ? '${syncHours.value} hr${syncHours.value > 1 ? 's' : ''}'
        : '';
    final minutesText = syncMinutes.value > 0
        ? '${syncMinutes.value} min${syncMinutes.value > 1 ? 's' : ''}'
        : '';

    if (hoursText.isNotEmpty && minutesText.isNotEmpty) {
      return '$hoursText $minutesText';
    } else if (hoursText.isNotEmpty) {
      return hoursText;
    } else {
      return minutesText;
    }
  }

  // ─── Helpers to get formatted months for the query ─────
  String get formattedFromMonth =>
      "${fromDate.value.year}-${fromDate.value.month.toString().padLeft(2, '0')}";
  String get formattedToMonth =>
      "${toDate.value.year}-${toDate.value.month.toString().padLeft(2, '0')}";
}

class AutomationScreen extends StatelessWidget {
  const AutomationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AutomationController>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final surfaceColor = isDarkMode
        ? Colors.grey.shade900
        : Colors.grey.shade50;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final labelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;
    final infoTextColor = isDarkMode
        ? Colors.grey.shade300
        : Colors.grey.shade800;

    return BaseLayout(
      appBarTitle: 'Automation & Integrations',
      showBackButton: false,
      onBackButtonPressed: null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header + Period Selector
                  Obx(
                    () => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Showing expenses with ${controller.selectedPeriod.value} frequency',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                        ),
                        const SizedBox(height: 12),

                        // Responsive Dropdown
                        IntrinsicWidth(
                          child: DropdownButtonFormField<String>(
                            initialValue: controller.selectedPeriod.value,
                            decoration: InputDecoration(
                              labelText: 'Period',
                              labelStyle: TextStyle(color: labelColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 16,
                              ),
                            ),
                            items: ['Daily', 'Weekly', 'Monthly']
                                .map(
                                  (period) => DropdownMenuItem(
                                    value: period,
                                    child: Text(
                                      period,
                                      style: TextStyle(color: textColor),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                controller.savePeriod(value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Date Range Section
                  Text(
                    'Select Date Range for Sales Trend:',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Obx(
                    () => Row(
                      children: [
                        // From Date Picker
                        IntrinsicWidth(
                          child: buildDateField(
                            context: context,
                            label: 'From',
                            date: controller.fromDate.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.fromDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                controller.saveDates(
                                  picked,
                                  controller.toDate.value,
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // To Date Picker
                        IntrinsicWidth(
                          child: buildDateField(
                            context: context,
                            label: 'To',
                            date: controller.toDate.value,
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: controller.toDate.value,
                                firstDate: DateTime(2020),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                controller.saveDates(
                                  controller.fromDate.value,
                                  picked,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Backup Sync Section
                  Container(
                    width: 350,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.sync, color: primaryColor, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'Backup & Sync',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Set up automatic backup sync interval to keep your data safe',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: labelColor),
                        ),
                        const SizedBox(height: 20),

                        // Manual Sync Now Button
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                await controller.syncService
                                    .manualSyncWithDialog();
                              } catch (e) {
                                AppSnackBars.showError(
                                  'Error',
                                  'Sync service not available: $e',
                                );
                              }
                            },
                            icon: const Icon(Icons.sync, size: 20),
                            label: const Text('Sync Now'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        // Container(
                        //   width: double.infinity,
                        //   margin: const EdgeInsets.only(bottom: 16),
                        //   child: ElevatedButton.icon(
                        //     onPressed: () async {
                        //       try {
                        //         await controller.syncService.importWithDialog();
                        //       } catch (e) {
                        //         AppSnackBars.showError(
                        //           'Error',
                        //           'Sync service not available: $e',
                        //         );
                        //       }
                        //     },
                        //     icon: const Icon(Icons.sync, size: 20),
                        //     label: const Text('Import Data'),
                        //     style: ElevatedButton.styleFrom(
                        //       backgroundColor: primaryColor,
                        //       foregroundColor: Colors.white,
                        //       padding: const EdgeInsets.symmetric(vertical: 16),
                        //       shape: RoundedRectangleBorder(
                        //         borderRadius: BorderRadius.circular(8),
                        //       ),
                        //     ),
                        //   ),
                        // ),

                        // Sync Settings Card
                        Obx(
                          () => Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode
                                  ? Colors.grey.shade800
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Toggle Row
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Enable Automatic Backup',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: textColor,
                                          ),
                                    ),
                                    Switch(
                                      value: controller.isSyncEnabled.value,
                                      onChanged: (value) {
                                        controller.saveBackupSettings(
                                          hours: controller.syncHours.value,
                                          minutes: controller.syncMinutes.value,
                                          enabled: value,
                                        );
                                      },
                                      activeThumbColor: primaryColor,
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Time Input Row
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Hours (0-24)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: labelColor),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller:
                                                controller.hoursController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: '0',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                              filled: !controller
                                                  .isSyncEnabled
                                                  .value,
                                              fillColor:
                                                  !controller
                                                      .isSyncEnabled
                                                      .value
                                                  ? (isDarkMode
                                                        ? Colors.grey.shade900
                                                        : Colors.grey.shade100)
                                                  : null,
                                            ),
                                            onChanged: (value) {
                                              controller.updateHours(value);
                                            },
                                            enabled:
                                                controller.isSyncEnabled.value,
                                            style: TextStyle(color: textColor),
                                            onTap: () {
                                              controller
                                                  .hoursController
                                                  .selection = TextSelection(
                                                baseOffset: 0,
                                                extentOffset: controller
                                                    .hoursController
                                                    .text
                                                    .length,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Minutes (0-59)',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: labelColor),
                                          ),
                                          const SizedBox(height: 4),
                                          TextField(
                                            controller:
                                                controller.minutesController,
                                            keyboardType: TextInputType.number,
                                            decoration: InputDecoration(
                                              hintText: '0',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                    vertical: 12,
                                                  ),
                                              filled: !controller
                                                  .isSyncEnabled
                                                  .value,
                                              fillColor:
                                                  !controller
                                                      .isSyncEnabled
                                                      .value
                                                  ? (isDarkMode
                                                        ? Colors.grey.shade900
                                                        : Colors.grey.shade100)
                                                  : null,
                                            ),
                                            onChanged: (value) {
                                              controller.updateMinutes(value);
                                            },
                                            enabled:
                                                controller.isSyncEnabled.value,
                                            style: TextStyle(color: textColor),
                                            onTap: () {
                                              controller
                                                  .minutesController
                                                  .selection = TextSelection(
                                                baseOffset: 0,
                                                extentOffset: controller
                                                    .minutesController
                                                    .text
                                                    .length,
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                // Current Settings & Save Button
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Settings:',
                                            style: Theme.of(context)
                                                .textTheme
                                                .labelMedium
                                                ?.copyWith(color: labelColor),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            controller.isSyncEnabled.value
                                                ? controller.formattedSyncTime
                                                : 'Disabled',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyLarge
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      controller
                                                          .isSyncEnabled
                                                          .value
                                                      ? primaryColor
                                                      : Colors.grey,
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        controller.saveBackupSettings(
                                          hours: controller.syncHours.value,
                                          minutes: controller.syncMinutes.value,
                                          enabled:
                                              controller.isSyncEnabled.value,
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: primaryColor,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Save',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Info Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Automatic Backup:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: primaryColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '• Backup sync runs at the specified interval\n• Manual sync is available anytime\n• Requires internet connectivity\n• Data is encrypted during transfer',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(color: infoTextColor),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const ThemeToggleButton(showText: true),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget buildDateField({
    required BuildContext context,
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final labelColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          borderRadius: BorderRadius.circular(8),
          color: isDarkMode ? Colors.grey.shade900 : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label Date',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: labelColor),
            ),
            const SizedBox(height: 4),
            Text(
              date.toLocal().toString().split(' ')[0],
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
