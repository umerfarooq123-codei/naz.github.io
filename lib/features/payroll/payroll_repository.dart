import '../../core/database/db_helper.dart';
import '../../core/models/employee.dart';
import '../../core/models/payroll.dart';

class PayrollRepository {
  final DBHelper _dbHelper = DBHelper();

  // EMPLOYEE CRUD
  Future<int> insertEmployee(Employee emp) async {
    final db = await _dbHelper.database;
    return await db.insert('employee', emp.toMap());
  }

  Future<List<Employee>> getAllEmployees() async {
    final db = await _dbHelper.database;
    final result = await db.query('employee', orderBy: 'name ASC');
    return result.map((e) => Employee.fromMap(e)).toList();
  }

  Future<int> updateEmployee(Employee emp) async {
    final db = await _dbHelper.database;
    return await db.update(
      'employee',
      emp.toMap(),
      where: 'id = ?',
      whereArgs: [emp.id],
    );
  }

  Future<int> deleteEmployee(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('employee', where: 'id = ?', whereArgs: [id]);
  }

  // PAYROLL CRUD
  Future<int> insertPayroll(Payroll payroll) async {
    final db = await _dbHelper.database;
    return await db.insert('payroll', payroll.toMap());
  }

  Future<List<Payroll>> getAllPayrolls() async {
    final db = await _dbHelper.database;
    final result = await db.query('payroll', orderBy: 'date DESC');
    return result.map((e) => Payroll.fromMap(e)).toList();
  }

  Future<int> updatePayroll(Payroll payroll) async {
    final db = await _dbHelper.database;
    return await db.update(
      'payroll',
      payroll.toMap(),
      where: 'id = ?',
      whereArgs: [payroll.id],
    );
  }

  Future<int> deletePayroll(int id) async {
    final db = await _dbHelper.database;
    return await db.delete('payroll', where: 'id = ?', whereArgs: [id]);
  }

  // AUTO-GENERATE PAYROLL ENTRY
  Future<int> generatePayroll(
    int employeeId,
    double allowances,
    double deductions,
    DateTime date,
  ) async {
    final db = await _dbHelper.database;
    final empMap = await db.query(
      'employee',
      where: 'id = ?',
      whereArgs: [employeeId],
    );
    if (empMap.isEmpty) throw Exception('Employee not found');
    final emp = Employee.fromMap(empMap.first);
    final netSalary = emp.basicSalary + allowances - deductions;

    final payroll = Payroll(
      employeeId: employeeId,
      date: date,
      basicSalary: emp.basicSalary,
      allowances: allowances,
      deductions: deductions,
      netSalary: netSalary,
    );
    return await insertPayroll(payroll);
  }
}
