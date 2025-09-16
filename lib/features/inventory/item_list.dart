import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/models/item.dart';
import 'inventory_repository.dart';

class ItemController extends GetxController {
  final InventoryRepository repo;
  final items = <Item>[].obs;
  final filteredItems = <Item>[].obs;
  final isDarkMode = true.obs;
  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final typeController = TextEditingController();
  final pricePerKgController = TextEditingController();
  final costPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final canWeightController = TextEditingController();
  final availableStockController = TextEditingController();
  final searchController = TextEditingController();

  final selectedType = 'powder'.obs;
  final weightUnit = 'kg'.obs;
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;

  ItemController(this.repo);

  @override
  void onInit() {
    super.onInit();
    loadTheme();
    fetchItems();
    loadRecentSearches();

    // Listen to type changes to update weight unit
    ever(selectedType, (type) {
      weightUnit.value = type == 'liquid' ? 'L' : 'kg';
    });

    // Listen to pricePerKg and canWeight changes for selling price calculation
    pricePerKgController.addListener(_calculateSellingPrice);
    canWeightController.addListener(_calculateSellingPrice);

    // Listen to search query changes
    ever(searchQuery, (query) => filterItems(query));
  }

  void _calculateSellingPrice() {
    final pricePerKg = double.tryParse(pricePerKgController.text) ?? 0;
    final canWeight = double.tryParse(canWeightController.text) ?? 0;

    if (pricePerKg > 0 && canWeight > 0) {
      final totalPrice = pricePerKg * canWeight;
      sellingPriceController.text = totalPrice.toStringAsFixed(2);
    }
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
  }

  Future<void> fetchItems() async {
    final data = await repo.getAllItems();
    items.assignAll(data);
    filterItems(searchQuery.value);
  }

  void filterItems(String query) {
    if (query.isEmpty) {
      filteredItems.assignAll(items);
    } else {
      final q = query.toLowerCase();
      filteredItems.assignAll(
        items.where(
          (item) =>
              item.name.toLowerCase().contains(q) ||
              item.type.toLowerCase().contains(q) ||
              item.pricePerKg.toString().contains(q) ||
              item.costPrice.toString().contains(q) ||
              item.sellingPrice.toString().contains(q) ||
              item.canWeight.toString().contains(q) ||
              item.availableStock.toString().contains(q),
        ),
      );
    }
  }

  Future<void> deleteItem(int id) async {
    await repo.deleteItem(id);
    await fetchItems();
  }

  Future<void> loadItem({Item? item}) async {
    if (item == null) {
      clearForm();
    } else {
      nameController.text = item.name.toUpperCase();
      selectedType.value = item.type;
      pricePerKgController.text = item.pricePerKg.toString();
      costPriceController.text = item.costPrice.toString();
      sellingPriceController.text = item.sellingPrice.toString();
      canWeightController.text = item.canWeight.toString();
      availableStockController.text = item.availableStock.toString();
    }
  }

  Future<void> saveItem(BuildContext context, {Item? item}) async {
    if (formKey.currentState!.validate()) {
      final newItem = Item(
        id: item?.id,
        name: nameController.text.toUpperCase(),
        type: selectedType.value,
        pricePerKg: double.parse(pricePerKgController.text),
        costPrice: double.parse(costPriceController.text),
        sellingPrice: double.parse(sellingPriceController.text),
        canWeight: double.parse(canWeightController.text),
        availableStock: double.parse(availableStockController.text),
      );

      if (item == null) {
        await repo.insertItem(newItem);
      } else {
        await repo.updateItem(newItem);
      }
      clearForm();
      await fetchItems();
      if (context.mounted) {
        Navigator.pop(context);
      }
    }
  }

  void clearForm() {
    nameController.clear();
    selectedType.value = 'powder';
    pricePerKgController.clear();
    costPriceController.clear();
    sellingPriceController.clear();
    canWeightController.clear();
    availableStockController.clear();
  }

  Future<void> loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    recentSearches.assignAll(prefs.getStringList('itemRecentSearches') ?? []);
  }

  Future<void> saveRecentSearch(String searchTerm) async {
    if (searchTerm.trim().isEmpty) return;

    // Remove if already exists to avoid duplicates
    recentSearches.remove(searchTerm.trim());

    // Add to beginning of list
    recentSearches.insert(0, searchTerm.trim());

    // Keep only the last 5 searches
    if (recentSearches.length > 5) {
      recentSearches.removeLast();
    }

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('itemRecentSearches', recentSearches.toList());
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
  }

  @override
  void onClose() {
    nameController.dispose();
    pricePerKgController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    canWeightController.dispose();
    availableStockController.dispose();
    searchController.dispose();
    super.onClose();
  }
}

// Updated ItemList widget with complete search functionality
class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ItemController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    WidgetsBinding.instance.addPostFrameCallback((callBack) {
      controller.clearSearch();
      controller.fetchItems();
    });

    void showItemDetailsDialog(Item item) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Item Details - ${item.name}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Name: ${item.name}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Type: ${item.type}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Price Per ${item.type == 'liquid' ? 'L' : 'Kg'}: Rs${item.pricePerKg}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Can Weight: ${item.canWeight} ${item.type == 'liquid' ? 'L' : 'kg'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Cost Price/Can: Rs${item.costPrice}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Selling Price/Can: Rs${item.sellingPrice}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Available Stock: ${item.availableStock} ${item.type == 'liquid' ? 'L' : 'kg'}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Close',
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Obx(
      () => Stack(
        children: [
          BaseLayout(
            appBarTitle: 'Inventory Items',
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return controller.recentSearches;
                      }
                      return controller.recentSearches.where(
                        (search) => search.toLowerCase().contains(q),
                      );
                    },
                    onSelected: (String value) async {
                      controller.searchQuery.value = value;
                      await controller.saveRecentSearch(value);
                    },
                    fieldViewBuilder:
                        (
                          context,
                          textEditingController,
                          focusNode,
                          onFieldSubmitted,
                        ) {
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            style: Theme.of(context).textTheme.bodySmall!,
                            decoration: InputDecoration(
                              hintText: 'Search by name, type, price, stock...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              hintStyle: Theme.of(context).textTheme.bodySmall!,
                              labelStyle: Theme.of(
                                context,
                              ).textTheme.bodySmall!,
                              prefixIcon: Icon(
                                Icons.search,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              suffixIcon:
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: textEditingController,
                                    builder: (context, value, _) =>
                                        value.text.isNotEmpty
                                        ? IconButton(
                                            icon: Icon(
                                              Icons.clear,
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurface,
                                            ),
                                            onPressed: () {
                                              textEditingController.clear();
                                              controller.clearSearch();
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            ),
                            onChanged: (value) {
                              controller.searchQuery.value = value;
                            },
                            onSubmitted: (value) async {
                              onFieldSubmitted();
                              if (value.trim().isNotEmpty) {
                                await controller.saveRecentSearch(value.trim());
                              }
                            },
                          );
                        },
                  ),
                ),
                Expanded(
                  child: controller.filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              controller.searchQuery.value.isEmpty
                                  ? 'No items found. Add some items to get started.'
                                  : 'No items match your search.',
                              style: Theme.of(context).textTheme.bodyMedium!
                                  .copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.8),
                                  ),
                            ),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isDesktop ? 4 : 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 3.5 / 1.8,
                              ),
                          itemCount: controller.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = controller.filteredItems[index];
                            final unit = item.type == 'liquid' ? 'L' : 'kg';

                            return Card(
                              color: Colors.white30,
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  12,
                                ), // 👈 rounded corners here
                                side: const BorderSide(
                                  color: Colors.grey,
                                ), // optional border
                              ),
                              child: InkWell(
                                onTap: () => showItemDetailsDialog(item),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            color: Colors.white,
                                            size: 30,
                                          ), // darker for contrast
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.name,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Type: ${item.type}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Stock: ${item.availableStock} $unit',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Spacer(),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Price/${item.type == 'liquid' ? 'L' : 'Kg'}: Rs${item.pricePerKg}',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Can: ${item.canWeight} $unit',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                'Selling: Rs${item.sellingPrice}/can',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                ),
                                                onPressed: () async {
                                                  await controller.loadItem(
                                                    item: item,
                                                  );
                                                  if (context.mounted) {
                                                    NavigationHelper.push(
                                                      context,
                                                      ItemAddEdit(item: item),
                                                    );
                                                  }
                                                  await controller.fetchItems();
                                                },
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                ),
                                                onPressed: () => controller
                                                    .deleteItem(item.id!),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: FloatingActionButton(
              onPressed: () async {
                await controller.loadItem();
                if (context.mounted) {
                  NavigationHelper.push(context, const ItemAddEdit());
                }
                await controller.fetchItems();
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

// Item Add/Edit Screen
class ItemAddEdit extends StatelessWidget {
  final Item? item;
  const ItemAddEdit({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ItemController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    Widget buildTextField({
      required TextEditingController textController,
      required String label,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator,
      bool readOnly = false,
      List<TextInputFormatter>? inputFormatters,
      String? suffixText,
      FocusNode? focusNode,
      FocusNode? nextFocus,
    }) {
      return TextFormField(
        controller: textController,
        focusNode: focusNode,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          errorStyle: TextStyle(
            color: Colors.red[900],
            fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
          ),
          suffixText: suffixText,
        ),
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        ),
        keyboardType: keyboardType,
        validator: validator,
        readOnly: readOnly,
        inputFormatters: inputFormatters,
        textInputAction: nextFocus != null
            ? TextInputAction.next
            : TextInputAction.done,
        onEditingComplete: nextFocus != null
            ? () => nextFocus.requestFocus()
            : null,
        onChanged: (value) {
          if (keyboardType == TextInputType.text &&
              textController == controller.nameController) {
            textController.value = textController.value.copyWith(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          }
        },
      );
    }

    // Create focus nodes for tab navigation
    final nameFocus = FocusNode();
    final typeFocus = FocusNode();
    final pricePerKgFocus = FocusNode();
    final canWeightFocus = FocusNode();
    final costPriceFocus = FocusNode();
    final sellingPriceFocus = FocusNode();
    final stockFocus = FocusNode();

    return BaseLayout(
      appBarTitle: item == null ? 'Add Item' : 'Edit Item',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: controller.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Item Details',
                  style: Theme.of(context).textTheme.displayLarge!.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2),
                          (Theme.of(context).cardTheme.color ??
                              Theme.of(context).colorScheme.surface),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                    child: isDesktop
                        ? Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController: controller.nameController,
                                      label: 'Item Name',
                                      focusNode: nameFocus,
                                      nextFocus: typeFocus,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter item name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Obx(
                                      () => DropdownButtonFormField<String>(
                                        initialValue:
                                            controller.selectedType.value,
                                        focusNode: typeFocus,
                                        items: const [
                                          DropdownMenuItem(
                                            value: 'powder',
                                            child: Text('Powder (kg)'),
                                          ),
                                          DropdownMenuItem(
                                            value: 'liquid',
                                            child: Text('Liquid (L)'),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          controller.selectedType.value =
                                              value!;
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(pricePerKgFocus);
                                        },
                                        decoration: InputDecoration(
                                          labelText:
                                              'Item Type', // ✅ Same as other fields
                                          labelStyle: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.8),
                                              ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          errorStyle: TextStyle(
                                            color: Colors.red[900],
                                            fontSize: Theme.of(
                                              context,
                                            ).textTheme.bodySmall!.fontSize,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 16,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          controller.pricePerKgController,
                                      label: 'Price Per Kg/L (₨)',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: pricePerKgFocus,
                                      nextFocus: canWeightFocus,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter price per kg/L';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          controller.canWeightController,
                                      label: 'Can Weight',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: canWeightFocus,
                                      nextFocus: costPriceFocus,
                                      suffixText: controller.weightUnit.value,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter can weight';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          controller.costPriceController,
                                      label: 'Cost Price/Can (₨)',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: costPriceFocus,
                                      nextFocus: sellingPriceFocus,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter cost price per can';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          controller.sellingPriceController,
                                      label: 'Selling Price/Can (₨)',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: sellingPriceFocus,
                                      nextFocus: stockFocus,
                                      readOnly: true,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Selling price is required';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          controller.availableStockController,
                                      label: 'Available Stock',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: stockFocus,
                                      suffixText: controller.weightUnit.value,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter available stock';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Please enter a valid number';
                                        }
                                        return null;
                                      },
                                      inputFormatters: [
                                        FilteringTextInputFormatter.allow(
                                          RegExp(r'^\d*\.?\d*$'),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(child: SizedBox()),
                                ],
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              buildTextField(
                                textController: controller.nameController,
                                label: 'Item Name',
                                focusNode: nameFocus,
                                nextFocus: typeFocus,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter item name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              Obx(
                                () => DropdownButtonFormField<String>(
                                  initialValue: controller.selectedType.value,
                                  focusNode: typeFocus,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'powder',
                                      child: Text('Powder (kg)'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'liquid',
                                      child: Text('Liquid (L)'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    controller.selectedType.value = value!;
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(pricePerKgFocus);
                                  },
                                  decoration: InputDecoration(
                                    labelText:
                                        'Item Type', // ✅ Same as other fields
                                    labelStyle: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withValues(alpha: 0.8),
                                        ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    errorStyle: TextStyle(
                                      color: Colors.red[900],
                                      fontSize: Theme.of(
                                        context,
                                      ).textTheme.bodySmall!.fontSize,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 16),
                              buildTextField(
                                textController: controller.pricePerKgController,
                                label: 'Price Per Kg/L (₨)',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: pricePerKgFocus,
                                nextFocus: canWeightFocus,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter price per kg/L';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                textController: controller.canWeightController,
                                label: 'Can Weight',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: canWeightFocus,
                                nextFocus: costPriceFocus,
                                suffixText: controller.weightUnit.value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter can weight';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                textController: controller.costPriceController,
                                label: 'Cost Price/Can (₨)',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: costPriceFocus,
                                nextFocus: sellingPriceFocus,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter cost price per can';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                textController:
                                    controller.sellingPriceController,
                                label: 'Selling Price/Can (₨)',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: sellingPriceFocus,
                                nextFocus: stockFocus,
                                readOnly: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selling price is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              buildTextField(
                                textController:
                                    controller.availableStockController,
                                label: 'Available Stock',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: stockFocus,
                                suffixText: controller.weightUnit.value,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter available stock';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*$'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        controller.clearForm();
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Cancel',
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () => controller.saveItem(context, item: item),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).iconTheme.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'Save',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
