import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ledger_master/features/inventory/inventory_service.dart';
import 'package:ledger_master/models/stock_item.dart';
import 'package:ledger_master/models/stock_transaction.dart';
import 'package:ledger_master/providers/inventory_providers.dart';

class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stockItems = ref.watch(inventoryNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Inventory Management")),
      body: ListView.separated(
        padding: EdgeInsets.all(16.w),
        itemCount: stockItems.length,
        separatorBuilder: (_, __) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final item = stockItems[index];
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              contentPadding: EdgeInsets.all(16.w),
              title: Text(item.name),
              subtitle: Text("Rate: ₹${item.rate.toStringAsFixed(2)}"),
              trailing: Text(
                "Qty: ${item.quantity}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () => _openStockForm(context, ref, item),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openStockForm(context, ref, null),
        icon: const Icon(Icons.add),
        label: const Text("Add Stock"),
      ),
    );
  }

  void _openStockForm(BuildContext context, WidgetRef ref, StockItem? item) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: item?.name ?? '');
    final rateController = TextEditingController(
      text: item != null ? item.rate.toString() : '',
    );
    final qtyController = TextEditingController();
    StockType type = StockType.inwards;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(item == null ? "Add Stock Item" : "Update Stock"),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        content: SizedBox(
          width: 400.w,
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (item == null)
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Item Name",
                      border: OutlineInputBorder(),
                    ),
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                if (item == null) SizedBox(height: 12.h),
                if (item == null)
                  TextFormField(
                    controller: rateController,
                    decoration: const InputDecoration(
                      labelText: "Rate",
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (val) =>
                        val == null || val.isEmpty ? "Required" : null,
                  ),
                if (item == null) SizedBox(height: 12.h),
                TextFormField(
                  controller: qtyController,
                  decoration: const InputDecoration(
                    labelText: "Quantity",
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (val) =>
                      val == null || val.isEmpty ? "Required" : null,
                ),
                SizedBox(height: 12.h),
                if (item != null)
                  DropdownButtonFormField<StockType>(
                    initialValue: type,
                    items: const [
                      DropdownMenuItem(
                        value: StockType.inwards,
                        child: Text("IN"),
                      ),
                      DropdownMenuItem(
                        value: StockType.outwards,
                        child: Text("OUT"),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) type = val;
                    },
                    decoration: const InputDecoration(
                      labelText: "Type",
                      border: OutlineInputBorder(),
                    ),
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
                final quantity = int.parse(qtyController.text);
                if (item == null) {
                  // Add new stock item
                  final newItem = StockItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    rate: double.parse(rateController.text),
                    quantity: quantity,
                  );
                  ref.read(inventoryNotifierProvider.notifier).addItem(newItem);
                } else {
                  // Update stock
                  final updatedQty = type == StockType.inwards
                      ? item.quantity + quantity
                      : item.quantity - quantity;
                  ref
                      .read(inventoryNotifierProvider.notifier)
                      .updateQuantity(item.id, updatedQty);

                  // Create Ledger entry
                  createLedgerEntryFromStock(
                    ref,
                    StockTransaction(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      itemId: item.id,
                      type: type,
                      quantity: quantity,
                      date: DateTime.now(),
                    ),
                    item,
                  );
                }
                Navigator.pop(context);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text("Stock updated")));
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
