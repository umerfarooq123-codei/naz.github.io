import 'package:get/get.dart';
import 'package:ledger_master/core/repositories/cans_repository.dart';
import 'package:ledger_master/core/repositories/kpi_repository.dart';
import 'package:ledger_master/features/automation/automation_screen.dart';
import 'package:ledger_master/features/automation/csv_import_repository.dart';
import 'package:ledger_master/features/automation/export_repository.dart';
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

/// Service Bindings - Initialize all repositories and controllers when app starts
class ServiceBindings extends Bindings {
  @override
  void dependencies() {
    // Initialize Repositories (keep existing)
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
    Get.put<ExportRepository>(ExportRepository(), permanent: true);
    Get.put<CSVImportRepository>(CSVImportRepository(), permanent: true);
    Get.put<KPIRepository>(KPIRepository(), permanent: true);

    // Initialize Controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(LedgerController(Get.find<LedgerRepository>()), permanent: true);
    Get.put(LedgerTableController(), permanent: true);
    Get.put(
      CustomerController(Get.find<CustomerRepository>()),
      permanent: true,
    );
    Get.put(CustomerLedgerTableController(), permanent: true);
    Get.put(VendorLedgerTableController(), permanent: true);
    Get.put(CansController(CansRepository()), permanent: true);
    Get.put(ItemLedgerTableController(), permanent: true);

    // ✅ Add ItemController registration
    Get.put(
      ItemController(Get.find<InventoryRepository>(), null),
      permanent: true,
    );

    Get.put(ExpensePurchaseGetxController(), permanent: true);
    Get.put(AutomationController(), permanent: true);
  }
}
