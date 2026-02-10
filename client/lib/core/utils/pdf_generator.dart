import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../data/models/report_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/transaction_item_model.dart';
import '../constants/app_constants.dart';
import '../constants/enums.dart';
import 'formatters.dart';

/// PDF Generator for receipts and reports
class PdfGenerator {
  PdfGenerator._();

  // ==================== FONTS ====================

  static pw.Font? _regularFont;
  static pw.Font? _boldFont;
  static pw.Font? _sinhalaFont;

  /// Initialize fonts
  static Future<void> initializeFonts() async {
    try {
      // Load fonts from assets
      final regularData =
          await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Poppins-Bold.ttf');

      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);

      // Try to load Sinhala font
      try {
        final sinhalaData =
            await rootBundle.load('assets/fonts/NotoSansSinhala-Regular.ttf');
        _sinhalaFont = pw.Font.ttf(sinhalaData);
      } catch (_) {
        // Sinhala font not available
      }
    } catch (e) {
      // Use default fonts if custom fonts fail
      _regularFont = pw.Font.helvetica();
      _boldFont = pw.Font.helveticaBold();
    }
  }

  /// Get text style
  static pw.TextStyle _getTextStyle({
    double fontSize = 12,
    bool bold = false,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      font: bold
          ? (_boldFont ?? pw.Font.helveticaBold())
          : (_regularFont ?? pw.Font.helvetica()),
      fontSize: fontSize,
      color: color ?? PdfColors.black,
    );
  }

  // ==================== RECEIPT GENERATION ====================

  /// Generate transaction receipt
  static Future<Uint8List> generateReceipt({
    required TransactionModel transaction,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyLogo,
    String? footerText,
  }) async {
    await initializeFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildReceiptHeader(
                companyName: companyName ?? AppConstants.appName,
                companyAddress: companyAddress,
                companyPhone: companyPhone,
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 16),

              // Transaction Info
              _buildTransactionInfo(transaction),
              pw.SizedBox(height: 16),

              // Customer Info
              if (transaction.customerName != null)
                _buildCustomerInfo(
                  name: transaction.customerName!,
                  phone: transaction.customerPhone,
                ),
              pw.SizedBox(height: 16),

              // Items Table
              _buildItemsTable(transaction.items),
              pw.SizedBox(height: 16),

              // Summary
              _buildReceiptSummary(transaction),
              pw.SizedBox(height: 24),

              // Footer
              _buildReceiptFooter(footerText),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Build receipt header
  static pw.Widget _buildReceiptHeader({
    required String companyName,
    String? companyAddress,
    String? companyPhone,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          companyName,
          style: _getTextStyle(fontSize: 20, bold: true),
        ),
        if (companyAddress != null) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            companyAddress,
            style: _getTextStyle(fontSize: 10),
            textAlign: pw.TextAlign.center,
          ),
        ],
        if (companyPhone != null) ...[
          pw.SizedBox(height: 2),
          pw.Text(
            'Tel: $companyPhone',
            style: _getTextStyle(fontSize: 10),
          ),
        ],
      ],
    );
  }

  /// Build transaction info section
  static pw.Widget _buildTransactionInfo(TransactionModel transaction) {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Receipt No:',
              style: _getTextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              transaction.transactionId,
              style: _getTextStyle(fontSize: 12, bold: true),
            ),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Date:',
              style: _getTextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
            pw.Text(
              dateFormat.format(transaction.transactionDate),
              style: _getTextStyle(fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  /// Build customer info section
  static pw.Widget _buildCustomerInfo({
    required String name,
    String? phone,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Row(
        children: [
          pw.Text('Customer: ', style: _getTextStyle(fontSize: 10)),
          pw.Text(name, style: _getTextStyle(fontSize: 10, bold: true)),
          if (phone != null) ...[
            pw.Text(' | ', style: _getTextStyle(fontSize: 10)),
            pw.Text(Formatters.phone(phone),
                style: _getTextStyle(fontSize: 10)),
          ],
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<TransactionItemModel> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('#', isHeader: true),
            _tableCell('Item', isHeader: true),
            _tableCell('Weight (kg)',
                isHeader: true, align: pw.TextAlign.right),
            _tableCell('Bags', isHeader: true, align: pw.TextAlign.center),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _tableCell('${index + 1}'),
              _tableCell(item.displayName),
              _tableCell(
                Formatters.weight(item.weightKg, showUnit: false),
                align: pw.TextAlign.right,
              ),
              _tableCell('${item.bagCount}', align: pw.TextAlign.center),
              _tableCell(
                Formatters.currencyValue(item.amount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build table cell
  static pw.Widget _tableCell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: _getTextStyle(
          fontSize: isHeader ? 10 : 9,
          bold: isHeader,
          color: color,
        ),
        textAlign: align,
      ),
    );
  }

  /// Build receipt summary
  static pw.Widget _buildReceiptSummary(TransactionModel transaction) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          _summaryRow(
              'Total Weight:', Formatters.weight(transaction.totalWeightKg)),
          _summaryRow('Total Bags:', '${transaction.totalBags}'),
          _summaryRow(
              'Price per kg:', Formatters.currency(transaction.pricePerKg)),
          pw.Divider(thickness: 0.5),
          _summaryRow(
            'Total Amount:',
            Formatters.currency(transaction.totalAmount),
            isBold: true,
            fontSize: 14,
          ),
          if (transaction.paidAmount > 0) ...[
            _summaryRow('Paid:', Formatters.currency(transaction.paidAmount)),
            _summaryRow(
              'Balance:',
              Formatters.currency(transaction.balanceDue),
              color:
                  transaction.balanceDue > 0 ? PdfColors.red : PdfColors.green,
            ),
          ],
        ],
      ),
    );
  }

  /// Build summary row
  static pw.Widget _summaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 11,
    PdfColor? color,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: _getTextStyle(fontSize: fontSize)),
          pw.Text(
            value,
            style: _getTextStyle(
              fontSize: fontSize,
              bold: isBold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build receipt footer
  static pw.Widget _buildReceiptFooter(String? customText) {
    return pw.Column(
      children: [
        pw.Center(
          child: pw.Text(
            customText ?? 'Thank you for your business!',
            style: _getTextStyle(fontSize: 10),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: 'Receipt generated by ${AppConstants.appName}',
            width: 60,
            height: 60,
          ),
        ),
      ],
    );
  }

  // ==================== REPORT GENERATION ====================

  /// Generate daily report
  static Future<Uint8List> generateDailyReport({
    required DateTime date,
    required List<TransactionModel> transactions,
    required double totalBuyAmount,
    required double totalSellAmount,
    required double totalBuyWeight,
    required double totalSellWeight,
    String? companyName,
  }) async {
    await initializeFonts();

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          title: 'Daily Transaction Report',
          subtitle: dateFormat.format(date),
          companyName: companyName ?? AppConstants.appName,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Summary Cards
          _buildReportSummary(
            buyAmount: totalBuyAmount,
            sellAmount: totalSellAmount,
            buyWeight: totalBuyWeight,
            sellWeight: totalSellWeight,
            transactionCount: transactions.length,
          ),
          pw.SizedBox(height: 24),

          // Transactions Table
          pw.Text(
            'Transactions',
            style: _getTextStyle(fontSize: 14, bold: true),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionsTable(transactions),
        ],
      ),
    );

    return pdf.save();
  }

  /// Build report header
  static pw.Widget _buildReportHeader({
    required String title,
    required String subtitle,
    required String companyName,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(companyName,
                style: _getTextStyle(fontSize: 16, bold: true)),
            pw.Text(
              'Generated: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: _getTextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
        pw.SizedBox(height: 16),
        pw.Text(title, style: _getTextStyle(fontSize: 20, bold: true)),
        pw.Text(subtitle,
            style: _getTextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 16),
      ],
    );
  }

  /// Build report footer
  static pw.Widget _buildReportFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              AppConstants.appName,
              style: _getTextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: _getTextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  /// Build report summary
  static pw.Widget _buildReportSummary({
    required double buyAmount,
    required double sellAmount,
    required double buyWeight,
    required double sellWeight,
    required int transactionCount,
  }) {
    return pw.Row(
      children: [
        _summaryCard(
            'Total Buy', Formatters.currency(buyAmount), PdfColors.orange),
        pw.SizedBox(width: 16),
        _summaryCard(
            'Total Sell', Formatters.currency(sellAmount), PdfColors.blue),
        pw.SizedBox(width: 16),
        _summaryCard(
          'Net Profit',
          Formatters.currency(sellAmount - buyAmount),
          sellAmount >= buyAmount ? PdfColors.green : PdfColors.red,
        ),
        pw.SizedBox(width: 16),
        _summaryCard('Transactions', '$transactionCount', PdfColors.purple),
      ],
    );
  }

  /// Build summary card
  static pw.Widget _summaryCard(String label, String value, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: color.shade(0.95),
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: color.shade(0.8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: _getTextStyle(fontSize: 10, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: _getTextStyle(fontSize: 14, bold: true)),
          ],
        ),
      ),
    );
  }

  /// Build transactions table for report
  static pw.Widget _buildTransactionsTable(
      List<TransactionModel> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Transaction ID', isHeader: true),
            _tableCell('Type', isHeader: true),
            _tableCell('Customer', isHeader: true),
            _tableCell('Weight', isHeader: true, align: pw.TextAlign.right),
            _tableCell('Bags', isHeader: true, align: pw.TextAlign.center),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Data
        ...transactions.map((t) => pw.TableRow(
              children: [
                _tableCell(t.transactionId),
                _tableCell(t.transactionType.displayName),
                _tableCell(t.customerName ?? '-'),
                _tableCell(Formatters.weight(t.totalWeightKg, showUnit: false),
                    align: pw.TextAlign.right),
                _tableCell('${t.totalBags}', align: pw.TextAlign.center),
                _tableCell(Formatters.currencyValue(t.totalAmount),
                    align: pw.TextAlign.right),
              ],
            )),
      ],
    );
  }

  // ==================== FILE OPERATIONS ====================

  /// Save PDF to file
  static Future<File> saveToFile(Uint8List pdfData, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(pdfData);
    return file;
  }

  /// Share PDF
  static Future<void> sharePdf(Uint8List pdfData, String fileName) async {
    await Printing.sharePdf(bytes: pdfData, filename: fileName);
  }

  /// Print PDF
  static Future<void> printPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfData);
  }

  /// Preview PDF
  static Future<void> previewPdf(Uint8List pdfData) async {
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Preview',
    );
  }

  /// Get PDF preview widget
  static pw.Widget getPdfPreview(Uint8List pdfData) {
    return PdfPreview(
      build: (format) async => pdfData,
    ) as pw.Widget;
  }

  // ==================== REPORT PDF GENERATION ====================

  /// Generate invoice PDF from TransactionModel
  static Future<String> generateInvoicePdf(TransactionModel transaction,
      {String? companyName}) async {
    await initializeFonts();

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    companyName ?? AppConstants.appName,
                    style: _getTextStyle(fontSize: 20, bold: true),
                  ),
                  pw.Text(
                    'INVOICE',
                    style: _getTextStyle(
                        fontSize: 18, bold: true, color: PdfColors.blue),
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 16),

              // Invoice Info
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Invoice No:',
                        style: _getTextStyle(
                            fontSize: 12, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        transaction.transactionId,
                        style: _getTextStyle(fontSize: 14, bold: true),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Date:',
                        style: _getTextStyle(
                            fontSize: 12, color: PdfColors.grey700),
                      ),
                      pw.Text(
                        dateFormat.format(transaction.transactionDate),
                        style: _getTextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),

              // Customer Info
              if (transaction.customerName != null)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Bill To:',
                        style: _getTextStyle(fontSize: 12, bold: true),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        transaction.customerName!,
                        style: _getTextStyle(fontSize: 14, bold: true),
                      ),
                      if (transaction.customerPhone != null) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Phone: ${Formatters.phone(transaction.customerPhone!)}',
                          style: _getTextStyle(fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              pw.SizedBox(height: 16),

              // Transaction Type
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: transaction.transactionType == TransactionType.buy
                      ? PdfColors.orange.shade(0.2)
                      : PdfColors.blue.shade(0.2),
                  borderRadius: pw.BorderRadius.circular(4),
                  border: pw.Border.all(
                    color: transaction.transactionType == TransactionType.buy
                        ? PdfColors.orange.shade(0.5)
                        : PdfColors.blue.shade(0.5),
                  ),
                ),
                child: pw.Text(
                  'Transaction Type: ${transaction.transactionType.displayName}',
                  style: _getTextStyle(
                    fontSize: 12,
                    bold: true,
                    color: transaction.transactionType == TransactionType.buy
                        ? PdfColors.orange.shade(0.8)
                        : PdfColors.blue.shade(0.8),
                  ),
                ),
              ),
              pw.SizedBox(height: 16),

              // Items Table
              _buildInvoiceItemsTable(transaction.items),
              pw.SizedBox(height: 16),

              // Summary
              _buildInvoiceSummary(transaction),
              pw.SizedBox(height: 24),

              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank you for your business!',
                  style: _getTextStyle(fontSize: 12),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Center(
                child: pw.Text(
                  'Generated by ${AppConstants.appName} on ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                  style: _getTextStyle(fontSize: 8, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfData = await pdf.save();
    final fileName =
        'Invoice_${transaction.transactionId}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = await saveToFile(pdfData, fileName);
    return file.path;
  }

  /// Build invoice items table
  static pw.Widget _buildInvoiceItemsTable(List<TransactionItemModel> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1),
        5: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('#', isHeader: true, align: pw.TextAlign.center),
            _tableCell('Item Details', isHeader: true),
            _tableCell('Weight (kg)',
                isHeader: true, align: pw.TextAlign.right),
            _tableCell('Bags', isHeader: true, align: pw.TextAlign.center),
            _tableCell('Rate', isHeader: true, align: pw.TextAlign.right),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _tableCell('${index + 1}', align: pw.TextAlign.center),
              _tableCell(item.displayName),
              _tableCell(
                Formatters.weight(item.weightKg, showUnit: false),
                align: pw.TextAlign.right,
              ),
              _tableCell('${item.bagCount}', align: pw.TextAlign.center),
              _tableCell(
                Formatters.currency(item.pricePerKg),
                align: pw.TextAlign.right,
              ),
              _tableCell(
                Formatters.currencyValue(item.amount),
                align: pw.TextAlign.right,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Build invoice summary
  static pw.Widget _buildInvoiceSummary(TransactionModel transaction) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        children: [
          _summaryRow(
              'Total Weight:', Formatters.weight(transaction.totalWeightKg)),
          _summaryRow('Total Bags:', '${transaction.totalBags}'),
          pw.Divider(thickness: 0.5),
          _summaryRow(
            'Subtotal:',
            Formatters.currency(transaction.totalAmount),
            fontSize: 13,
          ),
          if (transaction.paidAmount > 0) ...[
            _summaryRow(
                'Paid Amount:', Formatters.currency(transaction.paidAmount)),
            _summaryRow(
              'Balance Due:',
              Formatters.currency(transaction.balanceDue),
              color:
                  transaction.balanceDue > 0 ? PdfColors.red : PdfColors.green,
              fontSize: 14,
              isBold: true,
            ),
          ] else ...[
            _summaryRow(
              'Total Amount:',
              Formatters.currency(transaction.totalAmount),
              isBold: true,
              fontSize: 14,
            ),
          ],
        ],
      ),
    );
  }

  /// Generate PDF from ReportModel
  static Future<String> generateReportPdf(ReportModel report,
      {String? companyName}) async {
    await initializeFonts();

    final pdf = pw.Document();
    final dateFormat = DateFormat('dd MMMM yyyy');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        header: (context) => _buildReportHeader(
          title: report.title,
          subtitle:
              '${dateFormat.format(report.startDate)} - ${dateFormat.format(report.endDate)}',
          companyName: companyName ?? AppConstants.appName,
        ),
        footer: (context) => _buildReportFooter(context),
        build: (context) => [
          // Report Summary
          _buildReportSummarySection(report.summary),
          pw.SizedBox(height: 24),

          // Report Items Table
          if (report.items.isNotEmpty) ...[
            pw.Text(
              'Details',
              style: _getTextStyle(fontSize: 14, bold: true),
            ),
            pw.SizedBox(height: 8),
            _buildReportItemsTable(report.items),
          ],
        ],
      ),
    );

    final pdfData = await pdf.save();
    final fileName =
        '${report.title.replaceAll(' ', '_').replaceAll('-', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = await saveToFile(pdfData, fileName);
    return file.path;
  }

  /// Build report summary section
  static pw.Widget _buildReportSummarySection(ReportSummary summary) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary',
            style: _getTextStyle(fontSize: 16, bold: true),
          ),
          pw.SizedBox(height: 12),

          // Financial Summary
          pw.Row(
            children: [
              _summaryCard(
                  'Total Purchases',
                  Formatters.currency(summary.totalPurchases),
                  PdfColors.orange),
              pw.SizedBox(width: 12),
              _summaryCard('Total Sales',
                  Formatters.currency(summary.totalSales), PdfColors.blue),
              pw.SizedBox(width: 12),
              _summaryCard(
                'Gross Profit',
                Formatters.currency(summary.grossProfit),
                summary.grossProfit >= 0 ? PdfColors.green : PdfColors.red,
              ),
            ],
          ),
          pw.SizedBox(height: 12),

          // Transaction Counts
          pw.Row(
            children: [
              _summaryCard('Purchase Count', '${summary.purchaseCount}',
                  PdfColors.purple),
              pw.SizedBox(width: 12),
              _summaryCard(
                  'Sale Count', '${summary.saleCount}', PdfColors.teal),
              pw.SizedBox(width: 12),
              _summaryCard('Total Transactions', '${summary.totalTransactions}',
                  PdfColors.indigo),
            ],
          ),
          pw.SizedBox(height: 12),

          // Stock Information
          if (summary.totalPaddyStock > 0 || summary.totalRiceStock > 0) ...[
            pw.Row(
              children: [
                _summaryCard(
                    'Paddy Stock',
                    '${summary.totalPaddyStock.toStringAsFixed(2)} kg',
                    PdfColors.brown),
                pw.SizedBox(width: 12),
                _summaryCard(
                    'Rice Stock',
                    '${summary.totalRiceStock.toStringAsFixed(2)} kg',
                    PdfColors.amber),
              ],
            ),
            pw.SizedBox(height: 12),
          ],

          // Additional metrics
          if (summary.totalPaddyBought > 0 || summary.totalRiceSold > 0) ...[
            pw.Row(
              children: [
                if (summary.totalPaddyBought > 0)
                  _summaryCard(
                      'Paddy Bought',
                      '${summary.totalPaddyBought.toStringAsFixed(2)} kg',
                      PdfColors.green.shade(0.7)),
                if (summary.totalPaddyBought > 0 && summary.totalRiceSold > 0)
                  pw.SizedBox(width: 12),
                if (summary.totalRiceSold > 0)
                  _summaryCard(
                      'Rice Sold',
                      '${summary.totalRiceSold.toStringAsFixed(2)} kg',
                      PdfColors.blue.shade(0.7)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build report items table
  static pw.Widget _buildReportItemsTable(List<ReportItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('#', isHeader: true, align: pw.TextAlign.center),
            _tableCell('Item', isHeader: true),
            _tableCell('Description', isHeader: true),
            _tableCell('Value', isHeader: true, align: pw.TextAlign.right),
            _tableCell('Change', isHeader: true, align: pw.TextAlign.center),
          ],
        ),
        // Items
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return pw.TableRow(
            children: [
              _tableCell('${index + 1}', align: pw.TextAlign.center),
              _tableCell(item.label),
              _tableCell(item.description ?? '-'),
              _tableCell(
                item.formattedValue,
                align: pw.TextAlign.right,
                color: item.unit == 'currency' && item.value < 0
                    ? PdfColors.red
                    : null,
              ),
              _tableCell(
                item.changeIndicator,
                align: pw.TextAlign.center,
                color: item.isPositiveChange
                    ? PdfColors.green
                    : item.isNegativeChange
                        ? PdfColors.red
                        : PdfColors.grey600,
              ),
            ],
          );
        }),
      ],
    );
  }
}
