import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PurchasesScreen extends StatelessWidget {
  const PurchasesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final purchaseOrders = [
      {
        "id": "PO-2001",
        "vendor": "Tech Supplies Ltd",
        "amount": "₹ 50,000",
        "status": "Pending",
      },
      {
        "id": "PO-2002",
        "vendor": "OfficeMart",
        "amount": "₹ 15,500",
        "status": "Approved",
      },
    ];

    final expenses = [
      {
        "id": "EXP-001",
        "category": "Travel",
        "amount": "₹ 3,000",
        "date": "01/08/2025",
      },
      {
        "id": "EXP-002",
        "category": "Petty Cash",
        "amount": "₹ 1,200",
        "date": "02/08/2025",
      },
    ];

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Purchases & Expenses"),
          bottom: const TabBar(
            tabs: [
              Tab(text: "Purchase Orders"),
              Tab(text: "Expenses"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _PurchaseOrdersView(purchaseOrders: purchaseOrders),
            _ExpensesView(expenses: expenses),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabIndex = DefaultTabController.of(context).index;
            return FloatingActionButton.extended(
              onPressed: () => tabIndex == 0
                  ? _openPurchaseOrderForm(context)
                  : _openExpenseForm(context),
              icon: const Icon(Icons.add),
              label: Text(tabIndex == 0 ? "New PO" : "New Expense"),
            );
          },
        ),
      ),
    );
  }

  void _openPurchaseOrderForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _PurchaseOrderForm());
  }

  void _openExpenseForm(BuildContext context) {
    showDialog(context: context, builder: (_) => const _ExpenseForm());
  }
}

class _PurchaseOrdersView extends StatelessWidget {
  final List<Map<String, String>> purchaseOrders;

  const _PurchaseOrdersView({required this.purchaseOrders});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: purchaseOrders.length,
      itemBuilder: (context, index) {
        final po = purchaseOrders[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: CircleAvatar(child: Text(po["id"]!.split("-")[1])),
            title: Text(po["id"]!),
            subtitle: Text("Vendor: ${po["vendor"]}"),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  po["amount"]!,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  po["status"]!,
                  style: TextStyle(
                    color: po["status"] == "Approved"
                        ? Colors.green
                        : Colors.orange,
                  ),
                ),
              ],
            ),
            onTap: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text("Viewing ${po["id"]}")));
            },
          ),
        );
      },
    );
  }
}

class _ExpensesView extends StatelessWidget {
  final List<Map<String, String>> expenses;

  const _ExpensesView({required this.expenses});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: expenses.length,
      itemBuilder: (context, index) {
        final exp = expenses[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.h),
          child: ListTile(
            contentPadding: EdgeInsets.all(16.w),
            leading: const Icon(Icons.receipt_long),
            title: Text(exp["category"]!),
            subtitle: Text("Date: ${exp["date"]}"),
            trailing: Text(
              exp["amount"]!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PurchaseOrderForm extends StatelessWidget {
  const _PurchaseOrderForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final vendorController = TextEditingController();
    final amountController = TextEditingController();

    return AlertDialog(
      title: const Text("New Purchase Order"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: vendorController,
                decoration: const InputDecoration(
                  labelText: "Vendor",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Status",
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: "Pending", child: Text("Pending")),
                  DropdownMenuItem(value: "Approved", child: Text("Approved")),
                ],
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Purchase Order Created")),
              );
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}

class _ExpenseForm extends StatelessWidget {
  const _ExpenseForm();

  @override
  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    return AlertDialog(
      title: const Text("New Expense"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Category",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Amount",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: "Date",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.datetime,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            if (formKey.currentState!.validate()) {
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Expense Recorded")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
