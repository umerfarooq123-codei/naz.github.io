import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../sales_invoicing/invoice_repository.dart';

class ExportRepository {
  final InvoiceRepository _invoiceRepo = InvoiceRepository();

  // EXPORT INVOICES TO EXCEL
  // Future<String> exportInvoicesToExcel() async {
  //   final invoices = await _invoiceRepo.getAllInvoices();
  //   final excel = Excel.createExcel();
  //   final sheet = excel['Invoices'];

  //   // Add header row
  //   sheet.appendRow([
  //     'Invoice No',
  //     'Customer',
  //     'Date',
  //     'Total Amount',
  //     'Paid Amount',
  //     'Balance',
  //   ]);

  //   for (var inv in invoices) {
  //     sheet.appendRow([
  //       inv.id.toString(),
  //       inv.customerId.toString(),
  //       inv.date.toIso8601String(),
  //       inv.totalAmount,
  //       inv.paidAmount,
  //       inv.balance,
  //     ]);
  //   }

  //   final directory = await getApplicationDocumentsDirectory();
  //   final path = '${directory.path}/invoices.xlsx';
  //   final fileBytes = excel.encode();
  //   if (fileBytes == null) throw Exception('Excel encoding failed');
  //   File(path).writeAsBytesSync(fileBytes);

  //   return path;
  // }

  // EXPORT INVOICES TO PDF
  Future<void> exportInvoicesToPDF() async {
    final invoices = await _invoiceRepo.getAllInvoices();
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Invoices Report',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headers: [
              'Invoice No',
              'Customer',
              'Date',
              'Total',
              'Paid',
              'Balance',
            ],
            data: invoices
                .map(
                  (inv) => [
                    inv.id,
                    inv.customerId,
                    inv.date.toIso8601String(),
                    inv.totalAmount,
                    inv.paidAmount,
                    inv.balance,
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) => pdf.save());
  }
}
