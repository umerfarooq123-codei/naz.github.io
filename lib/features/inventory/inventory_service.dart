import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/models/stock_item.dart';
import 'package:ledger_master/models/stock_transaction.dart';
import 'package:ledger_master/providers/ledger_providers.dart';

void createLedgerEntryFromStock(
  WidgetRef ref,
  StockTransaction tx,
  StockItem item,
) {
  final ledgerNotifier = ref.read(journalListNotifierProvider.notifier);

  if (tx.type == StockType.inwards) {
    // Stock purchased
    ledgerNotifier.createEntry(
      LedgerEntry(
        id: '',
        date: tx.date,
        description: "Purchase of ${item.name}",
        lines: [
          LedgerLine(
            accountId: "Inventory",
            debit: item.rate * tx.quantity,
            credit: 0,
          ),
          LedgerLine(
            accountId: "Cash/Bank",
            debit: 0,
            credit: item.rate * tx.quantity,
          ),
        ],
      ),
    );
  } else {
    // Stock sold
    ledgerNotifier.createEntry(
      LedgerEntry(
        id: '',
        date: tx.date,
        description: "Sale of ${item.name}",
        lines: [
          LedgerLine(
            accountId: "COGS",
            debit: item.rate * tx.quantity,
            credit: 0,
          ),
          LedgerLine(
            accountId: "Inventory",
            debit: 0,
            credit: item.rate * tx.quantity,
          ),
        ],
      ),
    );
  }
}
