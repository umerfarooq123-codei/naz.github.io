import 'package:get/get.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';
import 'package:ledger_master/core/repositories/kpi_repository.dart';
import 'package:ledger_master/features/automation/automation_screen.dart';
import 'package:ledger_master/features/automation/csv_import_repository.dart';
import 'package:ledger_master/features/automation/export_repository.dart';
import 'package:ledger_master/features/bank_reconciliation/bank_repository.dart';
import 'package:ledger_master/features/customer_vendor/customer_ledger_table.dart';
import 'package:ledger_master/features/customer_vendor/customer_list.dart';
import 'package:ledger_master/features/customer_vendor/customer_repository.dart';
import 'package:ledger_master/features/inventory/inventory_repository.dart';
import 'package:ledger_master/features/inventory/item_list.dart';
import 'package:ledger_master/features/ledger/ledger_home.dart';
import 'package:ledger_master/features/ledger/ledger_repository.dart';
import 'package:ledger_master/features/payroll/payroll_repository.dart';
import 'package:ledger_master/features/purchases_expenses/purchase_and_expense_list_and_form.dart';
import 'package:ledger_master/features/purchases_expenses/purchase_expense_repository.dart';
import 'package:ledger_master/features/sales_invoicing/invoice_repository.dart';
import 'package:ledger_master/main.dart';

/// Service Bindings - Initialize all repositories and controllers when app starts
class ServiceBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize Repositories
    Get.lazyPut<LedgerRepository>(() => LedgerRepository());
    Get.lazyPut<CustomerRepository>(() => CustomerRepository());
    Get.lazyPut<CustomerLedgerRepository>(() => CustomerLedgerRepository());
    Get.lazyPut<InventoryRepository>(() => InventoryRepository());
    Get.lazyPut<ExpensePurchaseRepository>(() => ExpensePurchaseRepository());
    Get.lazyPut<InvoiceRepository>(() => InvoiceRepository());
    Get.lazyPut<PayrollRepository>(() => PayrollRepository());
    Get.lazyPut<BankRepository>(() => BankRepository());
    Get.lazyPut<CansRepository>(() => CansRepository());
    Get.lazyPut<ExportRepository>(() => ExportRepository());
    Get.lazyPut<CSVImportRepository>(() => CSVImportRepository());
    Get.lazyPut<KPIRepository>(() => KPIRepository());

    // Initialize Controllers
    Get.put(ThemeController());

    Get.put(LedgerController(Get.find<LedgerRepository>()));
    Get.put(LedgerTableController());

    Get.put(CustomerController(Get.find<CustomerRepository>()));
    Get.put(CustomerLedgerTableController());

    Get.put(ItemController(Get.find<InventoryRepository>(), null));
    Get.put(ItemLedgerTableController());
    // Note: ItemLedgerEntryController requires an Item parameter (currentItem)
    // It cannot be initialized globally - instantiate it when needed with:
    // Get.put(ItemLedgerEntryController(item))

    Get.put(ExpensePurchaseGetxController());

    Get.put(AutomationController());
  }
}
