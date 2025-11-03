// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReceiptItem {
  final String name;
  final double price;
  final int canQuantity;
  final String type;
  final String description;
  final double amount;

  ReceiptItem({
    required this.name,
    required this.price,
    required this.canQuantity,
    required this.type,
    required this.description,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'price': price,
      'canQuantity': canQuantity,
      'type': type,
      'description': description,
      'amount': amount,
    };
  }

  factory ReceiptItem.fromMap(Map<String, dynamic> map) {
    return ReceiptItem(
      name: map['name'] as String,
      price: map['price'] as double,
      canQuantity: map['canQuantity'] as int,
      type: map['type'] as String,
      description: map['description'] as String,
      amount: map['amount'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReceiptItem.fromJson(String source) =>
      ReceiptItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ReceiptData {
  final String companyName;
  final String date;
  final String customerName;
  final String customerAddress;
  final String vehicleNumber;
  final String voucherNumber;
  final List<ReceiptItem> items;
  final double previousCans;
  final double currentCans;
  final double totalCans;
  final double receivedCans;
  final double balanceCans;
  final double currentAmount;
  final double previousAmount;
  final double netBalance;

  ReceiptData({
    required this.companyName,
    required this.date,
    required this.customerName,
    required this.customerAddress,
    required this.vehicleNumber,
    required this.voucherNumber,
    required this.items,
    required this.previousCans,
    required this.currentCans,
    required this.totalCans,
    required this.receivedCans,
    required this.balanceCans,
    required this.currentAmount,
    required this.previousAmount,
    required this.netBalance,
  }) {
    // Data validation
    if (items.isEmpty) throw ArgumentError('Items list cannot be empty');
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'companyName': companyName,
      'date': date,
      'customerName': customerName,
      'customerAddress': customerAddress,
      'vehicleNumber': vehicleNumber,
      'voucherNumber': voucherNumber,
      'items': items.map((x) => x.toMap()).toList(),
      'previousCans': previousCans,
      'currentCans': currentCans,
      'totalCans': totalCans,
      'receivedCans': receivedCans,
      'balanceCans': balanceCans,
      'currentAmount': currentAmount,
      'previousAmount': previousAmount,
      'netBalance': netBalance,
    };
  }

  factory ReceiptData.fromMap(Map<String, dynamic> map) {
    return ReceiptData(
      companyName: map['companyName'] as String,
      date: map['date'] as String,
      customerName: map['customerName'] as String,
      customerAddress: map['customerAddress'] as String,
      vehicleNumber: map['vehicleNumber'] as String,
      voucherNumber: map['voucherNumber'] as String,
      items: List<ReceiptItem>.from(
        (map['items'] as List<int>).map<ReceiptItem>(
          (x) => ReceiptItem.fromMap(x as Map<String, dynamic>),
        ),
      ),
      previousCans: map['previousCans'] as double,
      currentCans: map['currentCans'] as double,
      totalCans: map['totalCans'] as double,
      receivedCans: map['receivedCans'] as double,
      balanceCans: map['balanceCans'] as double,
      currentAmount: map['currentAmount'] as double,
      previousAmount: map['previousAmount'] as double,
      netBalance: map['netBalance'] as double,
    );
  }

  String toJson() => json.encode(toMap());

  factory ReceiptData.fromJson(String source) =>
      ReceiptData.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ReceiptStyles {
  static const PdfColor black = PdfColors.black;
  static const PdfColor white = PdfColors.white;
  static const double fontSizeSmall = 8.0;
  static const double fontSizeNormal = 8.0;
  static const double fontSizeHeader = 14.0;
  static const double fontSizeTitle = 12.0;
  static const double padding =
      4.0; // Reduced padding for table rows as per "4 padding"
  static const double margin = 6.0;

  // Font loading with error handling
  static Future<pw.Font> loadMontserratRegular() async {
    try {
      final byteData = await rootBundle.load(
        'assets/fonts/Montserrat-Regular.ttf',
      );
      return pw.Font.ttf(byteData);
    } catch (e) {
      return pw.Font.times(); // Fallback to Times for better Unicode support
    }
  }

  static Future<pw.Font> loadMontserratBold() async {
    try {
      final byteData = await rootBundle.load(
        'assets/fonts/Montserrat-Bold.ttf',
      );
      return pw.Font.ttf(byteData);
    } catch (e) {
      return pw.Font.timesBold(); // Fallback to Times Bold
    }
  }

  // TextStyle getters to ensure Montserrat fonts are used
  static Future<pw.TextStyle> getTitleStyle() async {
    final montserratBold = await loadMontserratBold();
    return pw.TextStyle(
      font: montserratBold,
      fontSize: fontSizeTitle,
      fontWeight: pw.FontWeight.bold,
    );
  }

  static Future<pw.TextStyle> getHeaderStyle() async {
    final montserratBold = await loadMontserratBold();
    return pw.TextStyle(
      font: montserratBold,
      fontSize: fontSizeHeader,
      fontWeight: pw.FontWeight.bold,
    );
  }

  static Future<pw.TextStyle> getNormalStyle() async {
    final montserratRegular = await loadMontserratRegular();
    return pw.TextStyle(font: montserratRegular, fontSize: fontSizeNormal);
  }

  static Future<pw.TextStyle> getSmallStyle() async {
    final montserratRegular = await loadMontserratRegular();
    return pw.TextStyle(font: montserratRegular, fontSize: fontSizeSmall);
  }

  static Future<pw.TextStyle> getBoldStyle() async {
    final montserratBold = await loadMontserratBold();
    return pw.TextStyle(
      font: montserratBold,
      fontSize: fontSizeNormal,
      fontWeight: pw.FontWeight.bold,
    );
  }

  static pw.TableBorder get tableBorder =>
      pw.TableBorder.all(color: black, width: 1.0);
}

class ReceiptPdfGenerator {
  /// Number formatter for thousands separators.
  static final NumberFormat _commaFormatter = NumberFormat('#,##0.##');

  /// Formats a double/int with comma separators and removes .0/.00
  static String formatNumber(num value) {
    return _commaFormatter.format(value);
  }

  /// Loads the logo image from assets with error handling.
  static Future<pw.MemoryImage> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/images/icon.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (e) {
      return pw.MemoryImage(Uint8List.fromList([])); // Empty image as fallback
    }
  }

  /// Builds a single receipt content widget with all items in one centered table.
  static Future<pw.Widget> _buildReceiptContent(
    ReceiptData data,
    pw.TextStyle titleStyle,
    pw.TextStyle normalStyle,
    pw.TextStyle smallStyle,
    pw.TextStyle boldStyle,
    pw.MemoryImage logo,
  ) async {
    // Helper function to create a signature line
    pw.Widget signatureLine(String label, {bool isLeft = false}) {
      return pw.Expanded(
        flex: isLeft ? 1 : 1,
        child: pw.Padding(
          padding: const pw.EdgeInsets.only(top: 20),
          child: pw.Column(
            crossAxisAlignment: isLeft
                ? pw.CrossAxisAlignment.start
                : pw.CrossAxisAlignment.end,
            children: [
              pw.Container(width: 150, height: 1, color: ReceiptStyles.black),
              pw.SizedBox(height: 5),
              pw.Text(label, style: boldStyle),
            ],
          ),
        ),
      );
    }

    // Header: Company details, customer info, and logo
    final header = pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: 400,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Text('Voucher No: ', style: boldStyle),
                  pw.Text(data.voucherNumber, style: normalStyle),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text('Date: ', style: boldStyle),
                      pw.Text(data.date, style: normalStyle),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Text('Cust. Name: ', style: boldStyle),
                      pw.Text(data.customerName, style: normalStyle),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Text('Cust. Address: ', style: boldStyle),
                      pw.Expanded(
                        child: pw.Text(
                          data.customerAddress,
                          style: normalStyle,
                          softWrap: true,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 3),
                  pw.Row(
                    children: [
                      pw.Text('Vehicle No: ', style: boldStyle),
                      pw.Text(data.vehicleNumber, style: normalStyle),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.Container(
          width: 160,
          height: 160,
          child: logo.bytes.isNotEmpty
              ? pw.Image(logo, fit: pw.BoxFit.contain)
              : pw.Center(child: pw.Text('LOGO', style: smallStyle)),
        ),
      ],
    );

    // Items table
    final List<pw.TableRow> tableRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          buildTableCell('Item', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Price', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Can Qty', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Type', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Description', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Amount', isHeader: true, boldStyle: boldStyle),
        ],
      ),
    ];

    for (final item in data.items) {
      tableRows.add(
        pw.TableRow(
          children: [
            buildTableCell(item.name, normalStyle: normalStyle),
            buildTableCell(formatNumber(item.price), normalStyle: normalStyle),
            buildTableCell(
              formatNumber(item.canQuantity),
              normalStyle: normalStyle,
            ),
            buildTableCell(item.type, normalStyle: normalStyle),
            buildTableCell(item.description, normalStyle: normalStyle),
            buildTableCell(formatNumber(item.amount), normalStyle: normalStyle),
          ],
        ),
      );
    }

    final itemsTable = pw.Table(
      border: ReceiptStyles.tableBorder,
      children: tableRows,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      columnWidths: {
        0: pw.FlexColumnWidth(0.8),
        1: pw.FlexColumnWidth(0.5),
        2: pw.FlexColumnWidth(0.4),
        3: pw.FlexColumnWidth(0.4),
        4: pw.FlexColumnWidth(2.6),
        5: pw.FlexColumnWidth(0.6),
      },
    );

    // Cans table
    final List<pw.TableRow> canTableRows = [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: PdfColors.grey200),
        children: [
          buildTableCell('Previous Cans', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Current Cans', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Total Cans', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Received Cans', isHeader: true, boldStyle: boldStyle),
          buildTableCell('Balance Cans', isHeader: true, boldStyle: boldStyle),
        ],
      ),
      pw.TableRow(
        children: [
          buildTableCell(
            formatNumber(data.previousCans),
            normalStyle: normalStyle,
          ),
          buildTableCell(
            formatNumber(data.currentCans),
            normalStyle: normalStyle,
          ),
          buildTableCell(
            formatNumber(data.totalCans),
            normalStyle: normalStyle,
          ),
          buildTableCell(
            formatNumber(data.receivedCans),
            normalStyle: normalStyle,
          ),
          buildTableCell(
            formatNumber(data.balanceCans),
            normalStyle: normalStyle,
          ),
        ],
      ),
    ];

    final cansTable = pw.Table(
      border: ReceiptStyles.tableBorder,
      children: canTableRows,
      columnWidths: {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1),
      },
    );

    // Footer totals
    final footer = pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Container(
            width: 150,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Previous Amount:', style: boldStyle),
                pw.SizedBox(width: 5),
                pw.Text(formatNumber(data.previousAmount), style: normalStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(
            width: 150,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.end,
              children: [
                pw.Text('Current Amount:', style: boldStyle),
                pw.SizedBox(width: 5),
                pw.Text(formatNumber(data.currentAmount), style: normalStyle),
              ],
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 150,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Text('Net Balance:', style: boldStyle),
                    pw.SizedBox(width: 5),
                    pw.Text(formatNumber(data.netBalance), style: normalStyle),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Row(
            children: [
              signatureLine('Receiver Signature', isLeft: true),
              pw.Spacer(),
              signatureLine('Auth Signature'),
            ],
          ),
        ],
      ),
    );

    return pw.Stack(
      children: [
        pw.Positioned.fill(
          child: pw.Center(
            child: pw.Transform.rotate(
              angle: 0.5,
              child: pw.Text(
                'PAYMENT RECEIPT',
                style: boldStyle.copyWith(
                  color: PdfColors.grey400,
                  fontSize: 50,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            header,
            pw.SizedBox(height: 10),
            pw.Center(child: itemsTable),
            pw.SizedBox(height: 10),
            pw.Center(child: cansTable),
            footer,
          ],
        ),
      ],
    );
  }

  static Future<pw.Document> buildPdf(ReceiptData data) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    final titleStyle = await ReceiptStyles.getTitleStyle();
    final normalStyle = await ReceiptStyles.getNormalStyle();
    final smallStyle = await ReceiptStyles.getSmallStyle();
    final boldStyle = await ReceiptStyles.getBoldStyle();

    final officeCopy = await _buildReceiptContent(
      data,
      titleStyle,
      normalStyle,
      smallStyle,
      boldStyle,
      logo,
    );
    final receiverCopy = await _buildReceiptContent(
      data,
      titleStyle,
      normalStyle,
      smallStyle,
      boldStyle,
      logo,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(ReceiptStyles.margin),
        build: (pw.Context context) {
          return pw.ConstrainedBox(
            constraints: pw.BoxConstraints(
              maxWidth: PdfPageFormat.a4.width - 2 * ReceiptStyles.margin,
              maxHeight: PdfPageFormat.a4.height - 2 * ReceiptStyles.margin,
            ),
            child: pw.Column(
              children: [
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Stack(
                      children: [
                        officeCopy,
                        pw.Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: pw.Align(
                            alignment: pw.Alignment.bottomCenter,
                            child: pw.Text('Office Copy', style: smallStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                pw.Container(
                  width: double.infinity,
                  margin: const pw.EdgeInsets.symmetric(vertical: 4),
                  child: pw.Container(
                    height: 1,
                    decoration: pw.BoxDecoration(
                      border: pw.Border(
                        bottom: pw.BorderSide(
                          color: ReceiptStyles.black,
                          width: 1,
                          style: pw.BorderStyle.dashed,
                        ),
                      ),
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Stack(
                      children: [
                        receiverCopy,
                        pw.Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: pw.Align(
                            alignment: pw.Alignment.bottomCenter,
                            child: pw.Text('Receiver Copy', style: smallStyle),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    return pdf;
  }

  static pw.Widget buildTableCell(
    String text, {
    bool isHeader = false,
    pw.Alignment alignment = pw.Alignment.center,
    pw.TextStyle? boldStyle,
    pw.TextStyle? normalStyle,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(ReceiptStyles.padding),
      alignment: alignment,
      child: pw.Text(
        text,
        style: isHeader ? boldStyle : normalStyle,
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<String> saveToTempFile(ReceiptData data) async {
    final pdf = await buildPdf(data);
    final Uint8List bytes = await pdf.save();
    final Directory tempDir = await getTemporaryDirectory();
    final String filePath =
        '${tempDir.path}/receipt_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final File file = File(filePath);
    await file.writeAsBytes(bytes);
    return filePath;
  }

  static Future<void> printPdf(ReceiptData data) async {
    final pdf = await buildPdf(data);
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => await pdf.save(),
    );
  }

  static Future<void> generateAndPrint(ReceiptData data) async {
    await saveToTempFile(data);
    await printPdf(data);
  }
}
