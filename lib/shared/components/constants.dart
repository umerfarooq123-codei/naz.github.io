import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/main.dart';

void showCustomerLedgerEntryDialog(
  BuildContext context,
  CustomerLedgerEntry entry,
) {
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
                      "Customer Ledger Entry Details",
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
                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Customer Name", entry.customerName),
                        entryRow(
                          context,
                          "Date",
                          dateFormat.format(entry.date),
                        ),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        entryRow(
                          context,
                          "Debit",
                          entry.debit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Credit",
                          entry.credit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Balance",
                          entry.balance.toStringAsFixed(2),
                        ),
                        entryRow(context, "Description", entry.description),
                        entryRow(
                          context,
                          "Payment Method",
                          entry.paymentMethod ?? "-",
                        ),
                        entryRow(context, "Bank Name", entry.bankName ?? "-"),
                        entryRow(context, "Cheque No", entry.chequeNo ?? "-"),
                        entryRow(
                          context,
                          "Cheque Amount",
                          entry.chequeAmount?.toStringAsFixed(2) ?? "-",
                        ),
                        entryRow(
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
                        entryRow(
                          context,
                          "Created At",
                          dateFormat.format(entry.createdAt),
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
                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Account Name", entry.accountName),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        entryRow(
                          context,
                          "Debit",
                          entry.debit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Credit",
                          entry.credit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Balance",
                          entry.balance.toStringAsFixed(2),
                        ),
                        entryRow(context, "Status", entry.status),
                        entryRow(
                          context,
                          "Description",
                          entry.description ?? "-",
                        ),
                        entryRow(
                          context,
                          "Reference No",
                          entry.referenceNo ?? "-",
                        ),
                        entryRow(context, "Category", entry.category ?? "-"),
                        entryRow(
                          context,
                          "Tags",
                          entry.tags?.join(", ") ?? "-",
                        ),
                        entryRow(context, "Created By", entry.createdBy ?? "-"),
                        entryRow(
                          context,
                          "Payment Method",
                          entry.paymentMethod ?? "-",
                        ),
                        entryRow(context, "Bank Name", entry.bankName ?? "-"),
                        entryRow(context, "Cheque No", entry.chequeNo ?? "-"),
                        entryRow(
                          context,
                          "Cheque Amount",
                          entry.chequeAmount?.toStringAsFixed(2) ?? "-",
                        ),
                        entryRow(
                          context,
                          "Cheque Date",
                          entry.paymentMethod?.toLowerCase() == 'cheque' &&
                                  entry.chequeDate != null
                              ? DateFormat(
                                  'dd-MM-yyyy',
                                ).format(entry.chequeDate!)
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
                        entryRow(context, "Item Name", entry.itemName ?? "-"),
                        entryRow(
                          context,
                          "Item Price/Unit",
                          entry.itemPricePerUnit?.toStringAsFixed(2) ?? "-",
                        ),
                        entryRow(
                          context,
                          "Can Weight",
                          entry.canWeight?.toStringAsFixed(2) ?? "-",
                        ),
                        entryRow(
                          context,
                          "Cans Quantity",
                          entry.cansQuantity?.toString() ?? "-",
                        ),
                        entryRow(
                          context,
                          "Selling Price/Can",
                          entry.sellingPricePerCan?.toStringAsFixed(2) ?? "-",
                        ),
                        entryRow(
                          context,
                          "Balance Cans",
                          entry.balanceCans ?? "-",
                        ),
                        entryRow(
                          context,
                          "Received Cans",
                          entry.receivedCans ?? "-",
                        ),
                        entryRow(
                          context,
                          "Total Weight",
                          entry.totalWeight.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        entryRow(
                          context,
                          "Created At",
                          dateFormat.format(entry.createdAt),
                        ),
                        entryRow(
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
                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Ledger No", entry.ledgerNo),
                        entryRow(
                          context,
                          "Item ID",
                          entry.itemId?.toString() ?? "-",
                        ),
                        entryRow(context, "Item Name", entry.itemName),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        entryRow(
                          context,
                          "Debit",
                          entry.debit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Credit",
                          entry.credit.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Balance",
                          entry.balance.toStringAsFixed(2),
                        ),
                        const SizedBox(height: 10),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 10),
                        entryRow(
                          context,
                          "Created At",
                          dateFormat.format(entry.createdAt),
                        ),
                        entryRow(
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

Widget entryRow(BuildContext context, String label, String value) {
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

Widget totalBox(String label, double value, BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: isDark
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.primaryContainer,
      border: Border.all(
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
        width: 1,
      ),
    ),
    child: Text(
      "$label: ${NumberFormat('#,##0', 'en_US').format(value)}",
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: isDark
            ? Theme.of(context).colorScheme.onSurface
            : Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    ),
  );
}

void confirmDeleteDialog({
  required VoidCallback onConfirm,
  required BuildContext context,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Text(
        'Confirm Delete',
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      content: Text(
        'Are you sure you want to delete?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'No',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: Text(
            'Yes',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onError,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}
