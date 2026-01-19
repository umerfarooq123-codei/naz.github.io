import 'package:get/get.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';
import 'package:ledger_master/core/services/sheet_sync_service.dart'; // Add this import
import 'package:ledger_master/features/automation/automation_screen.dart';
import 'package:ledger_master/features/bank_reconciliation/bank_repository.dart';
import 'package:ledger_master/features/cans/cans_controller.dart';
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
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_repository.dart';
import 'package:ledger_master/features/vendor_ledger/vendor_ledger_table_controller.dart';
import 'package:ledger_master/main.dart';

class ServiceBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize Repositories first
    Get.put<LedgerRepository>(LedgerRepository(), permanent: true);
    Get.put<CustomerRepository>(CustomerRepository(), permanent: true);
    Get.put<CustomerLedgerRepository>(
      CustomerLedgerRepository(),
      permanent: true,
    );
    Get.put<VendorLedgerRepository>(VendorLedgerRepository(), permanent: true);
    Get.put<InventoryRepository>(InventoryRepository(), permanent: true);
    Get.put<ExpensePurchaseRepository>(
      ExpensePurchaseRepository(),
      permanent: true,
    );
    Get.put<InvoiceRepository>(InvoiceRepository(), permanent: true);
    Get.put<PayrollRepository>(PayrollRepository(), permanent: true);
    Get.put<BankRepository>(BankRepository(), permanent: true);
    Get.put<CansRepository>(CansRepository(), permanent: true);

    // Initialize ThemeController first (no dependencies)
    Get.put(ThemeController(), permanent: true);

    // ✅ ADD: SheetSyncService as a GetX Service
    Get.put(SheetSyncService(), permanent: true);

    // ✅ Use lazyPut to break circular dependency
    Get.lazyPut(() => LedgerTableController(), fenix: true);
    Get.lazyPut(
      () => LedgerController(Get.find<LedgerRepository>()),
      fenix: true,
    );

    // Then other controllers
    Get.lazyPut(
      () => CustomerController(Get.find<CustomerRepository>()),
      fenix: true,
    );
    Get.lazyPut(() => CustomerLedgerTableController(), fenix: true);
    Get.lazyPut(() => VendorLedgerTableController(), fenix: true);
    Get.lazyPut(() => CansController(Get.find<CansRepository>()), fenix: true);
    Get.lazyPut(() => ItemLedgerTableController(), fenix: true);
    Get.lazyPut(
      () => ItemController(Get.find<InventoryRepository>(), null),
      fenix: true,
    );
    Get.lazyPut(() => ExpensePurchaseGetxController(), fenix: true);
    Get.lazyPut(() => AutomationController(), fenix: true);
  }
}
