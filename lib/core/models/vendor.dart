class Vendor {
  final int? id;
  final String name;
  final String contact;
  final double dues;

  Vendor({
    this.id,
    required this.name,
    required this.contact,
    required this.dues,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'contact': contact, 'dues': dues};
  }

  factory Vendor.fromMap(Map<String, dynamic> map) {
    return Vendor(
      id: map['id'],
      name: map['name'],
      contact: map['contact'],
      dues: map['dues'],
    );
  }
}
