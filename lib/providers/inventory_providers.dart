import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_master/features/ledger/data/ledger_service.dart';
import 'package:ledger_master/models/ledger_entry.dart';

import '../../models/stock_item.dart';
import '../../models/stock_transaction.dart';

final inventoryNotifierProvider =
    StateNotifierProvider<InventoryNotifier, List<StockItem>>((ref) {
      final ledgerService = ref.watch(
        ledgerServiceProvider,
      ); // Existing Ledger service
      return InventoryNotifier(ledgerService: ledgerService);
    });

class InventoryNotifier extends StateNotifier<List<StockItem>> {
  final LedgerService ledgerService;
  InventoryNotifier({required this.ledgerService}) : super([]);

  void addStockTransaction(StockTransaction tx, {required StockItem item}) {
    // Update item quantity
    final updatedItem = item.copyWith(
      quantity:
          item.quantity +
          (tx.type == StockType.inwards ? tx.quantity : -tx.quantity),
    );
    state = [
      for (final i in state)
        if (i.id == item.id) updatedItem else i,
    ];

    // Sync with Ledger
    _syncLedger(tx, item);
  }

  Future<void> _syncLedger(StockTransaction tx, StockItem item) async {
    if (tx.type == StockType.inwards) {
      await ledgerService.createJournalEntry(
        description: "Stock IN: ${item.name}",
        lines: [
          LedgerLine(accountId: "Inventory", debit: tx.quantity * item.rate),
          LedgerLine(
            accountId: "Supplier/Cash",
            credit: tx.quantity * item.rate,
          ),
        ],
      );
    } else {
      // Stock OUT → reduce inventory, increase COGS
      await ledgerService.createJournalEntry(
        description: "Stock OUT: ${item.name}",
        lines: [
          LedgerLine(accountId: "COGS", debit: tx.quantity * item.rate),
          LedgerLine(accountId: "Inventory", credit: tx.quantity * item.rate),
        ],
      );
    }
  }
}
