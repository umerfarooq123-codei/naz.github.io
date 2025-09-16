import '../../core/database/db_helper.dart';
import '../../features/customer_vendor/customer_repository.dart';
import '../../features/purchases_expenses/purchase_expense_repository.dart';
import '../../features/sales_invoicing/invoice_repository.dart';

class ReportRepository {
  final DBHelper _dbHelper = DBHelper();
  final InvoiceRepository _invoiceRepo = InvoiceRepository();
  final PurchaseExpenseRepository _purchaseRepo = PurchaseExpenseRepository();
  final CustomerRepository _customerRepo = CustomerRepository();

  // PROFIT & LOSS REPORT
  Future<Map<String, double>> getProfitAndLoss() async {
    final invoices = await _invoiceRepo.getAllInvoices();
    final purchases = await _purchaseRepo.getAllPurchases();
    final expenses = await _purchaseRepo.getAllExpenses();

    double totalSales = invoices.fold(0, (sum, i) => sum + i.totalAmount);
    double totalCOGS = purchases.fold(0, (sum, p) => sum + p.totalAmount);
    double totalExpenses = expenses.fold(0, (sum, e) => sum + e.amount);

    double netProfit = totalSales - totalCOGS - totalExpenses;

    return {
      'Total Sales': totalSales,
      'Total COGS': totalCOGS,
      'Total Expenses': totalExpenses,
      'Net Profit': netProfit,
    };
  }

  // BALANCE SHEET
  Future<Map<String, double>> getBalanceSheet() async {
    // Assets: Cash (total received from invoices) + Stock
    // Liabilities: Vendor dues (from purchases)
    // Equity = Assets - Liabilities

    final db = await _dbHelper.database;
    final stockResult = await db.rawQuery(
      'SELECT SUM(costPrice * stock) as totalStock FROM item',
    );
    final totalStock = stockResult.first['totalStock'] as double? ?? 0.0;

    final invoices = await _invoiceRepo.getAllInvoices();
    final totalCash = invoices.fold(0.0, (sum, i) => sum + i.paidAmount);

    final purchases = await _purchaseRepo.getAllPurchases();
    final totalLiabilities = purchases.fold(0.0, (sum, p) => sum + p.balance);

    final totalAssets = totalCash + totalStock;
    final equity = totalAssets - totalLiabilities;

    return {
      'Total Assets': totalAssets,
      'Total Liabilities': totalLiabilities,
      'Equity': equity,
    };
  }

  // CASH FLOW
  Future<Map<String, double>> getCashFlow() async {
    final invoices = await _invoiceRepo.getAllInvoices();
    final purchases = await _purchaseRepo.getAllPurchases();
    final expenses = await _purchaseRepo.getAllExpenses();

    final cashIn = invoices.fold(0.0, (sum, i) => sum + i.paidAmount);
    final cashOut =
        purchases.fold(0.0, (sum, p) => sum + p.paidAmount) +
        expenses.fold(0.0, (sum, e) => sum + e.amount);

    final netCashFlow = cashIn - cashOut;

    return {
      'Cash In': cashIn,
      'Cash Out': cashOut,
      'Net Cash Flow': netCashFlow,
    };
  }

  // DEBTORS / CREDITORS AGING
  Future<List<Map<String, dynamic>>> getDebtorsAging() async {
    final customers = await _customerRepo.getAllCustomers();
    final invoices = await _invoiceRepo.getAllInvoices();

    return customers.map((c) {
      final customerInvoices = invoices
          .where((i) => i.customerId == c.id)
          .toList();
      final overdue = customerInvoices.fold(0.0, (sum, i) => sum + i.balance);
      return {'Customer': c.name, 'Outstanding': overdue};
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getCreditorsAging() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT v.name as Vendor, SUM(p.totalAmount - p.paidAmount) as Outstanding
      FROM vendor v
      LEFT JOIN purchase p ON v.id = p.vendorId
      GROUP BY v.id
    ''');
    return result;
  }
}
