// lib/core/export/desktop_export_service.dart - COMPLETE FIXED VERSION
import 'dart:io';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' hide Column, Row;
import 'package:universal_platform/universal_platform.dart';

import 'generic_data_extractor.dart';

class DesktopExportService {
  /// Generic export method for any ExportableData
  static Future<void> exportData<T extends ExportableData>({
    required BuildContext context,
    required List<T> data,
    required GenericDataExtractor<T> extractor,
    required String defaultFileName,
    required String fileType,
  }) async {
    try {
      if (data.isEmpty) {
        showMessage(context, 'No data to export', isError: false);
        return;
      }

      // Extract data using the generic extractor
      final extractedData = extractor.extractData(data);
      final headers = extractor.getHeaders();
      final fieldNames = extractor.getFieldNames();

      if (fileType.toLowerCase() == 'csv') {
        await exportAsCsv(
          extractedData: extractedData,
          columns: fieldNames,
          headers: headers,
          defaultFileName: defaultFileName,
          context: context,
        );
      } else if (fileType.toLowerCase() == 'excel' ||
          fileType.toLowerCase() == 'xlsx') {
        await exportAsExcel(
          extractedData: extractedData,
          columns: fieldNames,
          headers: headers,
          defaultFileName: defaultFileName,
          context: context,
        );
      } else {
        showMessage(context, 'Unsupported file type: $fileType', isError: true);
      }
    } catch (e) {
      showMessage(context, 'Export failed: $e', isError: true);
    }
  }

  static Future<void> exportAsCsv({
    required List<Map<String, dynamic>> extractedData,
    required List<String> columns,
    required List<String> headers,
    required String defaultFileName,
    required BuildContext context,
  }) async {
    // Build CSV content
    final csvContent = StringBuffer();

    // Headers
    csvContent.write(headers.map((h) => escapeCsvField(h)).join(','));
    csvContent.write('\n');

    // Data rows
    for (final row in extractedData) {
      final values = columns.map((col) {
        final value = row[col];
        return escapeCsvField(formatValueForCsv(value));
      }).toList();
      csvContent.write(values.join(','));
      csvContent.write('\n');
    }

    // Convert to bytes
    final bytes = Uint8List.fromList(csvContent.toString().codeUnits);

    // Save file
    await saveFile(
      bytes: bytes,
      fileName: '$defaultFileName.csv',
      context: context,
    );
  }

  static Future<void> exportAsExcel({
    required List<Map<String, dynamic>> extractedData,
    required List<String> columns,
    required List<String> headers,
    required String defaultFileName,
    required BuildContext context,
  }) async {
    // Create Excel workbook
    final Workbook workbook = Workbook();
    final Worksheet sheet = workbook.worksheets[0];
    sheet.name = 'Data Export';

    // Apply styling
    final Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.backColor = '#2C3E50'; // Dark blue
    headerStyle.fontColor = '#FFFFFF'; // White text
    headerStyle.fontName = 'Calibri';
    headerStyle.fontSize = 11;
    headerStyle.bold = true;
    headerStyle.hAlign = HAlignType.center;
    headerStyle.vAlign = VAlignType.center;

    // Write headers with styling
    for (int i = 0; i < headers.length; i++) {
      final range = sheet.getRangeByIndex(1, i + 1);
      range.setText(headers[i]);
      range.cellStyle = headerStyle;
    }

    // Write data
    for (int rowIndex = 0; rowIndex < extractedData.length; rowIndex++) {
      final row = extractedData[rowIndex];
      for (int colIndex = 0; colIndex < columns.length; colIndex++) {
        final range = sheet.getRangeByIndex(rowIndex + 2, colIndex + 1);
        final value = row[columns[colIndex]];
        setCellValue(range, value);
      }
    }

    // Auto-fit columns for better readability
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }

    // Add borders to all cells
    final Range dataRange = sheet.getRangeByIndex(
      1,
      1,
      extractedData.length + 1,
      headers.length,
    );
    final Style borderStyle = workbook.styles.add('BorderStyle');
    borderStyle.borders.all.lineStyle = LineStyle.thin;
    borderStyle.borders.all.color = '#BDC3C7'; // Light gray
    dataRange.cellStyle = borderStyle;

    // Alternate row coloring for better readability
    final Style altRowStyle = workbook.styles.add('AltRowStyle');
    altRowStyle.backColor = '#F8F9FA'; // Very light gray

    for (int i = 2; i <= extractedData.length + 1; i += 2) {
      final altRowRange = sheet.getRangeByIndex(i, 1, i, headers.length);
      altRowRange.cellStyle = altRowStyle;
    }

    // Save workbook to bytes
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();

    // Save file
    await saveFile(
      bytes: Uint8List.fromList(bytes),
      fileName: '$defaultFileName.xlsx',
      context: context,
    );
  }

  static void setCellValue(Range cell, dynamic value) {
    if (value == null) {
      cell.setText('');
    } else if (value is num) {
      cell.setNumber(value.toDouble());
      // Apply number formatting for better readability
      if (value is double && value.toString().contains('.')) {
        cell.numberFormat = '#,##0.00';
      } else {
        cell.numberFormat = '#,##0';
      }
    } else if (value is DateTime) {
      cell.setDateTime(value);
      cell.numberFormat = 'dd-mm-yyyy';
      cell.cellStyle.hAlign = HAlignType.center;
    } else if (value is bool) {
      // Use text for boolean values
      cell.setText(value ? 'Yes' : 'No');
      cell.cellStyle.hAlign = HAlignType.center;
    } else {
      cell.setText(value.toString());
    }
  }

  static String formatValueForCsv(dynamic value) {
    if (value == null) return '';
    if (value is DateTime) {
      return DateFormat('yyyy-MM-dd').format(value);
    }
    if (value is num) {
      // Format numbers with 2 decimal places
      if (value is double) {
        return value.toStringAsFixed(2);
      }
      return value.toString();
    }
    if (value is bool) {
      return value ? 'Yes' : 'No';
    }
    return value.toString();
  }

  static String escapeCsvField(String field) {
    if (field.contains(',') ||
        field.contains('\n') ||
        field.contains('\r') ||
        field.contains('"')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  // SIMPLIFIED AND CORRECT saveFile method:
  static Future<void> saveFile({
    required Uint8List bytes,
    required String fileName,
    required BuildContext context,
  }) async {
    try {
      final fileExtension = fileName.split('.').last.toLowerCase();

      if (UniversalPlatform.isDesktop) {
        // Desktop: Use FileSaver
        try {
          await FileSaver.instance.saveFile(
            name: fileName,
            bytes: bytes,
            mimeType: getMimeType(fileExtension),
          );

          if (context.mounted) {
            showMessage(context, 'File saved: $fileName', isError: false);
          }
        } catch (e) {
          // Fallback to documents directory
          final directory = await getApplicationDocumentsDirectory();
          final filePath = path.join(directory.path, fileName);
          await File(filePath).writeAsBytes(bytes);

          if (context.mounted) {
            showMessage(context, 'File saved to: $filePath', isError: false);
          }
        }
      } else {
        // Mobile/Web: Save to temp and share using static Share methods
        final tempDir = await getTemporaryDirectory();
        final tempPath = path.join(tempDir.path, fileName);
        await File(tempPath).writeAsBytes(bytes);

        if (context.mounted) {
          final xFile = XFile(
            tempPath,
            mimeType: getMimeTypeString(fileExtension),
          );

          // Use the static Share class methods (not SharePlus.instance)
          await Share.shareXFiles([xFile], text: 'Export: $fileName');

          showMessage(context, 'File shared successfully', isError: false);
        }
      }
    } catch (e) {
      if (context.mounted) {
        showMessage(context, 'Failed to save file: $e', isError: true);
      }
    }
  }

  static MimeType getMimeType(String fileExtension) {
    switch (fileExtension) {
      case 'csv':
        return MimeType.csv;
      case 'xlsx':
      case 'xls':
        return MimeType.microsoftExcel;
      case 'pdf':
        return MimeType.pdf;
      default:
        return MimeType.other;
    }
  }

  static String getMimeTypeString(String fileExtension) {
    switch (fileExtension) {
      case 'csv':
        return 'text/csv';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'xls':
        return 'application/vnd.ms-excel';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  static void showMessage(
    BuildContext context,
    String message, {
    required bool isError,
  }) {
    final snackBar = SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Helper method to generate a timestamp for file names
  static String generateTimestamp() {
    return DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
  }

  /// Helper method to get default export file name
  static String getDefaultFileName(String baseName) {
    return '${baseName}_${generateTimestamp()}';
  }

  /// Export dialog helper to show options to user
  static Future<void> showExportDialog<T extends ExportableData>({
    required BuildContext context,
    required List<T> data,
    required GenericDataExtractor<T> extractor,
    required String baseFileName,
    String title = 'Export Data',
  }) async {
    final selectedFormat = ValueNotifier<String>('excel');

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select export format:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                // Use ValueListenableBuilder for the new Radio API
                ValueListenableBuilder<String>(
                  valueListenable: selectedFormat,
                  builder: (context, format, child) {
                    return Column(
                      children: [
                        RadioMenuButton<String>(
                          value: 'excel',
                          groupValue: format,
                          onChanged: (value) => selectedFormat.value = value!,
                          child: const Text('Excel (.xlsx)'),
                        ),
                        RadioMenuButton<String>(
                          value: 'csv',
                          groupValue: format,
                          onChanged: (value) => selectedFormat.value = value!,
                          child: const Text('CSV (.csv)'),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Preview info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Export Summary:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text('• ${extractor.getHeaders().length} columns'),
                      Text('• ${data.length} records'),
                      ValueListenableBuilder<String>(
                        valueListenable: selectedFormat,
                        builder: (context, format, child) {
                          return Text(
                            '• File: ${baseFileName}_${generateTimestamp()}.${format == 'excel' ? 'xlsx' : 'csv'}',
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final format = selectedFormat.value;
                Navigator.pop(context);
                await exportData(
                  context: context,
                  data: data,
                  extractor: extractor,
                  defaultFileName: '${baseFileName}_${generateTimestamp()}',
                  fileType: format,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Export',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }
}
