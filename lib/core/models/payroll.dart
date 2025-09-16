class Payroll {
  final int? id;
  final int employeeId;
  final DateTime date;
  final double basicSalary;
  final double allowances;
  final double deductions;
  final double netSalary;

  Payroll({
    this.id,
    required this.employeeId,
    required this.date,
    required this.basicSalary,
    required this.allowances,
    required this.deductions,
    required this.netSalary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'basicSalary': basicSalary,
      'allowances': allowances,
      'deductions': deductions,
      'netSalary': netSalary,
    };
  }

  factory Payroll.fromMap(Map<String, dynamic> map) {
    return Payroll(
      id: map['id'],
      employeeId: map['employeeId'],
      date: DateTime.parse(map['date']),
      basicSalary: map['basicSalary'],
      allowances: map['allowances'],
      deductions: map['deductions'],
      netSalary: map['netSalary'],
    );
  }
}
