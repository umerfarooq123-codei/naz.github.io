import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:ledger_master/models/stock_item.dart';
import 'package:ledger_master/providers/inventory_providers.dart';

class AddNewItemForm extends ConsumerStatefulWidget {
  const AddNewItemForm({super.key});

  @override
  ConsumerState<AddNewItemForm> createState() => _AddNewItemFormState();
}

class _AddNewItemFormState extends ConsumerState<AddNewItemForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rateController = TextEditingController();
  final _quantityController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add New Item"),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      content: SizedBox(
        width: 400.w,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: "Item Name",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _rateController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Rate",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
              ),
              SizedBox(height: 12.h),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Initial Quantity",
                  border: OutlineInputBorder(),
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Required" : null,
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
              final item = StockItem(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                rate: double.parse(_rateController.text),
                quantity: int.parse(_quantityController.text),
              );
              ref.read(inventoryNotifierProvider.notifier).state = [
                ...ref.read(inventoryNotifierProvider),
                item,
              ];
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Item Added")));
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
