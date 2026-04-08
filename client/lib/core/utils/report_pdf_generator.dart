import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/entities/expense_entity.dart';
import 'pdf_generator.dart';

class ReportPdfGenerator {
  static Future<Uint8List> generatePeriodReport({
    required String periodLabel,
    required String dateRange,
    required List<TransactionEntity> transactions,
    required List<ExpenseEntity> expenses,
    required double totalBuy,
    required double totalSell,
    required double totalExpenses,
    required double netProfit,
  }) async {
    await PdfGenerator.initializeFonts();

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(periodLabel, dateRange),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          _buildSummaryCards(totalBuy, totalSell, totalExpenses, netProfit),
          pw.SizedBox(height: 24),
          if (transactions.isNotEmpty) ...[
            pw.Text(
              'Transactions',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildTransactionsTable(transactions),
            pw.SizedBox(height: 24),
          ],
          if (expenses.isNotEmpty) ...[
            pw.Text(
              'Expenses',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            _buildExpensesTable(expenses),
          ],
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String title, String subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Report: $title',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.Text('Date: $subtitle',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
        pw.SizedBox(height: 16),
        pw.Divider(thickness: 1),
        pw.SizedBox(height: 16),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Column(
      children: [
        pw.Divider(thickness: 0.5),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSummaryCards(
      double buy, double sell, double expenses, double profit) {
    return pw.Row(
      children: [
        _summaryCard('Total Buy', buy),
        pw.SizedBox(width: 8),
        _summaryCard('Total Sell', sell),
        pw.SizedBox(width: 8),
        _summaryCard('Expenses', expenses),
        pw.SizedBox(width: 8),
        _summaryCard('Net Profit', profit, isNetProfit: true),
      ],
    );
  }

  static pw.Widget _summaryCard(String label, double value,
      {bool isNetProfit = false}) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(4),
          border: pw.Border.all(color: PdfColors.black, width: 1.2),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 11,
                color: PdfColors.black,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Rs. ${value.toStringAsFixed(0)}',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: isNetProfit
                    ? (value >= 0 ? PdfColors.black : PdfColors.red800)
                    : PdfColors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildTransactionsTable(
      List<TransactionEntity> transactions) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Type', isHeader: true),
            _tableCell('Customer', isHeader: true),
            _tableCell('Date/Time', isHeader: true),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        ...transactions.map((t) => pw.TableRow(
              children: [
                _tableCell(t.isBuyTransaction ? 'Buy' : 'Sell'),
                _tableCell(t.customerName),
                _tableCell(
                    DateFormat('yyyy-MM-dd hh:mm a').format(t.transactionDate)),
                _tableCell('Rs. ${t.totalAmount.toStringAsFixed(0)}',
                    align: pw.TextAlign.right),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildExpensesTable(List<ExpenseEntity> expenses) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey700, width: 0.8),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2.5),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableCell('Category', isHeader: true),
            _tableCell('Notes', isHeader: true),
            _tableCell('Date/Time', isHeader: true),
            _tableCell('Amount', isHeader: true, align: pw.TextAlign.right),
          ],
        ),
        ...expenses.map((e) => pw.TableRow(
              children: [
                _tableCell(e.category.name),
                _tableCell(e.notes ?? '-'),
                _tableCell(DateFormat('yyyy-MM-dd hh:mm a').format(e.date)),
                _tableCell('Rs. ${e.amount.toStringAsFixed(0)}',
                    align: pw.TextAlign.right),
              ],
            )),
      ],
    );
  }

  static pw.Widget _tableCell(String text,
      {bool isHeader = false, pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: PdfColors.black,
        ),
        textAlign: align,
      ),
    );
  }
}
