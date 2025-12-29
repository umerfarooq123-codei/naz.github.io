import 'package:ledger_master/core/database/db_helper.dart';
import 'package:ledger_master/core/models/cans.dart';

class CansRepository {
  final DBHelper _dbHelper = DBHelper();

  /// Fetch all cans tables
  Future<List<Cans>> getAllCans() async {
    final db = await _dbHelper.database;
    final maps = await db.query('cans');
    return maps.map((map) => Cans.fromMap(map)).toList();
  }

  /// Fetch a single cans table by ID
  Future<Cans?> getCansById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query('cans', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Cans.fromMap(maps.first);
    }
    return null;
  }

  /// Add a new cans table
  Future<int> addCans(Cans cans) async {
    final db = await _dbHelper.database;
    return await db.insert('cans', cans.toMap());
  }

  /// Update an existing cans table
  Future<int> updateCans(Cans cans) async {
    final db = await _dbHelper.database;
    return await db.update(
      'cans',
      cans.toMap(),
      where: 'id = ?',
      whereArgs: [cans.id],
    );
  }

  /// Delete a cans table
  Future<int> deleteCans(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('cans', where: 'id = ?', whereArgs: [id]);
  }

  /// Fetch all entries for a specific cans table
  Future<List<CansEntry>> getCansEntriesByCansId(int cansId) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'cans_entries',
      where: 'cansId = ?',
      whereArgs: [cansId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => CansEntry.fromMap(map)).toList();
  }

  /// Add a new cans entry
  Future<int> addCansEntry(CansEntry entry) async {
    final db = await _dbHelper.database;
    return await db.insert('cans_entries', entry.toMap());
  }

  /// Update an existing cans entry
  Future<int> updateCansEntry(CansEntry entry) async {
    final db = await _dbHelper.database;
    return await db.update(
      'cans_entries',
      entry.toMap(),
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  /// Delete a cans entry
  Future<int> deleteCansEntry(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('cans_entries', where: 'id = ?', whereArgs: [id]);
  }
}
