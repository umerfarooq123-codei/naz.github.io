import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ledger_master/models/stock_item.dart';
import 'package:ledger_master/models/stock_transaction.dart';
import 'package:ledger_master/providers/inventory_providers.dart';

class AddStockForm extends ConsumerStatefulWidget {
  final StockItem item;
  const AddStockForm({super.key, required this.item});

  @override
  ConsumerState<AddStockForm> createState() => _AddStockFormState();
}

class _AddStockFormState extends ConsumerState<AddStockForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  StockType _type = StockType.inwards;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Update Stock - ${widget.item.name}"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Quantity",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              DropdownButtonFormField<StockType>(
                initialValue: _type,
                items: const [
                  DropdownMenuItem(
                    value: StockType.inwards,
                    child: Text("Stock IN"),
                  ),
                  DropdownMenuItem(
                    value: StockType.outwards,
                    child: Text("Stock OUT"),
                  ),
                ],
                onChanged: (val) => setState(() => _type = val!),
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
            if (_formKey.currentState!.validate()) {
              final qty = int.parse(_quantityController.text);
              final tx = StockTransaction(
                quantity: qty,
                type: _type,
                id: '',
                itemId: '',
                date: DateTime.now(),
              );
              ref
                  .read(inventoryNotifierProvider.notifier)
                  .addStockTransaction(tx, item: widget.item);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Stock Updated")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
