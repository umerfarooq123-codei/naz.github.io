import 'package:ledger_master/core/constants.dart';
import 'package:ledger_master/models/ledger_entry.dart';
import 'package:ledger_master/repositories/ledger_repository.dart';
import 'package:ledger_master/services/local_db/local_database.dart';
import 'package:sembast/sembast.dart';
import 'package:uuid/uuid.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  final StoreRef<int, Map<String, dynamic>> _store = intMapStoreFactory.store(
    AppConstants.ledgerStoreName,
  );
  final Database? _dbOverride;
  final _uuid = const Uuid();

  LedgerRepositoryImpl({Database? dbOverride}) : _dbOverride = dbOverride;

  Future<Database> get _db async =>
      _dbOverride ?? await LocalDatabase.openDatabase();

  @override
  Future<String> createJournalEntry(LedgerEntry entry) async {
    final db = await _db;
    final id = (entry.id.isEmpty) ? _uuid.v4() : entry.id;
    final payload = entry.copyWith(id: id).toJson();
    await _store.add(db, payload);
    return id;
  }

  Future<void> updateJournalEntry(LedgerEntry entry) async {
    final db = await _db;
    final finder = Finder(filter: Filter.equals('id', entry.id));
    await _store.update(db, entry.toJson(), finder: finder);
  }

  @override
  Future<List<LedgerEntry>> fetchEntries({
    DateTime? from,
    DateTime? to,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await _db;
    final filters = <Filter>[];
    if (from != null) {
      filters.add(Filter.greaterThanOrEquals('date', from.toIso8601String()));
    }
    if (to != null) {
      filters.add(Filter.lessThanOrEquals('date', to.toIso8601String()));
    }
    final finder = Finder(
      filter: filters.isNotEmpty ? Filter.and(filters) : null,
      sortOrders: [SortOrder('date', false)],
      limit: limit,
      offset: offset,
    );
    final records = await _store.find(db, finder: finder);
    return records.map((r) => LedgerEntry.fromJson(r.value)).toList();
  }

  Future<LedgerEntry?> getEntryById(String id) async {
    final db = await _db;
    final finder = Finder(filter: Filter.equals('id', id), limit: 1);
    final records = await _store.find(db, finder: finder);
    if (records.isEmpty) return null;
    return LedgerEntry.fromJson(records.first.value);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final db = await _db;
    final finder = Finder(filter: Filter.equals('id', id));
    await _store.delete(db, finder: finder);
  }
}
