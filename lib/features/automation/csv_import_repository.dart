import 'dart:io';

import 'package:csv/csv.dart';
import 'package:ledger_master/features/bank_reconciliation/bank_repository.dart';

import '../../core/models/bank_transaction.dart';

class CSVImportRepository {
  final BankRepository _bankRepo = BankRepository();

  // IMPORT BANK STATEMENT CSV
  Future<void> importBankCSV(String filePath) async {
    final file = File(filePath);
    final content = await file.readAsString();
    final rows = const CsvToListConverter().convert(content, eol: '\n');

    for (var row in rows.skip(1)) {
      // Skip header
      final tx = BankTransaction(
        description: row[0].toString(),
        date: DateTime.parse(row[1].toString()),
        amount: double.parse(row[2].toString()),
        type: row[3].toString().toUpperCase(),
        cleared: false,
      );
      await _bankRepo.insertTransaction(tx);
    }
  }
}
