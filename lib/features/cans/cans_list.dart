// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/components/constants.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';

import 'cans_controller.dart';
import 'cans_table.dart';
import 'create_cans_table.dart';

class CansList extends StatelessWidget {
  const CansList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CansController(Get.find()));
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(
      () => BaseLayout(
        showBackButton: false,
        appBarTitle: "Cans Management",
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => controller.searchQuery.value = value,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: 'Search by account name...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      suffixIcon: controller.searchQuery.value.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.clear,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                              onPressed: () =>
                                  controller.searchQuery.value = '',
                            )
                          : null,
                    ),
                  ),
                ),
                Expanded(
                  child: controller.isLoading.value
                      ? const Center(child: CircularProgressIndicator())
                      : controller.filteredCans.isEmpty
                      ? Center(
                          child: Text(
                            'No cans tables found.',
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop
                                    ? 4
                                    : MediaQuery.of(context).size.width < 500
                                    ? 1
                                    : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: isDesktop ? 2 : 1.4,
                              ),
                          itemCount: controller.filteredCans.length,
                          itemBuilder: (context, index) {
                            final cans = controller.filteredCans[index];
                            return Card(
                              elevation: isDark ? 4 : 0,
                              child: InkWell(
                                onTap: () => NavigationHelper.push(
                                  context,
                                  CansTable(cans: cans),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    return SingleChildScrollView(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primaryContainer,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Icon(
                                                  Icons.inventory,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onPrimaryContainer,
                                                  size: 20,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Account: ${cans.accountName}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      'Created: ${DateFormat('dd-MM-yyyy').format(cans.insertedDate)}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Divider(
                                            height: 8,
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.outlineVariant,
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      'Opening: ${cans.openingBalanceCans.toStringAsFixed(2)}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Current: ${cans.currentCans.toStringAsFixed(2)}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                    const SizedBox(height: 3),
                                                    Text(
                                                      'Total: ${cans.totalCans.toStringAsFixed(2)}',
                                                      style: Theme.of(
                                                        context,
                                                      ).textTheme.bodySmall,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  deleteButton(
                                                    context: context,
                                                    onPressed: () {
                                                      confirmDeleteDialog(
                                                        onConfirm: () {
                                                          controller
                                                              .deleteCansTable(
                                                                cans.id!,
                                                              );
                                                        },
                                                        context: context,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton(
                heroTag: 'cans-fab',
                onPressed: () => showDialog(
                  context: context,
                  builder: (ctx) => const CreateCansTable(),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
