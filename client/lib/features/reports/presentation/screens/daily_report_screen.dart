import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/utils/number_formatter.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/shared_widgets/loading_overlay.dart';
import '../../../../core/constants/si_strings.dart';
import '../../../../domain/entities/transaction_entity.dart';
import '../../../../domain/entities/expense_entity.dart';
import 'dart:convert';
import 'package:printing/printing.dart';
import '../../../../domain/repositories/transaction_repository.dart';
import '../../../../domain/repositories/expense_repository.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/enums.dart';
import '../../../../core/utils/report_pdf_generator.dart';
import '../widgets/export_button.dart';

enum ReportPeriod { day, week, month }

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  ReportPeriod _selectedPeriod = ReportPeriod.day;
  DateTime _selectedDate = DateTime.now();
  DateTimeRange? _selectedDateRange;
  DateTime? _chartSelectedDate;
  bool _isLoading = false;
  
  List<TransactionEntity> _transactions = [];
  List<ExpenseEntity> _expenses = [];
  
  // Summary data
  double _totalBuy = 0;
  double _totalSell = 0;
  double _totalExpenses = 0;
  double _profit = 0;
  
  // Chart data for the period
  List<DateTime> _periodDates = [];
  Map<DateTime, double> _buyData = {};
  Map<DateTime, double> _sellData = {};
  Map<DateTime, double> _expenseData = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final txnRepo = sl<TransactionRepository>();
      final expRepo = sl<ExpenseRepository>();
      
      // Determine date range based on selected period
      DateTime startDate, endDate;
      
      switch (_selectedPeriod) {
        case ReportPeriod.day:
          if (_selectedDateRange != null) {
            startDate = DateTime(_selectedDateRange!.start.year, _selectedDateRange!.start.month, _selectedDateRange!.start.day);
            endDate = DateTime(_selectedDateRange!.end.year, _selectedDateRange!.end.month, _selectedDateRange!.end.day).add(const Duration(days: 1));
            final int daysInRange = endDate.difference(startDate).inDays;
            _periodDates = List.generate(daysInRange, (i) => startDate.add(Duration(days: i)));
          } else {
            startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
            endDate = startDate.add(const Duration(days: 1));
            _periodDates = [startDate];
          }
          break;
          
        case ReportPeriod.week:
          // Start from Monday of the week
          startDate = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
          startDate = DateTime(startDate.year, startDate.month, startDate.day);
          endDate = startDate.add(const Duration(days: 7));
          _periodDates = List.generate(7, (i) => startDate.add(Duration(days: i)));
          break;
          
        case ReportPeriod.month:
          startDate = DateTime(_selectedDate.year, _selectedDate.month, 1);
          endDate = DateTime(_selectedDate.year, _selectedDate.month + 1, 1);
          final daysInMonth = endDate.difference(startDate).inDays;
          _periodDates = List.generate(daysInMonth, (i) => startDate.add(Duration(days: i)));
          break;
      }
      
      // Fetch all transactions and expenses
      final allTxnsResult = await txnRepo.getAllTransactions();
      final allExpensesResult = await expRepo.getExpenses();
      
      List<TransactionEntity> allTxns = [];
      List<ExpenseEntity> allExpenses = [];
      
      allTxnsResult.fold(
        (l) {
          // Handle failure silently, list remains empty
          return const [];
        },
        (r) {
          allTxns = r;
          return r;
        },
      );
      
      allExpensesResult.fold(
        (l) {
          // Handle failure silently, list remains empty
          return const [];
        },
        (r) {
          allExpenses = r;
          return r;
        },
      );
      
      // Filter for the period or specific chart-selected date
      DateTime filterStart, filterEnd;
      
      if (_chartSelectedDate != null) {
        // Show only the selected day from chart
        filterStart = DateTime(_chartSelectedDate!.year, _chartSelectedDate!.month, _chartSelectedDate!.day);
        filterEnd = filterStart.add(const Duration(days: 1));
      } else {
        filterStart = startDate;
        filterEnd = endDate;
      }
      
      _transactions = allTxns.where((t) {
        return t.transactionDate.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
               t.transactionDate.isBefore(filterEnd);
      }).toList();
      
      _expenses = allExpenses.where((e) {
        return e.date.isAfter(filterStart.subtract(const Duration(seconds: 1))) &&
               e.date.isBefore(filterEnd);
      }).toList();
      
      // Calculate summary
      _totalBuy = 0;
      _totalSell = 0;
      
      for (var t in _transactions) {
        if (t.type == TransactionType.buy) {
          _totalBuy += t.totalAmount;
        } else if (t.type == TransactionType.sell) {
          _totalSell += t.totalAmount;
        }
      }
      
      _totalExpenses = _expenses.fold(0.0, (sum, e) => sum + e.amount);
      _profit = _totalSell - _totalBuy - _totalExpenses;
      
      // Build chart data for the entire period
      _buyData.clear();
      _sellData.clear();
      _expenseData.clear();
      
      for (var date in _periodDates) {
        final dayStart = DateTime(date.year, date.month, date.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        
        final dayTxns = allTxns.where((t) =>
          t.transactionDate.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          t.transactionDate.isBefore(dayEnd)
        );
        
        final dayExpenses = allExpenses.where((e) =>
          e.date.isAfter(dayStart.subtract(const Duration(seconds: 1))) &&
          e.date.isBefore(dayEnd)
        );
        
        double dayBuy = 0;
        double daySell = 0;
        
        for (var t in dayTxns) {
          if (t.type == TransactionType.buy) dayBuy += t.totalAmount;
          if (t.type == TransactionType.sell) daySell += t.totalAmount;
        }
        
        double dayExpense = dayExpenses.fold(0.0, (sum, e) => sum + e.amount);
        
        _buyData[dayStart] = dayBuy;
        _sellData[dayStart] = daySell;
        _expenseData[dayStart] = dayExpense;
      }
      
    } catch (e) {
      debugPrint('Error loading report data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('වාර්තා'), // Reports
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.calendar_today),
              onPressed: _selectDate,
            ),
          ],
        ),
        body: Column(
          children: [
            // Period Filter Tabs
            _buildPeriodTabs(),
            
            // Date Navigation (for day mode)
            if (_selectedPeriod == ReportPeriod.day) _buildDateNavigation(),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected date indicator
                    if (_chartSelectedDate != null) _buildSelectedDateBanner(),
                    
                    // Summary Cards
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    
                    // Chart
                    if (_periodDates.length > 1) ...[
                      _buildChartSection(),
                      const SizedBox(height: 24),
                    ],
                    
                    // Transaction Details
                    _buildTransactionsList(),
                    const SizedBox(height: 16),
                    
                    // Expenses List
                    _buildExpensesList(),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: ExportButton(
          onExportPdf: _exportPdf,
          onExportExcel: _exportExcel,
          onPrint: _printReport,
        ),
      ),
    );
  }

  Widget _buildPeriodTabs() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _buildPeriodTab('දිනය', ReportPeriod.day),
          ),
          Expanded(
            child: _buildPeriodTab('සතිය', ReportPeriod.week),
          ),
          Expanded(
            child: _buildPeriodTab('මාසය', ReportPeriod.month),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, ReportPeriod period) {
    String englishLabel = '';
    switch (period) {
      case ReportPeriod.day: englishLabel = 'Day'; break;
      case ReportPeriod.week: englishLabel = 'Week'; break;
      case ReportPeriod.month: englishLabel = 'Month'; break;
    }
    
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPeriod = period;
          _chartSelectedDate = null; // Reset chart selection
          _selectedDateRange = null;
        });
        _loadData();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 20,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              SiStrings.isSinhala ? label : englishLabel,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateNavigation() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                if (_selectedDateRange != null) {
                  final duration = _selectedDateRange!.end.difference(_selectedDateRange!.start) + const Duration(days: 1);
                  _selectedDateRange = DateTimeRange(
                    start: _selectedDateRange!.start.subtract(duration),
                    end: _selectedDateRange!.end.subtract(duration),
                  );
                  _selectedDate = _selectedDateRange!.start;
                } else {
                  _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                }
                _chartSelectedDate = null;
              });
              _loadData();
            },
          ),
          Text(
            _selectedDateRange != null && _selectedDateRange!.start != _selectedDateRange!.end
                ? '${DateFormat('yyyy-MM-dd').format(_selectedDateRange!.start)} to ${DateFormat('MM-dd').format(_selectedDateRange!.end)}'
                : DateFormat('yyyy-MM-dd (EEEE)').format(_selectedDate),
            style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () {
              setState(() {
                if (_selectedDateRange != null) {
                  final duration = _selectedDateRange!.end.difference(_selectedDateRange!.start) + const Duration(days: 1);
                  final nextStart = _selectedDateRange!.start.add(duration);
                  final nextEnd = _selectedDateRange!.end.add(duration);
                  if (nextStart.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                    _selectedDateRange = DateTimeRange(
                      start: nextStart,
                      end: nextEnd.isAfter(DateTime.now()) ? DateTime.now() : nextEnd,
                    );
                    _selectedDate = _selectedDateRange!.start;
                  }
                } else {
                  final next = _selectedDate.add(const Duration(days: 1));
                  if (next.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                    _selectedDate = next;
                  }
                }
                _chartSelectedDate = null;
              });
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDateBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.info),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Showing: ${DateFormat('yyyy-MM-dd').format(_chartSelectedDate!)}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.info),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: AppColors.info),
            onPressed: () {
              setState(() => _chartSelectedDate = null);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'මුළු මිලදී ගැනීම්', // Total Buy
                _totalBuy,
                AppColors.error,
                Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'මුළු විකුණුම්', // Total Sell
                _totalSell,
                AppColors.success,
                Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSummaryCard(
                'වියදම්', // Expenses
                _totalExpenses,
                AppColors.warning,
                Icons.money_off,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSummaryCard(
                'ශුද්ධ ලාභය', // Net Profit
                _profit,
                _profit >= 0 ? AppColors.primary : AppColors.error,
                Icons.account_balance_wallet,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, double value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              label,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                'Rs. ${_formatCurrency(value)}',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity Chart',
            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('Buy', AppColors.error),
              const SizedBox(width: 16),
              _buildLegendItem('Sell', AppColors.success),
              const SizedBox(width: 16),
              _buildLegendItem('Exp', AppColors.warning),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: _buildBarChart(),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildBarChart() {
    if (_periodDates.isEmpty) return const SizedBox();
    
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxValue() * 1.2,
        barTouchData: BarTouchData(
          enabled: true,
          touchCallback: (event, response) {
            if (event is FlTapUpEvent && response != null && response.spot != null) {
              final index = response.spot!.touchedBarGroupIndex;
              if (index >= 0 && index < _periodDates.length) {
                setState(() {
                  _chartSelectedDate = _periodDates[index];
                });
                _loadData();
              }
            }
          },
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: AppColors.white.withOpacity(0.9),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final date = _periodDates[groupIndex];
              String label = '';
              Color color = AppColors.primary;
              
              if (rodIndex == 0) {
                label = 'Buy: ${_formatCurrency(_buyData[date] ?? 0)}';
                color = AppColors.error;
              } else if (rodIndex == 1) {
                label = 'Sell: ${_formatCurrency(_sellData[date] ?? 0)}';
                color = AppColors.success;
              } else {
                label = 'Expense: ${_formatCurrency(_expenseData[date] ?? 0)}';
                color = AppColors.warning;
              }
              
              return BarTooltipItem(
                label,
                TextStyle(color: color, fontWeight: FontWeight.bold),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= _periodDates.length) return const SizedBox.shrink();
                
                final date = _periodDates[index];
                
                // Determine if we should show this specific label to avoid overlap
                bool showLabel = true;
                if (_periodDates.length > 15) {
                  // For long periods (~30 days), show every 5th label and the last one
                  showLabel = (index % 5 == 0) || (index == _periodDates.length - 1);
                } else if (_periodDates.length > 8) {
                  // For medium periods (like a week), show every 2nd label
                  showLabel = (index % 2 == 0) || (index == _periodDates.length - 1);
                }
                
                if (!showLabel) return const SizedBox.shrink();

                final label = DateFormat('d').format(date);
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  space: 4,
                  child: Text(
                    label,
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(_periodDates.length, (index) {
          final date = _periodDates[index];
          final buy = _buyData[date] ?? 0;
          final sell = _sellData[date] ?? 0;
          final expense = _expenseData[date] ?? 0;
          
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: buy,
                color: AppColors.error,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: sell,
                color: AppColors.success,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
              BarChartRodData(
                toY: expense,
                color: AppColors.warning,
                width: 8,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }),
      ),
    );
  }

  double _getMaxValue() {
    double max = 0;
    for (var date in _periodDates) {
      final buy = _buyData[date] ?? 0;
      final sell = _sellData[date] ?? 0;
      final expense = _expenseData[date] ?? 0;
      
      if (buy > max) max = buy;
      if (sell > max) max = sell;
      if (expense > max) max = expense;
    }
    return max == 0 ? 100 : max;
  }

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'ගනුදෙනු නැත',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions (${_transactions.length})',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(_transactions.length, (index) {
          final txn = _transactions[index];
          final isBuy = txn.type == TransactionType.buy;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (isBuy ? AppColors.error : AppColors.success).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (isBuy ? AppColors.error : AppColors.success).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isBuy ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isBuy ? AppColors.error : AppColors.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isBuy ? 'Buy' : 'Sell',
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        txn.customerName ?? 'Unknown',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(txn.transactionDate),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 100,
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      'Rs. ${_formatCurrency(txn.totalAmount)}',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isBuy ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildExpensesList() {
    if (_expenses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'වියදම් නැත',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Expenses (${_expenses.length})',
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...List.generate(_expenses.length, (index) {
          final expense = _expenses[index];
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.money_off,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.category.sinhalaName,
                        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      if (expense.notes != null && expense.notes!.isNotEmpty)
                        Text(
                          expense.notes!,
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      Text(
                        DateFormat('hh:mm a').format(expense.date),
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Rs. ${_formatCurrency(expense.amount)}',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Future<void> _selectDate() async {
    final range = await showDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: _selectedDate,
        end: _selectedDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
        _selectedDate = range.start;
        _chartSelectedDate = null;
        _selectedPeriod = ReportPeriod.day;
      });
      _loadData();
    }
  }

  Future<void> _exportPdf() async {
    DateTime start = _selectedDate;
    DateTime end = _selectedDate;

    if (_chartSelectedDate != null) {
      start = _chartSelectedDate!;
      end = _chartSelectedDate!;
    } else if (_periodDates.isNotEmpty) {
      start = _periodDates.first;
      end = _periodDates.last;
    }
    
    setState(() => _isLoading = true);
    try {
      final String dateRangeLabel = start.isAtSameMomentAs(end)
          ? DateFormat('yyyy-MM-dd').format(start)
          : '${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('MM-dd').format(end)}';

      final pdfBytes = await ReportPdfGenerator.generatePeriodReport(
        periodLabel: _selectedPeriod.name.toUpperCase(),
        dateRange: dateRangeLabel,
        transactions: _transactions,
        expenses: _expenses,
        totalBuy: _totalBuy,
        totalSell: _totalSell,
        totalExpenses: _totalExpenses,
        netProfit: _profit,
      );
      
      await Printing.sharePdf(bytes: pdfBytes, filename: 'Report_${DateFormat('yyyy-MM-dd').format(start)}.pdf');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting PDF: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _exportExcel() async {
    DateTime start = _selectedDate;
    if (_chartSelectedDate != null) {
      start = _chartSelectedDate!;
    } else if (_periodDates.isNotEmpty) {
      start = _periodDates.first;
    }
    
    setState(() => _isLoading = true);
    try {
      final StringBuffer buffer = StringBuffer();
      
      buffer.writeln('Summary');
      buffer.writeln('Total Buy,${_totalBuy}');
      buffer.writeln('Total Sell,${_totalSell}');
      buffer.writeln('Total Expenses,${_totalExpenses}');
      buffer.writeln('Net Profit,${_profit}');
      buffer.writeln();
      
      buffer.writeln('Transactions');
      buffer.writeln('Type,Customer,Date,Amount');
      for (var t in _transactions) {
        buffer.writeln('${t.isBuyTransaction ? "Buy" : "Sell"},"${t.customerName}",${DateFormat('yyyy-MM-dd HH:mm').format(t.transactionDate)},${t.totalAmount}');
      }
      
      buffer.writeln();
      buffer.writeln('Expenses');
      buffer.writeln('Category,Notes,Date,Amount');
      for (var e in _expenses) {
        buffer.writeln('"${e.category.name}","${e.notes?.replaceAll('"', '""') ?? ""}",${DateFormat('yyyy-MM-dd HH:mm').format(e.date)},${e.amount}');
      }
      
      final bytes = utf8.encode(buffer.toString());
      await Printing.sharePdf(bytes: bytes, filename: 'Report_${DateFormat('yyyy-MM-dd').format(start)}.csv');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error exporting Excel: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _printReport() async {
    DateTime start = _selectedDate;
    DateTime end = _selectedDate;

    if (_chartSelectedDate != null) {
      start = _chartSelectedDate!;
      end = _chartSelectedDate!;
    } else if (_periodDates.isNotEmpty) {
      start = _periodDates.first;
      end = _periodDates.last;
    }
    
    setState(() => _isLoading = true);
    try {
      final String dateRangeLabel = start.isAtSameMomentAs(end)
          ? DateFormat('yyyy-MM-dd').format(start)
          : '${DateFormat('yyyy-MM-dd').format(start)} to ${DateFormat('MM-dd').format(end)}';

      final pdfBytes = await ReportPdfGenerator.generatePeriodReport(
        periodLabel: _selectedPeriod.name.toUpperCase(),
        dateRange: dateRangeLabel,
        transactions: _transactions,
        expenses: _expenses,
        totalBuy: _totalBuy,
        totalSell: _totalSell,
        totalExpenses: _totalExpenses,
        netProfit: _profit,
      );
      
      await Printing.layoutPdf(onLayout: (format) async => pdfBytes, name: 'Report_${DateFormat('yyyy-MM-dd').format(start)}');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error printing report: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatCurrency(double value) {
    return NumberFormatter.formatInteger(value);
  }
}
