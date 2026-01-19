import 'package:intl/intl.dart';

/// Base class for all exportable data models
abstract class ExportableData {
  /// Returns a map of field name to display name
  Map<String, String> getFieldMappings();

  /// Returns the data as a Map
  Map<String, dynamic> toExportMap();
}

/// Configuration for a column in export
class ExportColumnConfig {
  final String fieldName; // Field name in the data model
  final String displayName; // Display name in export
  final ExportDataType dataType;
  final String? dateFormat; // For DateTime fields
  final String? numberFormat; // For numeric fields
  final bool visible;

  ExportColumnConfig({
    required this.fieldName,
    required this.displayName,
    this.dataType = ExportDataType.string,
    this.dateFormat,
    this.numberFormat,
    this.visible = true,
  });
}

enum ExportDataType { string, number, date, boolean, currency }

/// Generic data extractor that works with any data model
class GenericDataExtractor<T extends ExportableData> {
  final List<ExportColumnConfig> columnConfigs;
  final DateFormat? defaultDateFormat;
  final NumberFormat? defaultNumberFormat;

  GenericDataExtractor({
    required this.columnConfigs,
    this.defaultDateFormat,
    this.defaultNumberFormat,
  });

  /// Extracts data from a list of exportable objects
  List<Map<String, dynamic>> extractData(List<T> data) {
    return data.map((item) {
      final exportMap = item.toExportMap();
      final processedMap = <String, dynamic>{};

      for (final config in columnConfigs.where((c) => c.visible)) {
        final rawValue = exportMap[config.fieldName];
        processedMap[config.fieldName] = _formatValue(
          rawValue,
          config.dataType,
          dateFormat: config.dateFormat,
          numberFormat: config.numberFormat,
        );
      }

      return processedMap;
    }).toList();
  }

  /// Gets the column headers for export
  List<String> getHeaders() {
    return columnConfigs
        .where((c) => c.visible)
        .map((c) => c.displayName)
        .toList();
  }

  /// Gets the field names for export
  List<String> getFieldNames() {
    return columnConfigs
        .where((c) => c.visible)
        .map((c) => c.fieldName)
        .toList();
  }

  dynamic _formatValue(
    dynamic value,
    ExportDataType dataType, {
    String? dateFormat,
    String? numberFormat,
  }) {
    if (value == null) return '';

    switch (dataType) {
      case ExportDataType.number:
      case ExportDataType.currency:
        return _formatNumber(value, numberFormat);
      case ExportDataType.date:
        return _formatDate(value, dateFormat);
      case ExportDataType.boolean:
        return value is bool ? value : value.toString().toLowerCase() == 'true';
      case ExportDataType.string:
        return value.toString();
    }
  }

  dynamic _formatNumber(dynamic value, String? format) {
    if (value == null) return '';

    try {
      final numValue = value is num ? value : double.tryParse(value.toString());
      if (numValue == null) return value.toString();

      if (format != null) {
        return NumberFormat(format).format(numValue);
      }

      return defaultNumberFormat?.format(numValue) ?? numValue;
    } catch (e) {
      return value.toString();
    }
  }

  dynamic _formatDate(dynamic value, String? format) {
    if (value == null) return '';

    try {
      DateTime date;
      if (value is DateTime) {
        date = value;
      } else if (value is String) {
        // Try common date formats
        date =
            DateTime.tryParse(value) ?? DateFormat('dd-MM-yyyy').parse(value);
      } else {
        return value.toString();
      }

      if (format != null) {
        return DateFormat(format).format(date);
      }

      return defaultDateFormat?.format(date) ?? date;
    } catch (e) {
      return value.toString();
    }
  }
}

/// Builder for creating extractor configurations easily
class DataExtractorBuilder<T extends ExportableData> {
  final List<ExportColumnConfig> _configs = [];

  DataExtractorBuilder<T> addColumn({
    required String fieldName,
    required String displayName,
    ExportDataType dataType = ExportDataType.string,
    String? dateFormat,
    String? numberFormat,
    bool visible = true,
  }) {
    _configs.add(
      ExportColumnConfig(
        fieldName: fieldName,
        displayName: displayName,
        dataType: dataType,
        dateFormat: dateFormat,
        numberFormat: numberFormat,
        visible: visible,
      ),
    );
    return this;
  }

  GenericDataExtractor<T> build({
    DateFormat? defaultDateFormat,
    NumberFormat? defaultNumberFormat,
  }) {
    return GenericDataExtractor<T>(
      columnConfigs: _configs,
      defaultDateFormat: defaultDateFormat,
      defaultNumberFormat: defaultNumberFormat,
    );
  }
}
