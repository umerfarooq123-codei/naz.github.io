import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/customer.dart';
import 'package:ledger_master/core/models/item.dart';
import 'package:ledger_master/core/models/ledger.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';
import 'package:ledger_master/main.dart';

void showCustomerLedgerEntryDialog(
  BuildContext context,
  CustomerLedgerEntry entry,
) {
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
                        // Basic Information
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
                            "Basic Information",
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
                        entryRow(context, "Description", entry.description),

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),

                        // Financial Details
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
                            "Financial Details",
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

                        // Payment Details (only show if payment method exists)
                        if (entry.paymentMethod != null &&
                            entry.paymentMethod!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),

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
                              "Payment Details",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          entryRow(
                            context,
                            "Payment Method",
                            entry.paymentMethod!,
                          ),

                          // Cheque details (only show if payment method is cheque)
                          if (entry.paymentMethod?.toLowerCase() ==
                              'cheque') ...[
                            entryRow(
                              context,
                              "Bank Name",
                              entry.bankName ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque No",
                              entry.chequeNo ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Amount",
                              entry.chequeAmount?.toStringAsFixed(2) ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Date",
                              entry.chequeDate != null
                                  ? formatChequeDateForDisplay(
                                      entry.chequeDate!.toIso8601String(),
                                    )
                                  : "-",
                            ),
                          ],
                        ],

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),

                        // System Information
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
                            "System Information",
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
                        // Basic Information
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
                            "Basic Information",
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

                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Account Name", entry.accountName),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
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

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),

                        // Financial Details
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
                            "Financial Details",
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

                        // Payment Details (only show if payment method exists)
                        if (entry.paymentMethod != null &&
                            entry.paymentMethod!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),

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
                              "Payment Details",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          entryRow(
                            context,
                            "Payment Method",
                            entry.paymentMethod!,
                          ),

                          // Cheque details (only show if payment method is cheque)
                          if (entry.paymentMethod?.toLowerCase() ==
                              'cheque') ...[
                            entryRow(
                              context,
                              "Bank Name",
                              entry.bankName ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque No",
                              entry.chequeNo ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Amount",
                              entry.chequeAmount?.toStringAsFixed(2) ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Date",
                              entry.chequeDate != null
                                  ? formatChequeDateForDisplay(
                                      entry.chequeDate!.toIso8601String(),
                                    )
                                  : "-",
                            ),
                          ],
                        ],

                        // Item Information (if exists)
                        if (entry.itemName != null &&
                            entry.itemName!.isNotEmpty) ...[
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
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
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
                        ],

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),

                        // System Information
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
                            "System Information",
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
  final isDark = Theme.of(context).brightness == Brightness.dark;

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
                        // Basic Information
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
                            "Basic Information",
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

                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Ledger No", entry.ledgerNo),
                        entryRow(
                          context,
                          "Item ID",
                          entry.itemId?.toString() ?? "-",
                        ),
                        entryRow(context, "Item Name", entry.itemName),
                        entryRow(context, "Vendor Name", entry.vendorName),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),

                        // Financial Details
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
                            "Financial Details",
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

                        entryRow(
                          context,
                          "Price per Unit",
                          entry.pricePerKg.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "Can Weight",
                          entry.canWeight.toStringAsFixed(2),
                        ),
                        entryRow(
                          context,
                          "New Stock",
                          entry.newStock.toStringAsFixed(2),
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

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),

                        // System Information
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
                            "System Information",
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

void showVendorLedgerEntryDialog(
  BuildContext context,
  VendorLedgerEntry entry,
) {
  final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final dateOnlyFormat = DateFormat('dd-MM-yyyy');
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
                      "Vendor Ledger Entry Details",
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
                        // Basic Information
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
                            "Basic Information",
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

                        entryRow(context, "Voucher No", entry.voucherNo),
                        entryRow(context, "Vendor Name", entry.vendorName),
                        entryRow(
                          context,
                          "Date",
                          dateOnlyFormat.format(entry.date),
                        ),
                        entryRow(
                          context,
                          "Transaction Type",
                          entry.transactionType,
                        ),
                        entryRow(
                          context,
                          "Description",
                          entry.description ?? "-",
                        ),

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 8),

                        // Financial Details
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
                            "Financial Details",
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

                        entryRow(
                          context,
                          "Debit",
                          NumberFormat('#,##0.00').format(entry.debit),
                        ),
                        entryRow(
                          context,
                          "Credit",
                          NumberFormat('#,##0.00').format(entry.credit),
                        ),
                        entryRow(
                          context,
                          "Balance",
                          NumberFormat('#,##0.00').format(entry.balance),
                        ),

                        // Payment Details (if applicable)
                        if (entry.paymentMethod != null) ...[
                          const SizedBox(height: 12),
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                          const SizedBox(height: 8),

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
                              "Payment Details",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: isDark
                                        ? Theme.of(
                                            context,
                                          ).colorScheme.secondary
                                        : Theme.of(
                                            context,
                                          ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          entryRow(
                            context,
                            "Payment Method",
                            entry.paymentMethod!,
                          ),

                          if (entry.paymentMethod?.toLowerCase() ==
                              'cheque') ...[
                            entryRow(
                              context,
                              "Bank Name",
                              entry.bankName ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque No",
                              entry.chequeNo ?? "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Amount",
                              entry.chequeAmount != null
                                  ? NumberFormat(
                                      '#,##0.00',
                                    ).format(entry.chequeAmount!)
                                  : "-",
                            ),
                            entryRow(
                              context,
                              "Cheque Date",
                              entry.chequeDate != null &&
                                      entry.chequeDate!.toString().isNotEmpty
                                  ? formatChequeDate(
                                      entry.chequeDate!.toString(),
                                    )
                                  : "-",
                            ),
                          ],
                        ],

                        const SizedBox(height: 12),
                        Divider(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),

                        // System Information
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
                            "System Information",
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
                        entryRow(
                          context,
                          "Vendor ID",
                          entry.vendorId.toString(),
                        ),
                        if (entry.id != null)
                          entryRow(context, "Entry ID", entry.id!.toString()),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Footer with action buttons
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

String formatChequeDate(String dateString) {
  debugPrint("Input dateString: $dateString");
  if (dateString.isEmpty) return dateString;

  // First try DateTime.tryParse (it handles ISO format with time)
  final parsedDate = DateTime.tryParse(dateString);
  if (parsedDate != null) {
    debugPrint("Parsed via DateTime.tryParse: $parsedDate");
    return DateFormat('yyyy-MM-dd').format(parsedDate);
  }

  debugPrint("DateTime.tryParse failed, trying specific formats");

  // Try parsing with different date-only formats
  final formatsToTry = [
    'dd-MM-yyyy', // 31-01-2026
    'yyyy-MM-dd', // 2026-01-31 (without time)
    'yyyy-MM-dd', // 2026/01/31
    'dd-MM-yyyy', // 31/01/2026
    'MM-dd-yyyy', // 01-31-2026
    'yyyy-MM-dd HH:mm:ss', // 2026-01-31 00:00:00
    'yyyy-MM-dd HH:mm:ss.SSS', // 2026-01-31 00:00:00.000
  ];

  for (final format in formatsToTry) {
    try {
      final parsedDate = DateFormat(format).parse(dateString);
      debugPrint("Parsed via format '$format': $parsedDate");
      return DateFormat('yyyy-MM-dd').format(parsedDate);
    } catch (e) {
      debugPrint("Failed to parse with format '$format': $e");
      continue;
    }
  }

  debugPrint("All parsing attempts failed, returning original: $dateString");
  return dateString;
}

String formatChequeDateForDisplay(String? dateString) {
  if (dateString == null || dateString.isEmpty) return "-";

  try {
    final dateTime = DateTime.parse(dateString);
    return DateFormat('yyyy/MM/dd').format(dateTime);
  } catch (e) {
    try {
      final parsedDate = DateFormat('dd-MM-yyyy').parse(dateString);
      return DateFormat('yyyy/MM/dd').format(parsedDate);
    } catch (e2) {
      return dateString;
    }
  }
}
