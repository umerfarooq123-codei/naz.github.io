import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/providers/ledger_providers.dart';
import 'package:ledger_master/repositories/ledger_repository.dart';

final ledgerServiceProvider = Provider<LedgerService>((ref) {
  final repo = ref.watch(ledgerRepositoryProvider);
  return LedgerService(repo: repo);
});

class LedgerService {
  final LedgerRepository repo;
  LedgerService({required this.repo});

  Future<void> createJournalEntry({
    required String description,
    required List<LedgerLine> lines,
  }) async {
    final entry = LedgerEntry(
      id: "",
      date: DateTime.now(),
      description: description,
      lines: lines,
    );
    if (!entry.isBalanced()) {
      throw Exception("Journal entry not balanced");
    }
    await repo.createJournalEntry(entry);
  }
}
