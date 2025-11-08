import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/main.dart';

void showLedgerEntryDialog(BuildContext context, LedgerEntry entry) {
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final isDark = Theme.of(context).brightness == Brightness.dark;

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Ledger Entry Details",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 8),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _entryRow(context, "Voucher No", entry.voucherNo),
                        _entryRow(context, "Account Name", entry.accountName),
                        _entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        _entryRow(
                          context,
                          "Debit",
                          entry.debit.toStringAsFixed(2),
                        ),
                        _entryRow(
                          context,
                          "Credit",
                          entry.credit.toStringAsFixed(2),
                        ),
                        _entryRow(
                          context,
                          "Balance",
                          entry.balance.toStringAsFixed(2),
                        ),
                        _entryRow(context, "Status", entry.status),
                        _entryRow(
                          context,
                          "Description",
                          entry.description ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Reference No",
                          entry.referenceNo ?? "-",
                        ),
                        _entryRow(context, "Category", entry.category ?? "-"),
                        _entryRow(
                          context,
                          "Tags",
                          entry.tags?.join(", ") ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Created By",
                          entry.createdBy ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Payment Method",
                          entry.paymentMethod ?? "-",
                        ),
                        _entryRow(context, "Bank Name", entry.bankName ?? "-"),
                        _entryRow(context, "Cheque No", entry.chequeNo ?? "-"),
                        _entryRow(
                          context,
                          "Cheque Amount",
                          entry.chequeAmount?.toStringAsFixed(2) ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Cheque Date",
                          entry.chequeDate != null
                              ? dateFormat.format(entry.chequeDate!)
                              : "-",
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withValues(alpha: 0.3)
                                : Theme.of(
                                    context,
                                  ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "Item Information",
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: isDark
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _entryRow(context, "Item Name", entry.itemName ?? "-"),
                        _entryRow(
                          context,
                          "Item Price/Unit",
                          entry.itemPricePerUnit?.toStringAsFixed(2) ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Can Weight",
                          entry.canWeight?.toStringAsFixed(2) ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Cans Quantity",
                          entry.cansQuantity?.toString() ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Selling Price/Can",
                          entry.sellingPricePerCan?.toStringAsFixed(2) ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Balance Cans",
                          entry.balanceCans ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Received Cans",
                          entry.receivedCans ?? "-",
                        ),
                        _entryRow(
                          context,
                          "Total Weight",
                          entry.totalWeight.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        _entryRow(
                          context,
                          "Created At",
                          dateFormat.format(entry.createdAt),
                        ),
                        _entryRow(
                          context,
                          "Updated At",
                          dateFormat.format(entry.updatedAt),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      "Close",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showItemLedgerEntryDialog(BuildContext context, ItemLedgerEntry entry) {
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 500, maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Item Ledger Entry Details",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                Divider(color: Theme.of(context).colorScheme.outlineVariant),
                const SizedBox(height: 8),

                // Scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _entryRow(context, "Voucher No", entry.voucherNo),
                        _entryRow(context, "Ledger No", entry.ledgerNo),
                        _entryRow(
                          context,
                          "Item ID",
                          entry.itemId?.toString() ?? "-",
                        ),
                        _entryRow(context, "Item Name", entry.itemName),
                        _entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        _entryRow(
                          context,
                          "Debit",
                          entry.debit.toStringAsFixed(2),
                        ),
                        _entryRow(
                          context,
                          "Credit",
                          entry.credit.toStringAsFixed(2),
                        ),
                        _entryRow(
                          context,
                          "Balance",
                          entry.balance.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 10),
                        _entryRow(
                          context,
                          "Created At",
                          dateFormat.format(entry.createdAt),
                        ),
                        _entryRow(
                          context,
                          "Updated At",
                          entry.updatedAt != null
                              ? dateFormat.format(entry.updatedAt!)
                              : "-",
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Footer
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.check_circle_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text(
                      "Close",
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _entryRow(BuildContext context, String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget actionButton({
  required BuildContext context,
  required IconData icon,
  required VoidCallback onPressed,
  required Color color,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: EdgeInsets.all(4),
      child: Icon(icon, size: 18, color: color),
    ),
  );
}

Widget editButton({
  required BuildContext context,
  required VoidCallback onPressed,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: EdgeInsets.all(4),
      child: Icon(
        Icons.edit_outlined,
        size: 18,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}

Widget deleteButton({
  required BuildContext context,
  required VoidCallback onPressed,
}) {
  return InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(20),
    child: Padding(
      padding: EdgeInsets.all(4),
      child: Icon(
        Icons.delete_outline,
        size: 18,
        color: Theme.of(context).colorScheme.error,
      ),
    ),
  );
}

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key, required this.showText});
  final bool showText;
  @override
  Widget build(BuildContext context) {
    final ThemeController controller = Get.find<ThemeController>();

    return Obx(() {
      final isDark = controller.isDarkMode.value;

      return InkWell(
        onTap: controller.toggleTheme,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? Colors.white24 : Colors.grey.shade400,
            ),
            color: isDark
                ? Colors.grey.shade800.withValues(alpha: 0.3)
                : Colors.grey.shade100,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => RotationTransition(
                  turns: child.key == const ValueKey('dark')
                      ? Tween<double>(begin: 1, end: 0.75).animate(anim)
                      : Tween<double>(begin: 0.75, end: 1).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                  key: ValueKey(isDark ? 'dark' : 'light'),
                  color: isDark ? Colors.amberAccent : const Color(0xFF0B57D0),
                  size: 22,
                ),
              ),
              if (showText) const SizedBox(width: 10),
              if (showText)
                Text(
                  isDark ? 'Dark Mode' : 'Light Mode',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
            ],
          ),
        ),
      );
    });
  }
}
