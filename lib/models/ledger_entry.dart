import 'package:collection/collection.dart';

class LedgerLine {
  final String accountId;
  final double debit;
  final double credit;
  final String? narration;

  LedgerLine({
    required this.accountId,
    this.debit = 0.0,
    this.credit = 0.0,
    this.narration,
  }) : assert(debit >= 0.0),
       assert(credit >= 0.0);

  LedgerLine copyWith({
    String? accountId,
    double? debit,
    double? credit,
    String? narration,
  }) => LedgerLine(
    accountId: accountId ?? this.accountId,
    debit: debit ?? this.debit,
    credit: credit ?? this.credit,
    narration: narration ?? this.narration,
  );

  Map<String, dynamic> toJson() => {
    'accountId': accountId,
    'debit': debit,
    'credit': credit,
    'narration': narration,
  };

  factory LedgerLine.fromJson(Map<String, dynamic> json) => LedgerLine(
    accountId: json['accountId'] as String,
    debit: (json['debit'] ?? 0).toDouble(),
    credit: (json['credit'] ?? 0).toDouble(),
    narration: json['narration'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerLine &&
          runtimeType == other.runtimeType &&
          accountId == other.accountId &&
          debit == other.debit &&
          credit == other.credit &&
          narration == other.narration;

  @override
  int get hashCode =>
      accountId.hashCode ^
      debit.hashCode ^
      credit.hashCode ^
      (narration?.hashCode ?? 0);
}

class LedgerEntry {
  final String id;
  final DateTime date;
  final String description;
  final List<LedgerLine> lines;
  final Map<String, dynamic>? metadata;

  LedgerEntry({
    required this.id,
    required this.date,
    required this.description,
    required List<LedgerLine> lines,
    this.metadata,
  }) : lines = List.unmodifiable(lines) {
    assert(lines.isNotEmpty, 'A journal entry must have at least one line');
  }

  LedgerEntry copyWith({
    String? id,
    DateTime? date,
    String? description,
    List<LedgerLine>? lines,
    Map<String, dynamic>? metadata,
  }) => LedgerEntry(
    id: id ?? this.id,
    date: date ?? this.date,
    description: description ?? this.description,
    lines: lines ?? this.lines,
    metadata: metadata ?? this.metadata,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date.toIso8601String(),
    'description': description,
    'lines': lines.map((l) => l.toJson()).toList(),
    'metadata': metadata,
  };

  factory LedgerEntry.fromJson(Map<String, dynamic> json) => LedgerEntry(
    id: json['id'] as String,
    date: DateTime.parse(json['date'] as String),
    description: json['description'] as String,
    lines: (json['lines'] as List<dynamic>)
        .map((e) => LedgerLine.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    metadata: json['metadata'] as Map<String, dynamic>?,
  );

  double totalDebit() => lines.fold(0.0, (s, l) => s + l.debit);
  double totalCredit() => lines.fold(0.0, (s, l) => s + l.credit);

  bool isBalanced({double epsilon = 0.0001}) =>
      (totalDebit() - totalCredit()).abs() < epsilon;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LedgerEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          DeepCollectionEquality().equals(toJson(), other.toJson());

  @override
  int get hashCode => id.hashCode;
}
