import 'package:flutter/material.dart';

import 'csv_import_repository.dart';
import 'export_repository.dart';

class AutomationScreen extends StatefulWidget {
  const AutomationScreen({super.key});

  @override
  State<AutomationScreen> createState() => _AutomationScreenState();
}

class _AutomationScreenState extends State<AutomationScreen> {
  final ExportRepository _exportRepo = ExportRepository();
  final CSVImportRepository _csvRepo = CSVImportRepository();

  @override
  void initState() {
    super.initState();
  }

  void _exportExcel() async {
    // final path = await _exportRepo.exportInvoicesToExcel();
    // ScaffoldMessenger.of(
    //   context,
    // ).showSnackBar(SnackBar(content: Text('Invoices exported to $path')));
  }

  void _exportPDF() async {
    await _exportRepo.exportInvoicesToPDF();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invoices exported to PDF')));
  }

  void _sendReminder() async {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Reminder sent')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Automation & Integrations')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _exportExcel,
              child: const Text('Export Invoices to Excel'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _exportPDF,
              child: const Text('Export Invoices to PDF'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _sendReminder,
              child: const Text('Send Payment Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
