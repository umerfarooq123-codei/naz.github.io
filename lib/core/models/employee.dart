class Employee {
  final int? id;
  final String name;
  final String position;
  final double basicSalary;

  Employee({
    this.id,
    required this.name,
    required this.position,
    required this.basicSalary,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'position': position,
      'basicSalary': basicSalary,
    };
  }

  factory Employee.fromMap(Map<String, dynamic> map) {
    return Employee(
      id: map['id'],
      name: map['name'],
      position: map['position'],
      basicSalary: map['basicSalary'],
    );
  }
}
