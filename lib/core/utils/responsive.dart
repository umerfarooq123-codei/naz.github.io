import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class Responsive {
  static Widget builder({required Widget child}) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, childWidget) => childWidget!,
      child: child,
    );
  }
}

/// ScrollBehavior that does NOT build any scrollbar widget.
class NoScrollbarBehavior extends ScrollBehavior {
  const NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // return the child directly so no scrollbar is drawn
    return child;
  }

  // allow mouse wheel & touch scrolling on desktop
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.unknown,
  };
}

// Required import
// CUSTOM COLUMN SIZER
class LedgerColumnSizer extends ColumnSizer {
  final List<dynamic>
  entries; // your ledger entry model list (RxList -> toList())
  final double maxColumnWidth;
  final double extraHorizontalPadding;
  final NumberFormat numberFormat;

  LedgerColumnSizer({
    required this.entries,
    this.maxColumnWidth = 600.0,
    this.extraHorizontalPadding = 24.0,
    NumberFormat? numberFormat,
  }) : numberFormat = numberFormat ?? NumberFormat('#,##0.##');

  // header width (we keep default behaviour but add cap)
  @override
  double computeHeaderCellWidth(GridColumn column, TextStyle style) {
    final double w = super.computeHeaderCellWidth(column, style);
    return math.min(w + extraHorizontalPadding, maxColumnWidth);
  }

  // cell width calculation — here we can format numbers and apply rules
  @override
  double computeCellWidth(
    GridColumn column,
    DataGridRow row,
    Object? cellValue,
    TextStyle textStyle,
  ) {
    final String col = column.columnName;
    String display;

    // turn the raw cellValue into the string we'd actually display in UI
    if (cellValue == null) {
      display = '';
    } else if (_isNumericColumn(col)) {
      // Some columns contain numbers but might come as String or num; format them
      final num? parsed = _tryParseNum(cellValue);
      display = parsed == null
          ? cellValue.toString()
          : numberFormat.format(parsed);
    } else if (col == 'date') {
      // format date value if needed - attempt to parse DateTime then format
      if (cellValue is DateTime) {
        display = DateFormat('dd/MM/yyyy').format(cellValue);
      } else {
        display = cellValue.toString();
      }
    } else {
      display = cellValue.toString();
    }

    // Special rule for 'canqty': if all rows have 0 -> measure as single '0'
    if (col == 'canqty') {
      final bool allZero =
          entries.isNotEmpty &&
          entries.every((e) {
            try {
              final dynamic v = _valueFromEntry(e, 'canqty');
              return (_tryParseNum(v) ?? 0) == 0;
            } catch (_) {
              return false;
            }
          });
      if (allZero) {
        display = '0';
      }
    }

    // Let the base class compute width for the provided display value (super accepts any cellValue)
    final double measured = super.computeCellWidth(
      column,
      row,
      display,
      textStyle,
    );

    // Add a little horizontal padding and cap the width
    return math.min(measured + extraHorizontalPadding, maxColumnWidth);
  }

  // Helper: which columns should be treated as numeric
  bool _isNumericColumn(String columnName) {
    const numericCols = <String>{
      'priceperkg',
      'canqty',
      'reccans',
      'canweight',
      'debit',
      'credit',
      'balance',
    };
    return numericCols.contains(columnName);
  }

  // Try to parse numbers cleanly (handles String or num)
  num? _tryParseNum(Object? v) {
    if (v == null) return null;
    if (v is num) return v;
    final s = v.toString().replaceAll(',', '');
    return num.tryParse(s);
  }

  // small helper to access a field by column name from the entry.
  // Adjust this to match your LedgerEntry fields (same mapping used in DataGridSource).
  dynamic _valueFromEntry(dynamic entry, String columnName) {
    // If your LedgerEntry is a Map:
    if (entry is Map) {
      return entry[columnName];
    }

    // Otherwise try expected properties — tweak to match your model class
    switch (columnName) {
      case 'voucherNo':
        return entry.voucherNo;
      case 'date':
        return entry.date;
      case 'item':
        return entry.item ?? entry.name ?? entry.product;
      case 'priceperkg':
        return entry.priceperkg ?? entry.price;
      case 'canqty':
        return entry.cansQuantity ?? entry.canqty ?? entry.cans;
      case 'reccans':
        return entry.receivedCans ?? entry.reccans;
      case 'canweight':
        return entry.canWeight ?? entry.canweight;
      case 'transactionType':
        return entry.transactionType ?? entry.type;
      case 'description':
        return entry.description;
      case 'referenceNo':
        return entry.referenceNo ?? entry.refNo;
      case 'createdBy':
        return entry.createdBy;
      case 'debit':
        return entry.debit;
      case 'credit':
        return entry.credit;
      case 'balance':
        return entry.balance;
      default:
        // fallback: try toString if property not found
        try {
          return entry.toString();
        } catch (_) {
          return '';
        }
    }
  }
}
