import 'dart:async';

import 'package:ledger_master/core/constants.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast_io.dart';

class LocalDatabase {
  static Database? _db;

  LocalDatabase._();

  static Future<Database> openDatabase() async {
    if (_db != null) return _db!;

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = join(dir.path, AppConstants.dbFileName);

    _db = await databaseFactoryIo.openDatabase(dbPath);
    return _db!;
  }

  // Basic helpers
  static Future<int> insert(
    String storeName,
    Map<String, dynamic> value,
  ) async {
    final db = await openDatabase();
    final store = intMapStoreFactory.store(storeName);
    return await store.add(db, value);
  }

  static Future<void> update(
    String storeName,
    Finder finder,
    Map<String, dynamic> value,
  ) async {
    final db = await openDatabase();
    final store = intMapStoreFactory.store(storeName);
    await store.update(db, value, finder: finder);
  }

  static Future<List<RecordSnapshot<int, Map<String, dynamic>>>> findRecords(
    String storeName, {
    Finder? finder,
  }) async {
    final db = await openDatabase();
    final store = intMapStoreFactory.store(storeName);
    return await store.find(db, finder: finder);
  }

  static Future<void> delete(String storeName, Finder finder) async {
    final db = await openDatabase();
    final store = intMapStoreFactory.store(storeName);
    await store.delete(db, finder: finder);
  }
}
