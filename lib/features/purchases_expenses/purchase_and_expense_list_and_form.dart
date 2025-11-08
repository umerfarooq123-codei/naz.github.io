import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/core/models/purchase.dart';
import 'package:ledger_master/features/purchases_expenses/purchase_expense_repository.dart';
import 'package:ledger_master/main.dart';

class ExpensePurchaseScreen extends StatelessWidget {
  const ExpensePurchaseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseLayout(
      showBackButton: false,
      appBarTitle: "Purchases and Expenses",
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // List Section
              Expanded(flex: 1, child: ExpensePurchaseList()),
              const SizedBox(width: 16),
              // Form Section
              Expanded(flex: 1, child: ExpensePurchaseForm()),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpensePurchaseList extends StatelessWidget {
  const ExpensePurchaseList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpensePurchaseGetxController>();
    final theme = Theme.of(context);

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Text(
                      'Expenses & Purchases',
                      style: theme.textTheme.headlineSmall!.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => Text(
                        'Total: ${controller.totalAmount.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium!.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Search and Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: _buildSearchAndFilters(controller, theme, context),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (controller.filteredExpensePurchases.isEmpty) {
                    return _buildEmptyState(theme);
                  }

                  return ListView.builder(
                    itemCount: controller.filteredExpensePurchases.length,
                    itemBuilder: (context, index) {
                      final expense =
                          controller.filteredExpensePurchases[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildExpenseTile(
                          expense,
                          controller,
                          theme,
                          context,
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters(
    ExpensePurchaseGetxController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    return Column(
      children: [
        // Search Field
        TextField(
          onChanged: (value) => controller.searchQuery.value = value,
          decoration: InputDecoration(
            hintText: 'Search expenses...',
            prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 12),

        // Filters Row
        Row(
          children: [
            // Category Filter
            Expanded(
              child: Obx(
                () => DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategory.value,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surface.withValues(alpha: 0.5),
                  ),
                  items: controller.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    controller.selectedCategory.value = value!;
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Date Range Filter - FIXED: Replaced with From/To date pickers
            Expanded(
              child: Row(
                children: [
                  // From Date
                  Expanded(
                    child: Obx(() {
                      final fromDate = controller.fromDate.value;
                      final hasFrom = fromDate != null;
                      return OutlinedButton(
                        onPressed: () => controller.selectFromDate(context),
                        style: OutlinedButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadiusGeometry.all(
                              Radius.circular(2),
                            ),
                          ),
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasFrom
                                  ? 'From: ${DateFormat('MMM dd').format(fromDate)}'
                                  : 'From',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (hasFrom)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => controller.clearFromDate(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(width: 8),
                  // To Date
                  Expanded(
                    child: Obx(() {
                      final toDate = controller.toDate.value;
                      final hasTo = toDate != null;
                      return OutlinedButton(
                        onPressed: () => controller.selectToDate(context),
                        style: OutlinedButton.styleFrom(
                          shape: BeveledRectangleBorder(
                            borderRadius: BorderRadiusGeometry.all(
                              Radius.circular(2),
                            ),
                          ),
                          backgroundColor: theme.colorScheme.surface.withValues(
                            alpha: 0.5,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasTo
                                  ? 'To: ${DateFormat('MMM dd').format(toDate)}'
                                  : 'To',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (hasTo)
                              IconButton(
                                icon: Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: theme.colorScheme.error,
                                ),
                                onPressed: () => controller.clearToDate(),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                          ],
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses found',
            style: theme.textTheme.titleMedium!.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense using the form on the right',
            style: theme.textTheme.bodyMedium!.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseTile(
    ExpensePurchase expense,
    ExpensePurchaseGetxController controller,
    ThemeData theme,
    BuildContext context,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        hoverColor: Colors.transparent,
        splashColor: Colors.transparent,
        // contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(Icons.receipt, color: theme.colorScheme.primary),
        ),
        title: Text(
          expense.description,
          style: theme.textTheme.bodyLarge!.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'By ${expense.madeBy} • ${expense.category}',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              DateFormat('dd MMM yyyy').format(expense.date),
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              expense.amount.toStringAsFixed(2),
              style: theme.textTheme.bodyLarge!.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              expense.paymentMethod,
              style: theme.textTheme.bodySmall!.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
        onTap: () => _showExpenseDetails(context, expense, controller),
      ),
    );
  }

  void _showExpenseDetails(
    BuildContext context,
    ExpensePurchase expense,
    ExpensePurchaseGetxController controller,
  ) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
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
                        "Expense Purchase Details",
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _entryRow("Description", expense.description),
                          _entryRow("Category", expense.category),
                          _entryRow("Date", dateFormat.format(expense.date)),
                          _entryRow(
                            "Amount",
                            expense.amount.toStringAsFixed(2),
                          ),
                          _entryRow("Made By", expense.madeBy),
                          _entryRow("Payment Method", expense.paymentMethod),
                          _entryRow(
                            "Reference No",
                            expense.referenceNumber ?? "-",
                          ),
                          const SizedBox(height: 12),
                          const Divider(color: Colors.white24),
                          const SizedBox(height: 12),
                          if (expense.notes?.isNotEmpty ?? false) ...[
                            Text(
                              "Notes",
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Colors.tealAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2A2A2A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Text(
                                expense.notes!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: Colors.white70),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Divider(color: Colors.white24),
                          ],
                          _entryRow(
                            "Created At",
                            dateFormat.format(expense.createdAt),
                          ),
                          _entryRow(
                            "Updated At",
                            dateFormat.format(expense.updatedAt),
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
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.tealAccent,
                      ),
                      label: const Text(
                        "Close",
                        style: TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 16,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.tealAccent,
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

  Widget _entryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

class ExpensePurchaseForm extends StatelessWidget {
  final ExpensePurchase? expensePurchase;
  final VoidCallback? onSaved;

  const ExpensePurchaseForm({super.key, this.expensePurchase, this.onSaved});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ExpensePurchaseGetxController>();
    final theme = Theme.of(context);
    final isEdit = expensePurchase != null;

    // Load data if editing
    if (isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        controller.loadExpenseForEdit(expensePurchase!);
      });
    }

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.1),
              theme.colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  isEdit ? 'Edit Expense' : 'Add New Expense',
                  style: theme.textTheme.headlineSmall!.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      child: Column(
                        children: [
                          // FIXED: Date Field as TextFormField for focus/tab support
                          TextFormField(
                            focusNode: controller.dateFocus,
                            readOnly: true,
                            controller: TextEditingController(
                              text: DateFormat(
                                'dd-MM-yyyy',
                              ).format(controller.selectedDate.value),
                            ),
                            decoration: InputDecoration(
                              labelText: 'Date',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.calendar_today,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            textInputAction: TextInputAction.next,
                            onTap: () => controller.selectDate(context),
                            onEditingComplete: () =>
                                controller.descriptionFocus.requestFocus(),
                          ),
                          const SizedBox(height: 16),

                          // Description Field
                          TextFormField(
                            focusNode: controller.descriptionFocus,
                            controller: controller.descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.description,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                controller.amountFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Amount Field
                          TextFormField(
                            focusNode: controller.amountFocus,
                            controller: controller.amountController,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.attach_money,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            keyboardType: TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d*'),
                              ),
                            ],
                            style: theme.textTheme.bodyMedium,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                controller.madeByFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter amount';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Please enter valid amount';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Made By Field
                          TextFormField(
                            focusNode: controller.madeByFocus,
                            controller: controller.madeByController,
                            decoration: InputDecoration(
                              labelText: 'Made By',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.person,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                controller.categoryFocus.requestFocus(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter who made this expense';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // FIXED: Category Dropdown with Obx and focus
                          Obx(
                            () => DropdownButtonFormField<String>(
                              focusNode: controller.categoryFocus,
                              initialValue: controller
                                  .categoryValue
                                  .value, // FIXED: Use 'value' for reactive updates (not initialValue)
                              decoration: InputDecoration(
                                labelText: 'Category',
                                labelStyle: theme.textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.category,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              items: controller.categories
                                  .where((category) => category != 'All')
                                  .map(
                                    (category) => DropdownMenuItem(
                                      value: category,
                                      child: Text(category),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.categoryValue.value = value;
                                }
                              },
                              // FIXED: Removed invalid parameters (textInputAction and onFieldSubmitted not supported in DropdownButtonFormField)
                              // Tab navigation for dropdowns uses default focus behavior; use FocusTraversalGroup if needed for custom order
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select category';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // FIXED: Payment Method Dropdown with Obx and focus
                          Obx(
                            () => DropdownButtonFormField<String>(
                              focusNode: controller.paymentMethodFocus,
                              initialValue: controller
                                  .paymentMethodValue
                                  .value, // FIXED: Use 'value' for reactive updates
                              decoration: InputDecoration(
                                labelText: 'Payment Method',
                                labelStyle: theme.textTheme.bodyMedium,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(
                                  Icons.payment,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              items: controller.paymentMethods
                                  .map(
                                    (method) => DropdownMenuItem(
                                      value: method,
                                      child: Text(method),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  controller.paymentMethodValue.value = value;
                                }
                              },
                              // FIXED: Removed invalid parameters (textInputAction and onFieldSubmitted not supported)
                              // Add validator if required
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select payment method';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Reference Number
                          TextFormField(
                            focusNode: controller.referenceNumberFocus,
                            controller: controller.referenceNumberController,
                            decoration: InputDecoration(
                              labelText: 'Reference Number (Optional)',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.confirmation_number,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            textInputAction: TextInputAction.next,
                            onEditingComplete: () =>
                                controller.notesFocus.requestFocus(),
                          ),
                          const SizedBox(height: 16),

                          // Notes
                          TextFormField(
                            focusNode: controller.notesFocus,
                            controller: controller.notesController,
                            decoration: InputDecoration(
                              labelText: 'Notes (Optional)',
                              labelStyle: theme.textTheme.bodyMedium,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.note,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            style: theme.textTheme.bodyMedium,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    controller.clearForm();
                                    if (onSaved != null) onSaved!();
                                  },
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  child: Text(
                                    'Clear',
                                    style: theme.textTheme.bodyLarge!.copyWith(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    final description =
                                        controller.descriptionController.text;
                                    final amount = double.tryParse(
                                      controller.amountController.text,
                                    );
                                    final madeBy =
                                        controller.madeByController.text;

                                    if (description.isEmpty ||
                                        amount == null ||
                                        madeBy.isEmpty) {
                                      Get.snackbar(
                                        'Error',
                                        'Please fill all required fields',
                                        backgroundColor: Colors.red,
                                        colorText: Colors.white,
                                        snackPosition: SnackPosition.BOTTOM,
                                      );
                                      return;
                                    }

                                    final expense = ExpensePurchase(
                                      id: isEdit ? expensePurchase!.id : null,
                                      date: controller.selectedDate.value,
                                      description: description,
                                      amount: amount,
                                      madeBy: madeBy,
                                      // FIXED: Use Rx values (guaranteed non-empty)
                                      category: controller.categoryValue.value,
                                      paymentMethod:
                                          controller.paymentMethodValue.value,
                                      referenceNumber: controller
                                          .referenceNumberController
                                          .text,
                                      notes: controller.notesController.text,
                                      createdAt: isEdit
                                          ? expensePurchase!.createdAt
                                          : DateTime.now(),
                                    );

                                    try {
                                      if (isEdit) {
                                        await controller.updateExpensePurchase(
                                          expense,
                                        );
                                      } else {
                                        await controller.addExpensePurchase(
                                          expense,
                                        );
                                      }
                                      controller.clearForm();
                                      if (onSaved != null) onSaved!();
                                    } catch (e) {
                                      // Error handling is done in controller
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    isEdit ? 'Update' : 'Save',
                                    style: theme.textTheme.bodyLarge!.copyWith(
                                      color: theme.colorScheme.onPrimary,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpensePurchaseGetxController extends GetxController {
  final ExpensePurchaseRepository _repository = ExpensePurchaseRepository();
  final expensePurchases = <ExpensePurchase>[].obs;
  final filteredExpensePurchases = <ExpensePurchase>[].obs;
  final isLoading = false.obs;
  final searchQuery = ''.obs;
  final selectedCategory = 'All'.obs;
  final dateRange = Rxn<DateTimeRange>();
  final fromDate = Rxn<DateTime>();
  final toDate = Rxn<DateTime>();

  // Form controllers
  final descriptionController = TextEditingController();
  final amountController = TextEditingController();
  final madeByController = TextEditingController();
  final referenceNumberController = TextEditingController();
  final notesController = TextEditingController();
  final selectedDate = DateTime.now().obs;

  // FIXED: Use RxString for category and paymentMethod instead of controllers
  final categoryValue = 'General'.obs;
  final paymentMethodValue = 'Cash'.obs;

  // FIXED: Add FocusNodes for tab navigation
  final FocusNode descriptionFocus = FocusNode();
  final FocusNode amountFocus = FocusNode();
  final FocusNode madeByFocus = FocusNode();
  final FocusNode categoryFocus = FocusNode();
  final FocusNode paymentMethodFocus = FocusNode();
  final FocusNode referenceNumberFocus = FocusNode();
  final FocusNode notesFocus = FocusNode();
  final FocusNode dateFocus = FocusNode();

  // Categories
  final List<String> categories = [
    'All',
    'General',
    'Office Supplies',
    'Utilities',
    'Rent',
    'Salaries',
    'Marketing',
    'Travel',
    'Maintenance',
    'Equipment',
    'Software',
    'Other',
  ];

  // Payment methods
  final List<String> paymentMethods = [
    'Cash',
    'Bank Transfer',
    'Cheque',
    'Credit Card',
    'Digital Payment',
  ];

  @override
  void onInit() {
    super.onInit();
    loadExpensePurchases();
    ever(searchQuery, (_) => filterExpensePurchases());
    ever(selectedCategory, (_) => filterExpensePurchases());
    // FIXED: Set defaults
    categoryValue.value = 'General';
    paymentMethodValue.value = 'Cash';
  }

  Future<void> loadExpensePurchases() async {
    try {
      isLoading.value = true;
      final data = await _repository.getAllExpensePurchases();
      expensePurchases.assignAll(data);
      filterExpensePurchases();
    } catch (e) {
      print(e.toString());
      Get.snackbar(
        'Error',
        'Failed to load expenses: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void filterExpensePurchases() {
    final query = searchQuery.value.toLowerCase().trim();
    final category = selectedCategory.value;

    var filtered = expensePurchases.where((expense) {
      final matchesCategory = category == 'All' || expense.category == category;
      final matchesSearch =
          query.isEmpty ||
          expense.description.toLowerCase().contains(query) ||
          expense.madeBy.toLowerCase().contains(query) ||
          expense.category.toLowerCase().contains(query) ||
          (expense.referenceNumber?.toLowerCase().contains(query) ?? false);

      // FIXED: Updated to use fromDate and toDate for filtering
      final matchesDateRange =
          fromDate.value == null ||
          toDate.value == null ||
          (expense.date.isAfter(fromDate.value!) &&
              expense.date.isBefore(
                toDate.value!.add(const Duration(days: 1)),
              )); // Inclusive end

      return matchesCategory && matchesSearch && matchesDateRange;
    }).toList();

    // Sort by date descending
    filtered.sort((a, b) => b.date.compareTo(a.date));
    filteredExpensePurchases.assignAll(filtered);
  }

  Future<void> addExpensePurchase(ExpensePurchase expensePurchase) async {
    try {
      await _repository.insertExpensePurchase(expensePurchase);
      await loadExpensePurchases();
      Get.snackbar(
        'Success',
        'Expense added successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to add expense: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> updateExpensePurchase(ExpensePurchase expensePurchase) async {
    try {
      await _repository.updateExpensePurchase(expensePurchase);
      await loadExpensePurchases();
      Get.snackbar(
        'Success',
        'Expense updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to update expense: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  Future<void> deleteExpensePurchase(int id) async {
    try {
      await _repository.deleteExpensePurchase(id);
      await loadExpensePurchases();
      Get.snackbar(
        'Success',
        'Expense deleted successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete expense: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
      rethrow;
    }
  }

  void loadExpenseForEdit(ExpensePurchase expense) {
    descriptionController.text = expense.description;
    amountController.text = expense.amount.toStringAsFixed(2);
    madeByController.text = expense.madeBy;
    // FIXED: Set Rx values
    categoryValue.value = expense.category;
    paymentMethodValue.value = expense.paymentMethod;
    referenceNumberController.text = expense.referenceNumber ?? '';
    notesController.text = expense.notes ?? '';
    selectedDate.value = expense.date;
  }

  void clearForm() {
    descriptionController.clear();
    amountController.clear();
    madeByController.clear();
    // FIXED: Reset to defaults
    categoryValue.value = 'General';
    paymentMethodValue.value = 'Cash';
    referenceNumberController.clear();
    notesController.clear();
    selectedDate.value = DateTime.now();
  }

  double get totalAmount {
    return filteredExpensePurchases.fold(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
  }

  Future<void> selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      selectedDate.value = picked;
    }
  }

  Future<void> selectFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: fromDate.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: toDate.value ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      fromDate.value = picked;
      filterExpensePurchases();
    }
  }

  Future<void> selectToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: toDate.value ?? DateTime.now(),
      firstDate: fromDate.value ?? DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      toDate.value = picked;
      filterExpensePurchases();
    }
  }

  void clearFromDate() {
    fromDate.value = null;
    filterExpensePurchases();
  }

  void clearToDate() {
    toDate.value = null;
    filterExpensePurchases();
  }

  void clearDateRange() {
    // FIXED: Updated to clear both
    fromDate.value = null;
    toDate.value = null;
    filterExpensePurchases();
  }

  @override
  void onClose() {
    descriptionController.dispose();
    amountController.dispose();
    madeByController.dispose();
    referenceNumberController.dispose();
    notesController.dispose();
    // FIXED: Dispose focus nodes
    descriptionFocus.dispose();
    amountFocus.dispose();
    madeByFocus.dispose();
    categoryFocus.dispose();
    paymentMethodFocus.dispose();
    referenceNumberFocus.dispose();
    notesFocus.dispose();
    dateFocus.dispose();
    super.onClose();
  }
}
