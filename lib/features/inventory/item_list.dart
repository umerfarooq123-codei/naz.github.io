import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/sales_invoicing/invoice_generator.dart';
import 'package:ledger_master/main.dart';
import 'package:ledger_master/shared/widgets/navigation_files.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../core/models/item.dart';
import 'inventory_repository.dart';

class ItemController extends GetxController {
  final Item? item;
  final InventoryRepository repo;
  final items = <Item>[].obs;
  final filteredItems = <Item>[].obs;
  final filteredItemLedgerEntry = <ItemLedgerEntry>[].obs;
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
  List<ItemLedgerEntry> itemLedgerEntries = <ItemLedgerEntry>[].obs;
  final DataGridController dataGridController = DataGridController();
  final selectedType = 'powder'.obs;
  final selectedCustOrVend = ''.obs;
  final weightUnit = 'kg'.obs;
  final searchQuery = ''.obs;
  final recentSearches = <String>[].obs;
  final selectedTransactionType = RxnString();

  ItemController(this.repo, this.item);
  final RxMap<String, double> columnWidths = <String, double>{}.obs;

  // optional helper to set a default width only if not already set
  void ensureColumnWidth(String columnName, double width) {
    if (!columnWidths.containsKey(columnName)) {
      columnWidths[columnName] = width;
    }
  }

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

  Future<void> saveItem(BuildContext context) async {
    final newItem = Item(
      name: nameController.text.toUpperCase(),
      type: selectedType.value,
      vendor: selectedCustOrVend.value.toUpperCase(),
    );

    if (item == null) {
      await repo.insertItem(newItem);
      // await repo.insertItemLedgerEntry("", itemLedgerEntry);
    } else {
      await repo.updateItem(newItem);
    }
    clearForm();
    await fetchItems();
    if (context.mounted) {
      Navigator.pop(context);
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

  Future<void> getItemLedgerEntries(String ledgerName) async {
    itemLedgerEntries = await repo.getItemLedgerEntries(ledgerName);
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

class ItemList extends StatelessWidget {
  const ItemList({super.key});

  @override
  Widget build(BuildContext context) {
    final itemController = Get.find<ItemController>();
    final custController = Get.find<CustomerController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;

    WidgetsBinding.instance.addPostFrameCallback((callBack) {
      itemController.clearSearch();
    });
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
          labelStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
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
        style: Theme.of(context).textTheme.bodySmall!.copyWith(
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
              textController == itemController.nameController) {
            textController.value = textController.value.copyWith(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          }
        },
      );
    }

    void addItemDialog(Item item) {
      bool isError = false;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(
                  'Add Item Details',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                content: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Obx(() {
                        final selectedValue =
                            itemController.selectedCustOrVend.value;
                        final customers = custController.filteredCustomers
                            .where(
                              (cust) =>
                                  cust.customerNo.toString().contains('VEN'),
                            )
                            .toList();
                        return DropdownButtonFormField<String>(
                          initialValue:
                              selectedValue.isNotEmpty &&
                                  customers.any(
                                    (customer) =>
                                        customer.name == selectedValue,
                                  )
                              ? selectedValue
                              : null,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Select Vendor',
                                style: Theme.of(context).textTheme.bodySmall!
                                    .copyWith(color: Colors.grey),
                              ),
                            ),
                            ...customers.map(
                              (customer) => DropdownMenuItem(
                                value: customer.name,
                                child: Text(
                                  customer.name.toUpperCase(),
                                  style: Theme.of(context).textTheme.bodySmall!
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            itemController.selectedCustOrVend.value =
                                value ?? '';
                          },
                          decoration: InputDecoration(
                            labelText: 'Vendor',
                            labelStyle: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
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
                        );
                      }),
                      SizedBox(height: 10),
                      buildTextField(
                        textController: itemController.nameController,
                        label: 'Item Name',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter item name';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 10),
                      Obx(
                        () => DropdownButtonFormField<String>(
                          initialValue: itemController.selectedType.value,
                          items: [
                            DropdownMenuItem(
                              value: 'powder',
                              child: Text(
                                'Powder (kg)',
                                style: Theme.of(context).textTheme.bodySmall!,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'liquid',
                              child: Text(
                                'Liquid (L)',
                                style: Theme.of(context).textTheme.bodySmall!,
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            itemController.selectedType.value = value!;
                          },
                          decoration: InputDecoration(
                            labelText: 'Item Type',
                            labelStyle: Theme.of(context).textTheme.bodySmall!
                                .copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
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
                      SizedBox(height: 10),
                      if (isError)
                        Text(
                          'Please fill all the fields.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall!.copyWith(color: Colors.red),
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      if (itemController.nameController.text.isNotEmpty &&
                          itemController.selectedType.value.isNotEmpty &&
                          itemController.selectedCustOrVend.value.isNotEmpty) {
                        itemController.saveItem(context);
                      } else {
                        setState(() => isError = true);
                      }
                    },
                    child: Text(
                      'Save',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    itemController.fetchItems();
    return Obx(
      () => Stack(
        children: [
          BaseLayout(
            showBackButton: false,
            appBarTitle: 'Inventory Items',
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      final q = textEditingValue.text.trim().toLowerCase();
                      if (q.isEmpty) {
                        return itemController.recentSearches;
                      }
                      return itemController.recentSearches.where(
                        (search) => search.toLowerCase().contains(q),
                      );
                    },
                    onSelected: (String value) async {
                      itemController.searchQuery.value = value;
                      await itemController.saveRecentSearch(value);
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
                                              itemController.clearSearch();
                                            },
                                          )
                                        : const SizedBox.shrink(),
                                  ),
                            ),
                            onChanged: (value) {
                              itemController.searchQuery.value = value;
                            },
                            onSubmitted: (value) async {
                              onFieldSubmitted();
                              if (value.trim().isNotEmpty) {
                                await itemController.saveRecentSearch(
                                  value.trim(),
                                );
                              }
                            },
                          );
                        },
                  ),
                ),
                Expanded(
                  child: itemController.filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text(
                              itemController.searchQuery.value.isEmpty
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
                          itemCount: itemController.filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = itemController.filteredItems[index];
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
                                onTap: () {
                                  NavigationHelper.push(
                                    context,
                                    LedgerTablePage(item: item),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.inventory,
                                            color: Colors.white,
                                            size: 30,
                                          ), // darker for contrast
                                          SizedBox(width: 10),
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
                                          Expanded(
                                            // 👈 forces left column to fit remaining width
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Can: ${item.canWeight} $unit',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  'Rs ${item.sellingPrice}/can',
                                                  style: Theme.of(
                                                    context,
                                                  ).textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                ),
                                                onPressed: () => itemController
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
                await itemController.loadItem();
                final item = Item(name: '', type: '', vendor: '');
                addItemDialog(item);
                // if (context.mounted) {
                //   NavigationHelper.push(context, const ItemAddEdit());
                // }
                // await itemController.fetchItems();
              },
              child: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemAddEdit extends StatelessWidget {
  final Item? item;
  const ItemAddEdit({super.key, this.item});

  @override
  Widget build(BuildContext context) {
    final itemController = Get.find<ItemController>();
    final custController = Get.find<CustomerController>();
    final isDesktop = MediaQuery.of(context).size.width > 800;
    final isEditing = item != null;

    // Initialize item data for editing
    if (isEditing) {
      itemController.loadItem(item: item!);
    }

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
              textController == itemController.nameController) {
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
    final custVendFocus = FocusNode();
    final canWeightFocus = FocusNode();
    final costPriceFocus = FocusNode();
    final sellingPriceFocus = FocusNode();
    final stockFocus = FocusNode();
    custController.fetchCustomers();

    return BaseLayout(
      showBackButton: true,
      appBarTitle: item == null ? 'Add Item' : 'Edit Item',
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: itemController.formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Obx(() {
                                      final selectedValue = itemController
                                          .selectedCustOrVend
                                          .value;
                                      final customers = custController
                                          .filteredCustomers
                                          .where(
                                            (cust) => cust.customerNo
                                                .toString()
                                                .contains('VEN'),
                                          )
                                          .toList();
                                      final isValidVendor =
                                          isEditing &&
                                          item!.vendor.isNotEmpty &&
                                          customers.any(
                                            (customer) =>
                                                customer.name == item!.vendor,
                                          );

                                      return isEditing && !isValidVendor
                                          ? buildTextField(
                                              textController:
                                                  TextEditingController(
                                                    text: item!.vendor,
                                                  ),
                                              label: 'Vendor',
                                              readOnly: true,
                                              focusNode: custVendFocus,
                                              nextFocus: nameFocus,
                                            )
                                          : DropdownButtonFormField<String>(
                                              initialValue:
                                                  selectedValue.isNotEmpty &&
                                                      customers.any(
                                                        (customer) =>
                                                            customer.name ==
                                                            selectedValue,
                                                      )
                                                  ? selectedValue
                                                  : null,
                                              focusNode: custVendFocus,
                                              items: [
                                                DropdownMenuItem(
                                                  value: null,
                                                  child: Text(
                                                    'Select Vendor',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .bodySmall!
                                                        .copyWith(
                                                          color: Colors.grey,
                                                        ),
                                                  ),
                                                ),
                                                ...customers.map(
                                                  (
                                                    customer,
                                                  ) => DropdownMenuItem(
                                                    value: customer.name,
                                                    child: Text(
                                                      customer.name
                                                          .toUpperCase(),
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodySmall!
                                                          .copyWith(
                                                            color: Colors.white,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                              onChanged: (value) {
                                                itemController
                                                        .selectedCustOrVend
                                                        .value =
                                                    value ?? '';
                                                FocusScope.of(
                                                  context,
                                                ).requestFocus(nameFocus);
                                              },
                                              decoration: InputDecoration(
                                                labelText: 'Vendor',
                                                labelStyle: Theme.of(context)
                                                    .textTheme
                                                    .bodyMedium!
                                                    .copyWith(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onSurface
                                                          .withValues(
                                                            alpha: 0.8,
                                                          ),
                                                    ),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                errorStyle: TextStyle(
                                                  color: Colors.red[900],
                                                  fontSize: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall!
                                                      .fontSize,
                                                ),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 16,
                                                    ),
                                              ),
                                            );
                                    }),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          itemController.nameController,
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Obx(
                                      () => DropdownButtonFormField<String>(
                                        initialValue:
                                            itemController.selectedType.value,
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
                                          itemController.selectedType.value =
                                              value!;
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(pricePerKgFocus);
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Item Type',
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          itemController.pricePerKgController,
                                      label: 'Price Per Kg/L',
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          itemController.canWeightController,
                                      label: 'Can Weight',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: canWeightFocus,
                                      nextFocus: costPriceFocus,
                                      suffixText:
                                          itemController.weightUnit.value,
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          itemController.costPriceController,
                                      label: 'Cost Price/Can',
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
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: buildTextField(
                                      textController:
                                          itemController.sellingPriceController,
                                      label: 'Selling Price/Can',
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
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: buildTextField(
                                      textController: itemController
                                          .availableStockController,
                                      label: 'Stock',
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      focusNode: stockFocus,
                                      suffixText:
                                          itemController.weightUnit.value,
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
                                ],
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Obx(() {
                                final selectedValue =
                                    itemController.selectedCustOrVend.value;
                                final customers =
                                    custController.filteredCustomers;
                                final isValidVendor =
                                    isEditing &&
                                    item!.vendor.isNotEmpty &&
                                    customers.any(
                                      (customer) =>
                                          customer.name == item!.vendor,
                                    );

                                return isEditing && !isValidVendor
                                    ? buildTextField(
                                        textController: TextEditingController(
                                          text: item!.vendor,
                                        ),
                                        label: 'Vendor',
                                        readOnly: true,
                                        focusNode: custVendFocus,
                                        nextFocus: nameFocus,
                                      )
                                    : DropdownButtonFormField<String>(
                                        initialValue:
                                            selectedValue.isNotEmpty &&
                                                customers.any(
                                                  (customer) =>
                                                      customer.name ==
                                                      selectedValue,
                                                )
                                            ? selectedValue
                                            : null,
                                        focusNode: custVendFocus,
                                        items: [
                                          DropdownMenuItem(
                                            value: null,
                                            child: Text(
                                              'Select Vendor',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall!
                                                  .copyWith(color: Colors.grey),
                                            ),
                                          ),
                                          ...customers.map(
                                            (customer) => DropdownMenuItem(
                                              value: customer.name,
                                              child: Text(
                                                customer.name.toUpperCase(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .bodySmall!
                                                    .copyWith(
                                                      color: Colors.white,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                        onChanged: (value) {
                                          itemController
                                                  .selectedCustOrVend
                                                  .value =
                                              value!;
                                          FocusScope.of(
                                            context,
                                          ).requestFocus(nameFocus);
                                        },
                                        decoration: InputDecoration(
                                          labelText: 'Vendor',
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
                                      );
                              }),
                              const SizedBox(height: 16),
                              buildTextField(
                                textController: itemController.nameController,
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
                                  initialValue:
                                      itemController.selectedType.value,
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
                                    itemController.selectedType.value = value!;
                                    FocusScope.of(
                                      context,
                                    ).requestFocus(pricePerKgFocus);
                                  },
                                  decoration: InputDecoration(
                                    labelText: 'Item Type',
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
                                textController:
                                    itemController.pricePerKgController,
                                label: 'Price Per Kg/L',
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
                                textController:
                                    itemController.canWeightController,
                                label: 'Can Weight',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: canWeightFocus,
                                nextFocus: costPriceFocus,
                                suffixText: itemController.weightUnit.value,
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
                                textController:
                                    itemController.costPriceController,
                                label: 'Cost Price/Can',
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
                                    itemController.sellingPriceController,
                                label: 'Selling Price/Can',
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
                                    itemController.availableStockController,
                                label: 'Stock',
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                focusNode: stockFocus,
                                suffixText: itemController.weightUnit.value,
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
                        itemController.clearForm();
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
                      onPressed: () => itemController.saveItem(context),
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

class LedgerTablePage extends StatelessWidget {
  final Item item;

  const LedgerTablePage({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ItemLedgerTableController(item));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntries("${item.name}_${item.id}");
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Ledger Entries of: ${item.name}"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Obx(() {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: controller.searchController,
                        onChanged: (value) =>
                            controller.searchQuery.value = value,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Search by Voucher No or Date",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          hintStyle: Theme.of(context).textTheme.bodySmall,
                          labelStyle: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: item.name,
                      readOnly: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "Ledger Name",
                        border: OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: DropdownButtonFormField<String>(
                      initialValue: controller.selectedTransactionType.value,
                      style: Theme.of(context).textTheme.bodySmall,
                      items: const [
                        DropdownMenuItem(value: null, child: Text("All Types")),
                        DropdownMenuItem(value: "Debit", child: Text("Debit")),
                        DropdownMenuItem(
                          value: "Credit",
                          child: Text("Credit"),
                        ),
                      ],
                      onChanged: (value) {
                        controller.selectedTransactionType.value = value;
                      },
                      decoration: InputDecoration(
                        labelText: "Transaction Type",
                        border: OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: controller.fromDateController,
                      readOnly: true,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: "From Date",
                        border: const OutlineInputBorder(),
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () => controller.selectDate(context, true),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: controller.toDateController,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.white),
                      readOnly: true,
                      decoration: InputDecoration(
                        hintStyle: Theme.of(context).textTheme.bodySmall,
                        labelStyle: Theme.of(context).textTheme.bodySmall,
                        labelText: "To Date",
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () =>
                              controller.selectDate(context, false),
                        ),
                      ),
                      onTap: () => controller.selectDate(context, false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton(
                    heroTag: 'ledger-fab',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ItemLedgerEntryAddEdit(
                            ledgerNo: "${item.name}_${item.id}",
                            onEntrySaved: () => controller.loadLedgerEntries(
                              "${item.name}_${item.id}",
                            ),
                            item: item,
                          ),
                        ),
                      );
                    },
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            controller.isLoading.value
                ? Expanded(
                    child: const Center(child: CircularProgressIndicator()),
                  )
                : Expanded(
                    child: SfDataGrid(
                      source: LedgerEntryDataSource(
                        controller.filteredLedgerEntries,
                        item,
                        context,
                      ),
                      controller: controller.dataGridController,
                      columnWidthMode: ColumnWidthMode.fill,
                      gridLinesVisibility: GridLinesVisibility.both,
                      headerGridLinesVisibility: GridLinesVisibility.both,
                      placeholder: Center(
                        child: Text(
                          "No data available",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      columns: [
                        GridColumn(
                          columnName: 'voucherNo',
                          label: headerText("Voucher No", context),
                        ),
                        GridColumn(
                          columnName: 'date',
                          label: headerText("Date", context),
                        ),
                        GridColumn(
                          columnName: 'item',
                          label: headerText("Item", context),
                        ),
                        GridColumn(
                          columnName: 'priceperkg',
                          label: headerText("Price", context),
                        ),
                        GridColumn(
                          columnName: 'canweight',
                          label: headerText("Can weight", context),
                        ),
                        GridColumn(
                          columnName: 'transactionType',
                          label: headerText("Type", context),
                        ),
                        GridColumn(
                          columnName: 'debit',
                          label: headerText("Debit", context),
                        ),
                        GridColumn(
                          columnName: 'credit',
                          label: headerText("Credit", context),
                        ),
                        GridColumn(
                          columnName: 'balance',
                          label: headerText("Balance", context),
                        ),
                      ],
                    ),
                  ),
            Container(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  totalBox("Total Debit", controller.totalDebit, context),
                  const SizedBox(width: 16),
                  totalBox("Net Balance", controller.netBalance, context),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget totalBox(String label, double value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Text(
        "$label: ${NumberFormat('#,##0.00', 'en_US').format(value)}",
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget headerText(String text, context) => Container(
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Text(text, style: Theme.of(context).textTheme.bodySmall),
    ),
  );
}

class LedgerEntryDataSource extends DataGridSource {
  List<DataGridRow> _rows = [];
  final BuildContext context;
  final Item item;
  LedgerEntryDataSource(
    List<ItemLedgerEntry> entries,
    this.item,
    this.context,
  ) {
    _rows = entries.map((entry) {
      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'voucherNo', value: entry.voucherNo),
          DataGridCell(
            columnName: 'date',
            value: DateFormat('dd-MM-yyyy').format(entry.createdAt),
          ),
          DataGridCell(columnName: 'item', value: item.name),
          DataGridCell(
            columnName: 'priceperkg',
            value: '${item.pricePerKg}/(Kg/L)',
          ),
          DataGridCell(
            columnName: 'canweight',
            value: '${item.canWeight}(Kg/L)',
          ),
          DataGridCell(
            columnName: 'transactionType',
            value: entry.transactionType,
          ),
          DataGridCell(columnName: 'debit', value: entry.debit),
          DataGridCell(columnName: 'credit', value: entry.credit),
          DataGridCell(columnName: 'balance', value: entry),
        ],
      );
    }).toList();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final entry = (row.getCells().last.value as ItemLedgerEntry);
    bool isHovered = false;
    return DataGridRowAdapter(
      cells: row.getCells().asMap().entries.map((cellEntry) {
        final cell = cellEntry.value;
        final isLastCell = cellEntry.key == row.getCells().length - 1;
        final rowIndex = rows.indexOf(row);
        if (isLastCell) {
          return StatefulBuilder(
            builder: (context, setState) {
              return MouseRegion(
                onEnter: (_) => setState(() => isHovered = true),
                onExit: (_) => setState(() => isHovered = false),
                child: Stack(
                  alignment: Alignment.centerRight,
                  children: [
                    Container(
                      alignment: Alignment.center,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text(
                          NumberFormat(
                            '#,##0.00',
                            'en_US',
                          ).format(cell.value.balance ?? 0),
                          style: Theme.of(context).textTheme.bodySmall!
                              .copyWith(fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    if (isHovered)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Tooltip(
                            message: "print",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => printEntry(entry, rowIndex),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.print, size: 16),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: "delete",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => deleteEntry(entry, context),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.delete, size: 16),
                              ),
                            ),
                          ),
                          Tooltip(
                            message: "edit",
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => editEntry(entry, context),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: const Icon(Icons.edit, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          );
        }
        return Container(
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              cell.columnName == 'debit' || cell.columnName == 'credit'
                  ? NumberFormat('#,##0.00', 'en_US').format(cell.value ?? 0)
                  : cell.value.toString(),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall!.copyWith(
                fontWeight:
                    cell.columnName == 'debit' || cell.columnName == 'credit'
                    ? FontWeight.w500
                    : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> printEntry(ItemLedgerEntry entry, int index) async {
    final controller = Get.find<ItemLedgerTableController>();
    final customerController = Get.find<CustomerController>();

    // Compute can quantities from debit/credit
    double currentCans = 0.0;
    double receivedCans = 0.0;
    final amount = entry.transactionType == 'Debit'
        ? entry.debit
        : entry.credit;
    if (item.pricePerKg > 0 && item.canWeight > 0) {
      final weight = amount / item.pricePerKg; // Calculate weight from amount
      final cans = weight / item.canWeight; // Calculate cans from weight
      if (entry.transactionType == 'Debit') {
        currentCans = cans; // Debit = cans issued
      } else {
        receivedCans = cans; // Credit = cans received
      }
    }

    // Compute running previous balance of cans
    final list = controller.filteredLedgerEntries;
    double runningPrevBalance = 0.0;
    for (int i = 0; i < index && i < list.length; i++) {
      final prevEntry = list[i];
      final prevAmount = prevEntry.transactionType == 'Debit'
          ? prevEntry.debit
          : prevEntry.credit;
      final prevWeight = prevAmount / item.pricePerKg;
      final prevCans = prevWeight / item.canWeight;
      runningPrevBalance += (prevEntry.transactionType == 'Debit'
          ? prevCans
          : -prevCans);
    }

    // Calculate totals
    final totalCans = runningPrevBalance + currentCans;
    final balanceCans = totalCans - receivedCans;

    // Create ReceiptItem
    final items = [
      ReceiptItem(
        name: item.name,
        price: item.pricePerKg,
        canQuantity: currentCans.round(), // Use integer for can quantity
        type: entry.transactionType,
        description: '${entry.transactionType} transaction for ${item.name}',
        amount: amount,
      ),
    ];

    // Fetch customer details (if applicable)
    // Note: Since ItemLedgerEntry doesn't link to a customer, use placeholders
    // If you have a way to link itemId to a customer, use customerController here
    final customer = await customerController.repo.getCustomer(
      '',
    ); // Placeholder
    final customerName = customer?.name ?? 'N/A';
    final customerAddress = customer?.address ?? 'N/A';

    // Create ReceiptData
    final data = ReceiptData(
      companyName: 'NAZ ENTERPRISES',
      date: DateFormat('dd/MM/yyyy').format(entry.createdAt),
      customerName: customerName,
      customerAddress: customerAddress,
      vehicleNumber: 'N/A', // Replace with entry.vehicleNo if available
      voucherNumber: entry.voucherNo,
      items: items,
      previousCans: runningPrevBalance,
      currentCans: currentCans,
      totalCans: totalCans,
      receivedCans: receivedCans,
      balanceCans: balanceCans,
      currentAmount: amount,
      previousAmount: index > 0 ? list[index - 1].balance : 0.0,
      netBalance: entry.balance,
    );

    // Generate and print PDF
    await ReceiptPdfGenerator.generateAndPrint(data);
  }

  void deleteEntry(ItemLedgerEntry entry, BuildContext context) async {
    final controller = Get.find<ItemLedgerTableController>();
    try {
      await controller.repo.deleteItemLedgerEntry(
        "${item.name}_${item.id}",
        entry.id!,
      );
      String reverseType = entry.transactionType == "Debit"
          ? "Credit"
          : "Debit";
      double qty = entry.transactionType == "Debit"
          ? entry.debit
          : entry.credit;
      await controller.repo.updateItemStock(
        itemId: entry.itemId!,
        transactionType: reverseType,
        quantity: qty,
      );
      await controller.loadLedgerEntries("${item.name}_${item.id}");
      Get.snackbar(
        'Success',
        'Entry deleted successfully',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to delete entry: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void editEntry(ItemLedgerEntry entry, BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ItemLedgerEntryAddEdit(
          ledgerNo: "${item.name}_${item.id}",
          entry: entry,
          item: item,
          onEntrySaved: () => Get.find<ItemLedgerTableController>()
              .loadLedgerEntries("${item.name}_${item.id}"),
        ),
      ),
    );
  }

  double safeParseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    final str = value.toString().trim();
    if (str.isEmpty) return 0.0;
    return double.tryParse(str) ?? 0.0;
  }
}

class ItemLedgerTableController extends GetxController {
  final Item item;
  final DataGridController dataGridController = DataGridController();
  final fromDateController = TextEditingController();
  final toDateController = TextEditingController();
  final searchController = TextEditingController();
  final selectedRows = <int>{}.obs;
  final selectAll = false.obs;
  final selectedTransactionType = RxnString();
  final isLoading = false.obs;
  final calculationAnalysis = ''.obs;
  final showCalculationAnalysis = false.obs;
  final searchQuery = ''.obs;
  final fromDate = Rx<DateTime>(DateTime.now().subtract(Duration(days: 30)));
  final toDate = Rx<DateTime>(DateTime.now());
  final filteredLedgerEntries = <ItemLedgerEntry>[].obs;
  final RxMap<String, double> columnWidths = <String, double>{}.obs;
  final repo = InventoryRepository();

  ItemLedgerTableController(this.item);

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(Duration(days: 30));
    fromDate.value = DateTime(
      thirtyDaysAgo.year,
      thirtyDaysAgo.month,
      thirtyDaysAgo.day,
    );
    toDate.value = DateTime(now.year, now.month, now.day);
    fromDateController.text = DateFormat('dd-MM-yyyy').format(fromDate.value);
    toDateController.text = DateFormat('dd-MM-yyyy').format(toDate.value);
    everAll([
      searchQuery,
      fromDate,
      toDate,
      selectedTransactionType,
    ], (_) => applyFilters());
    applyFilters();
  }

  Future<void> applyFilters({String? ledgerNo}) async {
    isLoading.value = true;
    try {
      final ledgerId = ledgerNo ?? "${item.name}_${item.id}";
      final itemLedgerEntries = await repo.getItemLedgerEntries(ledgerId);
      final fromDateValue = DateTime(
        fromDate.value.year,
        fromDate.value.month,
        fromDate.value.day,
      );
      final toDateValue = DateTime(
        toDate.value.year,
        toDate.value.month,
        toDate.value.day,
        23,
        59,
        59,
        999,
      );

      final filtered = itemLedgerEntries.where((entry) {
        final entryDate = entry.createdAt;
        final normalizedEntryDate = DateTime(
          entryDate.year,
          entryDate.month,
          entryDate.day,
        );
        bool dateMatch =
            !normalizedEntryDate.isBefore(fromDateValue) &&
            !normalizedEntryDate.isAfter(toDateValue);
        bool typeMatch =
            selectedTransactionType.value == null ||
            entry.transactionType == selectedTransactionType.value;
        bool searchMatch =
            searchQuery.value.isEmpty ||
            entry.voucherNo.toLowerCase().contains(
              searchQuery.value.toLowerCase(),
            ) ||
            DateFormat(
              'dd-MM-yyyy',
            ).format(entryDate).contains(searchQuery.value);
        return dateMatch && typeMatch && searchMatch;
      }).toList();

      filtered.sort((a, b) {
        int dateComparison = a.createdAt.compareTo(b.createdAt);
        if (dateComparison != 0) return dateComparison;
        return (a.id ?? 0).compareTo(b.id ?? 0);
      });

      double runningBalance = 0;
      for (var entry in filtered) {
        runningBalance += entry.transactionType == "Credit"
            ? entry.credit
            : -entry.debit;
        entry.balance = runningBalance;
      }

      filteredLedgerEntries.assignAll(filtered);

      if (filteredLedgerEntries.isNotEmpty) {
        final lastIndex = filteredLedgerEntries.length - 1;
        Future.delayed(Duration(milliseconds: 500), () {
          dataGridController.scrollToRow(lastIndex.toDouble());
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error applying filters: $e");
      }
      filteredLedgerEntries.clear();
      Get.snackbar(
        'Error',
        'Failed to load entries: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> selectDate(BuildContext context, bool isFromDate) async {
    final currentDate = isFromDate ? fromDate.value : toDate.value;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final normalizedDate = DateTime(picked.year, picked.month, picked.day);
      if (isFromDate) {
        fromDate.value = normalizedDate;
        fromDateController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(normalizedDate);
      } else {
        toDate.value = normalizedDate;
        toDateController.text = DateFormat('dd-MM-yyyy').format(normalizedDate);
      }
    }
  }

  Future<void> loadLedgerEntries(String ledgerNo) async {
    await applyFilters(ledgerNo: ledgerNo);
  }

  double get totalDebit {
    return filteredLedgerEntries.fold(0, (sum, entry) => sum + entry.debit);
  }

  double get totalCredit {
    return filteredLedgerEntries.fold(0, (sum, entry) => sum + entry.credit);
  }

  double get netBalance {
    if (filteredLedgerEntries.isEmpty) return 0;
    return filteredLedgerEntries.last.balance;
  }

  void handleRowSelection(int id, bool? selected) {
    if (selected == true) {
      selectedRows.add(id);
    } else {
      selectedRows.remove(id);
    }
    selectAll.value = selectedRows.length == filteredLedgerEntries.length;
  }

  void handleSelectAll(bool? selected) {
    selectAll.value = selected ?? false;
    if (selectAll.value) {
      selectedRows.assignAll(filteredLedgerEntries.map((e) => e.id!));
    } else {
      selectedRows.clear();
    }
  }

  void analyzeCalculations() {
    final entries = filteredLedgerEntries;
    String analysis = "Calculation Analysis:\n\n";
    analysis += "All Entries:\n";
    for (var entry in entries) {
      analysis +=
          "Voucher: ${entry.voucherNo} | Debit: ${NumberFormat('#,##0.00', 'en_US').format(entry.debit)} | Credit: ${NumberFormat('#,##0.00', 'en_US').format(entry.credit)} | Balance: ${NumberFormat('#,##0.00', 'en_US').format(entry.balance)}\n";
    }
    analysis += "\nTotals:\n";
    analysis +=
        "Total Debit: ${NumberFormat('#,##0.00', 'en_US').format(totalDebit)}\n";
    analysis +=
        "Total Credit: ${NumberFormat('#,##0.00', 'en_US').format(totalCredit)}\n";
    analysis +=
        "Net Balance: ${NumberFormat('#,##0.00', 'en_US').format(netBalance)}\n\n";
    double calculatedNetBalance = entries.fold(
      0,
      (sum, entry) =>
          sum +
          (entry.transactionType == "Credit" ? entry.credit : -entry.debit),
    );
    analysis +=
        "Calculated Net Balance: ${NumberFormat('#,##0.00', 'en_US').format(calculatedNetBalance)}\n";
    if ((netBalance - calculatedNetBalance).abs() < 0.01) {
      analysis += "✓ Balance calculation is CORRECT\n";
    } else {
      analysis += "✗ Balance calculation is INCORRECT\n";
      analysis +=
          "Difference: ${NumberFormat('#,##0.00', 'en_US').format(netBalance - calculatedNetBalance)}\n";
    }
    calculationAnalysis.value = analysis;
    showCalculationAnalysis.value = true;
  }

  @override
  void onClose() {
    fromDateController.dispose();
    toDateController.dispose();
    searchController.dispose();
    super.onClose();
  }
}

class ItemLedgerEntryAddEdit extends StatelessWidget {
  final String ledgerNo;
  final ItemLedgerEntry? entry;
  final Item item;
  final VoidCallback? onEntrySaved;

  const ItemLedgerEntryAddEdit({
    super.key,
    required this.ledgerNo,
    required this.item,
    this.entry,
    this.onEntrySaved,
  });

  @override
  Widget build(BuildContext context) {
    final ItemLedgerEntryController controller = Get.put(
      ItemLedgerEntryController(item),
    );
    final ScrollController scrollController = ScrollController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadLedgerEntry(entry: entry, ledgerNo: ledgerNo, item: item);
      scrollController.jumpTo(0);
    });

    return Obx(
      () => Scaffold(
        appBar: AppBar(
          title: Text(entry == null ? 'Add Ledger Entry' : 'Edit Ledger Entry'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.of(context).pop();
              controller.clearForm();
              scrollController.dispose();
            },
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            controller: scrollController,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                        Theme.of(context).colorScheme.surface,
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
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.voucherNoController,
                                focusNode: controller.voucherNoFocusNode,
                                label: 'Voucher No',
                                readOnly: true,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Voucher No is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.itemIdController,
                                focusNode: controller.itemIdFocusNode,
                                label: 'Item ID',
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Item ID is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.itemWeightType,
                                focusNode: controller.itemWeightTypeFocusNode,
                                label: 'Type',
                                readOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.itemWeightPrevious,
                                focusNode:
                                    controller.itemWeightPreviousFocusNode,
                                label: 'Available Stock',
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Available Stock is required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.unitPriceController,
                                focusNode:
                                    controller.unitPriceControllerFocusNode,
                                label: item.type.toLowerCase() == 'powder'
                                    ? 'Price/kg'
                                    : 'Price/L',
                                readOnly: false,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Unit Price is required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) == 0.0) {
                                    return 'Unit Price must be a non-zero number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.costPriceController,
                                focusNode: controller.costPriceFocusNode,
                                label: 'Cost Price',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Cost Price is required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) == 0.0) {
                                    return 'Cost Price must be a non-zero number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.sellingPriceController,
                                focusNode: controller.sellingPriceFocusNode,
                                label: 'Selling Price',
                                readOnly: true,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Selling Price is required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) == 0.0) {
                                    return 'Selling Price must be a non-zero number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.canWeightController,
                                focusNode: controller.canWeightFocusNode,
                                label: 'Can Weight',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Can Weight is required';
                                  }
                                  if (double.tryParse(value) == null ||
                                      double.parse(value) == 0.0) {
                                    return 'Can Weight must be a non-zero number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.itemWeightCurrent,
                                focusNode:
                                    controller.itemWeightCurrentFocusNode,
                                label:
                                    'New Stock (${item.type.toLowerCase() == 'powder' ? 'kg' : 'L'})',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (!controller.arePriceFieldsValid()) {
                                    return 'Please fill all price fields above first';
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'New Stock is required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.itemNameController,
                                focusNode: controller.itemNameFocusNode,
                                label: 'Item Name',
                                readOnly: true,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Item Name is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue:
                                    controller.transactionType.value.isNotEmpty
                                    ? controller.transactionType.value
                                    : null,
                                focusNode: controller.transactionTypeFocusNode,
                                style: Theme.of(context).textTheme.bodyMedium,
                                decoration: InputDecoration(
                                  labelText: 'Transaction Type',
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
                                ),
                                items: const ['Debit', 'Credit']
                                    .map(
                                      (t) => DropdownMenuItem<String>(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (!controller.arePriceFieldsValid()) {
                                    Get.snackbar(
                                      'Error',
                                      'Please fill all price fields above first',
                                      snackPosition: SnackPosition.BOTTOM,
                                      backgroundColor: Colors.red,
                                    );
                                    return;
                                  }
                                  if (value != null) {
                                    controller.transactionType.value = value;
                                    controller.transactionTypeController.text =
                                        value;
                                    controller.updateTransactionFields();
                                  }
                                },
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Transaction Type is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.debitController,
                                focusNode: controller.debitFocusNode,
                                label: 'Debit',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (!controller.arePriceFieldsValid()) {
                                    return 'Please fill all price fields above first';
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'Debit is required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.creditController,
                                focusNode: controller.creditFocusNode,
                                label: 'Credit',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'^\d*\.?\d*'),
                                  ),
                                ],
                                validator: (value) {
                                  if (!controller.arePriceFieldsValid()) {
                                    return 'Please fill all price fields above first';
                                  }
                                  if (value == null || value.isEmpty) {
                                    return 'Credit is required';
                                  }
                                  if (double.tryParse(value) == null) {
                                    return 'Please enter a valid number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: buildTextField(
                                context: context,
                                controller: controller.balanceController,
                                focusNode: controller.balanceFocusNode,
                                label: 'Balance',
                                readOnly: true,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Balance is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: controller.createdAtController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Created At',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () =>
                                        controller.selectCreatedAt(context),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Created At is required'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: controller.updatedAtController,
                                readOnly: true,
                                decoration: InputDecoration(
                                  labelText: 'Updated At',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  labelStyle: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.8),
                                      ),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: () =>
                                        controller.selectUpdatedAt(context),
                                  ),
                                ),
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Updated At is required'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                controller.clearForm();
                                scrollController.dispose();
                              },
                              child: Text(
                                'Cancel',
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.8),
                                    ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: () async {
                                if (controller.formKey.currentState!
                                    .validate()) {
                                  final entry = await controller
                                      .saveLedgerEntry(context, ledgerNo);
                                  if (entry != null) {
                                    if (onEntrySaved != null) {
                                      onEntrySaved!();
                                    }
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                      Get.snackbar(
                                        'Success',
                                        'Ledger entry saved successfully',
                                        snackPosition: SnackPosition.BOTTOM,
                                        backgroundColor: Colors.green,
                                      );
                                    }
                                    scrollController.dispose();
                                  }
                                } else {
                                  _requestFocusForInvalidField(
                                    controller,
                                    context,
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.primary,
                                foregroundColor: Theme.of(
                                  context,
                                ).iconTheme.color,
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
            ),
          ),
        ),
      ),
    );
  }

  void _requestFocusForInvalidField(
    ItemLedgerEntryController controller,
    BuildContext context,
  ) {
    if (controller.voucherNoController.text.isEmpty) {
      controller.voucherNoFocusNode.requestFocus();
    } else if (controller.itemIdController.text.isEmpty) {
      controller.itemIdFocusNode.requestFocus();
    } else if (controller.itemNameController.text.isEmpty) {
      controller.itemNameFocusNode.requestFocus();
    } else if (controller.unitPriceController.text.isEmpty ||
        double.tryParse(controller.unitPriceController.text) == null ||
        double.parse(controller.unitPriceController.text) == 0.0) {
      controller.unitPriceControllerFocusNode.requestFocus();
    } else if (controller.costPriceController.text.isEmpty ||
        double.tryParse(controller.costPriceController.text) == null ||
        double.parse(controller.costPriceController.text) == 0.0) {
      controller.costPriceFocusNode.requestFocus();
    } else if (controller.sellingPriceController.text.isEmpty ||
        double.tryParse(controller.sellingPriceController.text) == null ||
        double.parse(controller.sellingPriceController.text) == 0.0) {
      controller.sellingPriceFocusNode.requestFocus();
    } else if (controller.canWeightController.text.isEmpty ||
        double.tryParse(controller.canWeightController.text) == null ||
        double.parse(controller.canWeightController.text) == 0.0) {
      controller.canWeightFocusNode.requestFocus();
    } else if (controller.transactionType.value.isEmpty) {
      controller.transactionTypeFocusNode.requestFocus();
    } else if (controller.itemWeightCurrent.text.isEmpty ||
        double.tryParse(controller.itemWeightCurrent.text) == null) {
      controller.itemWeightCurrentFocusNode.requestFocus();
    } else if (controller.debitController.text.isEmpty ||
        double.tryParse(controller.debitController.text) == null) {
      controller.debitFocusNode.requestFocus();
    } else if (controller.creditController.text.isEmpty ||
        double.tryParse(controller.creditController.text) == null) {
      controller.creditFocusNode.requestFocus();
    } else if (controller.balanceController.text.isEmpty) {
      controller.balanceFocusNode.requestFocus();
    }
  }

  Widget buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    final itemController = Get.find<ItemLedgerEntryController>();
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        labelStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
      validator: validator,
      style: Theme.of(context).textTheme.bodyMedium,
      onChanged: (value) {
        itemController.updateTransactionFields();
      },
    );
  }
}

class ItemLedgerEntryController extends GetxController {
  ItemLedgerEntryController(this.currentItem);
  final ItemLedgerTableController itemLedgerTableController =
      Get.find<ItemLedgerTableController>();
  final Item currentItem;
  final formKey = GlobalKey<FormState>();
  final ledgerNoController = TextEditingController();
  final voucherNoController = TextEditingController();
  final itemWeightType = TextEditingController();
  final itemWeightPrevious = TextEditingController();
  final itemWeightCurrent = TextEditingController();
  final itemIdController = TextEditingController();
  final itemNameController = TextEditingController();
  final transactionTypeController = TextEditingController();
  final debitController = TextEditingController();
  final creditController = TextEditingController();
  final balanceController = TextEditingController();
  final createdAtController = TextEditingController();
  final updatedAtController = TextEditingController();
  final unitPriceController = TextEditingController();
  final costPriceController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final canWeightController = TextEditingController();
  final RxString transactionType = RxString("Debit");
  final Rx<DateTime> createdAt = DateTime.now().obs;
  final Rx<DateTime?> updatedAt = Rxn<DateTime?>();
  final ledgerNoFocusNode = FocusNode();
  final voucherNoFocusNode = FocusNode();
  final itemIdFocusNode = FocusNode();
  final itemNameFocusNode = FocusNode();
  final itemWeightTypeFocusNode = FocusNode();
  final itemWeightPreviousFocusNode = FocusNode();
  final itemWeightCurrentFocusNode = FocusNode();
  final transactionTypeFocusNode = FocusNode();
  final createdAtFocusNode = FocusNode();
  final updatedAtFocusNode = FocusNode();
  final debitFocusNode = FocusNode();
  final creditFocusNode = FocusNode();
  final balanceFocusNode = FocusNode();
  final unitPriceControllerFocusNode = FocusNode();
  final costPriceFocusNode = FocusNode();
  final sellingPriceFocusNode = FocusNode();
  final canWeightFocusNode = FocusNode();
  final Rx<int> entryId = 0.obs;
  double? previousBalance;
  bool _isUpdatingCredit = false;
  bool _isUpdatingDebit = false;
  bool _isUpdatingQty = false;
  final repo = InventoryRepository();

  double get netBalance {
    if (itemLedgerTableController.filteredLedgerEntries.isEmpty) return 0;
    return itemLedgerTableController.filteredLedgerEntries.last.balance;
  }

  @override
  void onInit() async {
    super.onInit();
    itemWeightCurrent.addListener(updateTransactionFields);
    debitController.addListener(updateTransactionFields);
    creditController.addListener(updateTransactionFields);
    unitPriceController.addListener(_updateSellingPrice);
    canWeightController.addListener(_updateSellingPrice);
    ever(transactionType, (String value) {
      updateTransactionFields();
    });

    final updatedItem = await repo.getItemById(currentItem.id!);
    if (updatedItem != null) {
      unitPriceController.text = updatedItem.pricePerKg != 0.0
          ? updatedItem.pricePerKg.toStringAsFixed(2)
          : "";
      costPriceController.text = updatedItem.costPrice != 0.0
          ? updatedItem.costPrice.toStringAsFixed(2)
          : "";
      canWeightController.text = updatedItem.canWeight != 0.0
          ? updatedItem.canWeight.toStringAsFixed(2)
          : "";
      _updateSellingPrice();
    }
  }

  bool arePriceFieldsValid() {
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    final costPrice = double.tryParse(costPriceController.text) ?? 0.0;
    final sellingPrice = double.tryParse(sellingPriceController.text) ?? 0.0;
    final canWeight = double.tryParse(canWeightController.text) ?? 0.0;
    return unitPrice != 0.0 &&
        costPrice != 0.0 &&
        sellingPrice != 0.0 &&
        canWeight != 0.0 &&
        unitPriceController.text.isNotEmpty &&
        costPriceController.text.isNotEmpty &&
        sellingPriceController.text.isNotEmpty &&
        canWeightController.text.isNotEmpty;
  }

  void _updateSellingPrice() {
    if (_isUpdatingQty) return;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    final canWeight = double.tryParse(canWeightController.text) ?? 0.0;
    final sellingPrice = unitPrice * canWeight;
    sellingPriceController.text = sellingPrice != 0.0
        ? sellingPrice.toStringAsFixed(2)
        : "";
    updateTransactionFields();
  }

  void updateTransactionFields() async {
    if (_isUpdatingQty || _isUpdatingDebit || _isUpdatingCredit) return;
    if (!arePriceFieldsValid()) {
      updateBalance();
      return;
    }

    _isUpdatingQty = true;
    _isUpdatingDebit = true;
    _isUpdatingCredit = true;

    final qty = double.tryParse(itemWeightCurrent.text) ?? 0.0;
    final unitPrice = double.tryParse(unitPriceController.text) ?? 0.0;
    final amount = qty * unitPrice;

    if (transactionType.value == "Debit") {
      debitController.text = amount != 0.0 ? amount.toStringAsFixed(2) : "0.00";
      creditController.text = "0.00";
    } else {
      creditController.text = amount != 0.0
          ? amount.toStringAsFixed(2)
          : "0.00";
      debitController.text = "0.00";
    }

    _isUpdatingQty = false;
    _isUpdatingDebit = false;
    _isUpdatingCredit = false;
    updateBalance();
  }

  void updateBalance() {
    // final debit = double.tryParse(debitController.text) ?? 0.0;
    final credit = double.tryParse(creditController.text) ?? 0.0;
    final previous = netBalance;
    double balance =
        previous + credit; // Changed to add credit instead of subtract
    if (balance < 0) {
      balance = 0.0;
    }
    balanceController.text = balance.toStringAsFixed(2);
  }

  Future<void> loadLedgerEntry({
    required String ledgerNo,
    ItemLedgerEntry? entry,
    required Item item,
  }) async {
    ledgerNoController.text = ledgerNo;
    previousBalance = await _getPreviousBalance(ledgerNo);
    itemWeightPrevious.text = previousBalance!.toStringAsFixed(2);
    updateBalance();

    if (entry != null) {
      entryId.value = entry.id ?? 0;
      voucherNoController.text = entry.voucherNo;
      itemIdController.text = entry.itemId.toString();
      itemNameController.text = entry.itemName;
      transactionType.value = entry.transactionType;
      transactionTypeController.text = entry.transactionType;
      debitController.text = entry.debit != 0.0
          ? entry.debit.toStringAsFixed(2)
          : "0.00";
      creditController.text = entry.credit != 0.0
          ? entry.credit.toStringAsFixed(2)
          : "0.00";
      balanceController.text = entry.balance.toStringAsFixed(2);
      itemWeightType.text = item.type.toString();
      createdAt.value = entry.createdAt;
      updatedAt.value = entry.createdAt;
      createdAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(createdAt.value);
      updatedAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(updatedAt.value!);
      double change = entry.transactionType == "Credit"
          ? entry.credit
          : entry.debit; // Removed negation for debit
      previousBalance = entry.balance - change;
      itemWeightPrevious.text = previousBalance!.toStringAsFixed(2);
      itemWeightCurrent.text =
          (entry.transactionType == "Debit" ? entry.debit : entry.credit) != 0.0
          ? (entry.transactionType == "Debit" ? entry.debit : entry.credit)
                .toStringAsFixed(2)
          : "";
      unitPriceController.text = item.pricePerKg != 0.0
          ? item.pricePerKg.toStringAsFixed(2)
          : "";
      costPriceController.text = item.costPrice != 0.0
          ? item.costPrice.toStringAsFixed(2)
          : "";
      canWeightController.text = item.canWeight != 0.0
          ? item.canWeight.toStringAsFixed(2)
          : "";
      _updateSellingPrice();
    } else {
      entryId.value = 0;
      voucherNoController.text = await _generateVoucherNo(ledgerNo);
      itemIdController.text = item.id?.toString() ?? "";
      itemNameController.text = item.name;
      itemWeightType.text = item.type.toString();
      transactionType.value = "Debit";
      transactionTypeController.text = "Debit";
      debitController.text = "0.00";
      creditController.text = "0.00";
      createdAt.value = DateTime.now();
      updatedAt.value = DateTime.now();
      createdAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(createdAt.value);
      updatedAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(updatedAt.value!);
      itemWeightCurrent.text = "";
      unitPriceController.text = item.pricePerKg != 0.0
          ? item.pricePerKg.toStringAsFixed(2)
          : "";
      costPriceController.text = item.costPrice != 0.0
          ? item.costPrice.toStringAsFixed(2)
          : "";
      canWeightController.text = item.canWeight != 0.0
          ? item.canWeight.toStringAsFixed(2)
          : "";
      _updateSellingPrice();
    }
    updateTransactionFields();
  }

  Future<String> _generateVoucherNo(String ledgerNo) async {
    return await repo.getLastVoucherNo(ledgerNo);
  }

  Future<double> _getPreviousBalance(String ledgerNo) async {
    final entries = await repo.getItemLedgerEntries(ledgerNo);
    if (entries.isEmpty) return 0.0;
    entries.sort((a, b) {
      int dateComp = a.createdAt.compareTo(b.createdAt);
      if (dateComp != 0) return dateComp;
      return a.id!.compareTo(b.id!);
    });
    double running = 0.0;
    for (var e in entries) {
      running += e.transactionType == "Credit"
          ? e.credit
          : e.debit; // Changed to add debit
    }
    return running;
  }

  Future<ItemLedgerEntry?> saveLedgerEntry(
    BuildContext context,
    String ledgerNo,
  ) async {
    if (!formKey.currentState!.validate()) {
      if (kDebugMode) {
        print("Form validation failed");
      }
      return null;
    }
    try {
      final itemId = int.tryParse(itemIdController.text);
      if (itemId == null) {
        if (kDebugMode) {
          print("Error: itemId is null or invalid: ${itemIdController.text}");
        }
        Get.snackbar(
          'Error',
          'Invalid Item ID',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
        return null;
      }

      final debit = double.tryParse(debitController.text) ?? 0.0;
      final credit = double.tryParse(creditController.text) ?? 0.0;
      if (debit == 0.0 && credit == 0.0) {
        if (kDebugMode) {
          print("Error: Both debit and credit are 0");
        }
        Get.snackbar(
          'Error',
          'Debit or Credit must be non-zero',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
        return null;
      }

      final entry = ItemLedgerEntry(
        id: entryId.value == 0 ? null : entryId.value,
        ledgerNo: ledgerNoController.text,
        voucherNo: voucherNoController.text,
        itemId: itemId,
        itemName: itemNameController.text,
        transactionType: transactionType.value,
        debit: debit,
        credit: credit,
        balance: double.tryParse(balanceController.text) ?? 0.0,
        createdAt: createdAt.value,
        updatedAt: updatedAt.value ?? DateTime.now(),
      );

      final isEdit = entryId.value != 0;
      if (isEdit) {
        if (kDebugMode) {
          print("Editing existing entry with ID: ${entryId.value}");
        }
        final oldEntry = await repo.getItemLedgerEntryById(
          ledgerNo,
          entryId.value,
        );
        if (oldEntry != null) {
          final reverseType = oldEntry.transactionType == "Debit"
              ? "Credit"
              : "Debit";
          final oldQty = oldEntry.transactionType == "Debit"
              ? oldEntry.debit
              : oldEntry.credit;
          if (kDebugMode) {
            print(
              "Reversing old stock: itemId=$itemId, type=$reverseType, qty=$oldQty",
            );
          }
          await repo.updateItemStock(
            itemId: itemId,
            transactionType: reverseType,
            quantity: oldQty,
          );
        } else {
          if (kDebugMode) {
            print(
              "Error: Could not find existing entry with ID: ${entryId.value}",
            );
          }
          Get.snackbar(
            'Error',
            'Existing entry not found',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
          );
          return null;
        }
      } else {
        if (kDebugMode) {
          print("Creating new entry for ledgerNo: $ledgerNo");
          print("Saving entry: ${entry.toString()}");
        }
        final costPrice = double.tryParse(costPriceController.text) ?? 0.0;
        final sellingPrice =
            double.tryParse(sellingPriceController.text) ?? 0.0;
        final canWeight = double.tryParse(canWeightController.text) ?? 0.0;
        final item = Item(
          id: itemId,
          name: itemNameController.text,
          type: itemWeightType.text,
          vendor: currentItem.vendor,
          availableStock: double.tryParse(itemWeightPrevious.text) ?? 0.0,
          pricePerKg: double.tryParse(unitPriceController.text) ?? 0.0,
          costPrice: costPrice,
          sellingPrice: sellingPrice,
          canWeight: canWeight,
        );
        final updateResult = await repo.updateItem(item);
        if (kDebugMode) {
          print("Item update result: $updateResult");
        }
        if (updateResult <= 0) {
          if (kDebugMode) {
            print("Error: Failed to update item with ID: $itemId");
          }
          Get.snackbar(
            'Error',
            'Failed to update item details',
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
          );
          return null;
        }
      }

      final result = await repo.insertItemLedgerEntry(ledgerNo, entry);
      if (kDebugMode) {
        print("Insert result: $result");
      }
      if (result <= 0) {
        if (kDebugMode) {
          print(
            "Error: insertItemLedgerEntry returned $result, indicating failure",
          );
        }
        Get.snackbar(
          'Error',
          'Failed to save ledger entry to database',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
        );
        return null;
      }

      final qty = entry.transactionType == "Debit" ? entry.debit : entry.credit;
      if (kDebugMode) {
        print(
          "Updating stock: itemId=$itemId, type=${entry.transactionType}, qty=$qty",
        );
      }
      await repo.updateItemStock(
        itemId: itemId,
        transactionType: entry.transactionType,
        quantity: qty,
      );

      // Reload the current item to update prices
      final updatedItem = await repo.getItemById(itemId);
      if (updatedItem != null) {
        unitPriceController.text = updatedItem.pricePerKg != 0.0
            ? updatedItem.pricePerKg.toStringAsFixed(2)
            : "";
        costPriceController.text = updatedItem.costPrice != 0.0
            ? updatedItem.costPrice.toStringAsFixed(2)
            : "";
        canWeightController.text = updatedItem.canWeight != 0.0
            ? updatedItem.canWeight.toStringAsFixed(2)
            : "";
        _updateSellingPrice();
      }

      return entry;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print("Error saving ledger entry: $e\nStackTrace: $stackTrace");
      }
      Get.snackbar(
        'Error',
        'Error saving entry: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
      );
      return null;
    }
  }

  Future<void> selectCreatedAt(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: createdAt.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      createdAt.value = DateTime(picked.year, picked.month, picked.day);
      createdAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(createdAt.value);
      if (entryId.value != 0) {
        updatedAt.value = createdAt.value;
        updatedAtController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(updatedAt.value!);
      }
    }
  }

  Future<void> selectUpdatedAt(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: updatedAt.value ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      updatedAt.value = DateTime(picked.year, picked.month, picked.day);
      updatedAtController.text = DateFormat(
        'dd-MM-yyyy',
      ).format(updatedAt.value!);
      if (entryId.value != 0) {
        createdAt.value = updatedAt.value!;
        createdAtController.text = DateFormat(
          'dd-MM-yyyy',
        ).format(createdAt.value);
      }
    }
  }

  void clearForm() {
    ledgerNoController.clear();
    voucherNoController.clear();
    itemIdController.clear();
    itemNameController.clear();
    transactionTypeController.clear();
    debitController.clear();
    creditController.clear();
    balanceController.clear();
    createdAtController.clear();
    updatedAtController.clear();
    itemWeightCurrent.clear();
    itemWeightPrevious.clear();
    itemWeightType.clear();
    unitPriceController.clear();
    costPriceController.clear();
    sellingPriceController.clear();
    canWeightController.clear();
    transactionType.value = "Debit";
    createdAt.value = DateTime.now();
    updatedAt.value = null;
    previousBalance = null;
    entryId.value = 0;
  }

  @override
  void onClose() {
    ledgerNoController.dispose();
    voucherNoController.dispose();
    itemIdController.dispose();
    itemWeightCurrent.dispose();
    itemWeightPrevious.dispose();
    itemWeightType.dispose();
    itemNameController.dispose();
    transactionTypeController.dispose();
    debitController.dispose();
    creditController.dispose();
    balanceController.dispose();
    createdAtController.dispose();
    updatedAtController.dispose();
    unitPriceController.dispose();
    costPriceController.dispose();
    sellingPriceController.dispose();
    canWeightController.dispose();
    ledgerNoFocusNode.dispose();
    voucherNoFocusNode.dispose();
    itemIdFocusNode.dispose();
    itemNameFocusNode.dispose();
    transactionTypeFocusNode.dispose();
    createdAtFocusNode.dispose();
    updatedAtFocusNode.dispose();
    debitFocusNode.dispose();
    creditFocusNode.dispose();
    balanceFocusNode.dispose();
    itemWeightTypeFocusNode.dispose();
    itemWeightCurrentFocusNode.dispose();
    itemWeightPreviousFocusNode.dispose();
    unitPriceControllerFocusNode.dispose();
    costPriceFocusNode.dispose();
    sellingPriceFocusNode.dispose();
    canWeightFocusNode.dispose();
    super.onClose();
  }
}
