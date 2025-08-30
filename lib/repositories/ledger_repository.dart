import 'package:ledger_master/models/ledger_entry.dart';

abstract class LedgerRepository {
  Future<String> createJournalEntry(LedgerEntry entry);
  Future<List<LedgerEntry>> fetchEntries({
    DateTime? from,
    DateTime? to,
    int limit = 100,
  });
  Future<void> deleteEntry(String id);
}
