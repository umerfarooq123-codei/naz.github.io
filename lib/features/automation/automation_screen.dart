import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AutomationController extends GetxController {
  var selectedPeriod = 'Daily'.obs;

  // 🗓️ New reactive date range variables
  var fromDate = DateTime.now()
      .subtract(const Duration(days: 30))
      .obs; // Default: 30 days ago
  var toDate = DateTime.now().obs; // Default: today

  @override
  void onInit() {
    super.onInit();
    loadSavedPeriod();
    loadSavedDates();
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
    final screenWidth = MediaQuery.of(context).size.width;

    return BaseLayout(
      appBarTitle: 'Automation & Integrations',
      showBackButton: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(
              () => SizedBox(
                width: screenWidth / 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Showing expenses with ${controller.selectedPeriod.value} frequency',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: screenWidth / 4,
                      child: DropdownButtonFormField<String>(
                        initialValue: controller.selectedPeriod.value,
                        decoration: InputDecoration(
                          labelText: 'Period',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['Daily', 'Weekly', 'Monthly']
                            .map(
                              (period) => DropdownMenuItem(
                                value: period,
                                child: Text(period),
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
                    const SizedBox(height: 20),

                    // 🗓️ From Date Picker
                    Text(
                      'Select Date Range for Sales Trend:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        // FROM Date
                        Expanded(
                          child: GestureDetector(
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'From: ${controller.fromDate.value.toLocal().toString().split(' ')[0]}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // TO Date
                        Expanded(
                          child: GestureDetector(
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
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'To: ${controller.toDate.value.toLocal().toString().split(' ')[0]}',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ThemeToggleButton(showText: true),
            // Other widgets remain unchanged...
          ],
        ),
      ),
    );
  }
}
