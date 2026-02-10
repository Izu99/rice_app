// lib/data/models/report_model.dart

import 'package:equatable/equatable.dart';

/// Report types
enum ReportType {
  daily,
  weekly,
  monthly,
  yearly,
  custom,
}

/// Report category
enum ReportCategory {
  sales,
  purchases,
  stock,
  financial,
  customer,
}

class ReportModel extends Equatable {
  final String id;
  final String? serverId;
  final ReportType type;
  final ReportCategory category;
  final String title;
  final DateTime startDate;
  final DateTime endDate;
  final String companyId;
  final String generatedById;
  final ReportSummary summary;
  final List<ReportItem> items;
  final Map<String, dynamic>? charts; // Chart data for visualization
  final String? pdfUrl;
  final String? excelUrl;
  final DateTime generatedAt;

  const ReportModel({
    required this.id,
    this.serverId,
    required this.type,
    required this.category,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.companyId,
    required this.generatedById,
    required this.summary,
    this.items = const [],
    this.charts,
    this.pdfUrl,
    this.excelUrl,
    required this.generatedAt,
  });

  /// Create ReportModel from JSON
  factory ReportModel.fromJson(Map<String, dynamic> json) {
    List<ReportItem> items = [];
    if (json['items'] != null) {
      items = (json['items'] as List)
          .map((item) => ReportItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ReportModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      serverId: json['server_id']?.toString() ?? json['_id']?.toString(),
      type: _parseReportType(json['type']),
      category: _parseReportCategory(json['category']),
      title: json['title'] ?? '',
      startDate: DateTime.parse(json['start_date'].toString()),
      endDate: DateTime.parse(json['end_date'].toString()),
      companyId: json['company_id']?.toString() ?? '',
      generatedById: json['generated_by_id']?.toString() ?? '',
      summary: ReportSummary.fromJson(json['summary'] ?? {}),
      items: items,
      charts: json['charts'] != null
          ? Map<String, dynamic>.from(json['charts'])
          : null,
      pdfUrl: json['pdf_url'],
      excelUrl: json['excel_url'],
      generatedAt: json['generated_at'] != null
          ? DateTime.parse(json['generated_at'].toString())
          : DateTime.now(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'type': type.name,
      'category': category.name,
      'title': title,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'company_id': companyId,
      'generated_by_id': generatedById,
      'summary': summary.toJson(),
      'items': items.map((item) => item.toJson()).toList(),
      'charts': charts,
      'pdf_url': pdfUrl,
      'excel_url': excelUrl,
      'generated_at': generatedAt.toIso8601String(),
    };
  }

  /// Copy with method
  ReportModel copyWith({
    String? id,
    String? serverId,
    ReportType? type,
    ReportCategory? category,
    String? title,
    DateTime? startDate,
    DateTime? endDate,
    String? companyId,
    String? generatedById,
    ReportSummary? summary,
    List<ReportItem>? items,
    Map<String, dynamic>? charts,
    String? pdfUrl,
    String? excelUrl,
    DateTime? generatedAt,
  }) {
    return ReportModel(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      type: type ?? this.type,
      category: category ?? this.category,
      title: title ?? this.title,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      companyId: companyId ?? this.companyId,
      generatedById: generatedById ?? this.generatedById,
      summary: summary ?? this.summary,
      items: items ?? this.items,
      charts: charts ?? this.charts,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      excelUrl: excelUrl ?? this.excelUrl,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  /// Create daily report
  factory ReportModel.createDaily({
    required DateTime date,
    required String companyId,
    required String generatedById,
    required ReportSummary summary,
    List<ReportItem> items = const [],
  }) {
    final now = DateTime.now();
    return ReportModel(
      id: 'RPT_${now.millisecondsSinceEpoch}',
      type: ReportType.daily,
      category: ReportCategory.financial,
      title: 'Daily Report - ${_formatDate(date)}',
      startDate: DateTime(date.year, date.month, date.day),
      endDate: DateTime(date.year, date.month, date.day, 23, 59, 59),
      companyId: companyId,
      generatedById: generatedById,
      summary: summary,
      items: items,
      generatedAt: now,
    );
  }

  /// Create monthly report
  factory ReportModel.createMonthly({
    required int year,
    required int month,
    required String companyId,
    required String generatedById,
    required ReportSummary summary,
    List<ReportItem> items = const [],
  }) {
    final now = DateTime.now();
    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0, 23, 59, 59);

    return ReportModel(
      id: 'RPT_${now.millisecondsSinceEpoch}',
      type: ReportType.monthly,
      category: ReportCategory.financial,
      title: 'Monthly Report - ${_formatMonth(year, month)}',
      startDate: startDate,
      endDate: endDate,
      companyId: companyId,
      generatedById: generatedById,
      summary: summary,
      items: items,
      generatedAt: now,
    );
  }

  /// Parse report type
  static ReportType _parseReportType(dynamic type) {
    if (type == null) return ReportType.daily;
    if (type is ReportType) return type;

    final typeStr = type.toString().toLowerCase();
    switch (typeStr) {
      case 'weekly':
        return ReportType.weekly;
      case 'monthly':
        return ReportType.monthly;
      case 'yearly':
        return ReportType.yearly;
      case 'custom':
        return ReportType.custom;
      case 'daily':
      default:
        return ReportType.daily;
    }
  }

  /// Parse report category
  static ReportCategory _parseReportCategory(dynamic category) {
    if (category == null) return ReportCategory.financial;
    if (category is ReportCategory) return category;

    final catStr = category.toString().toLowerCase();
    switch (catStr) {
      case 'sales':
        return ReportCategory.sales;
      case 'purchases':
        return ReportCategory.purchases;
      case 'stock':
        return ReportCategory.stock;
      case 'customer':
        return ReportCategory.customer;
      case 'financial':
      default:
        return ReportCategory.financial;
    }
  }

  /// Format date helper
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Format month helper
  static String _formatMonth(int year, int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[month - 1]} $year';
  }

  /// Get type display name
  String get typeDisplayName {
    switch (type) {
      case ReportType.daily:
        return 'Daily';
      case ReportType.weekly:
        return 'Weekly';
      case ReportType.monthly:
        return 'Monthly';
      case ReportType.yearly:
        return 'Yearly';
      case ReportType.custom:
        return 'Custom';
    }
  }

  /// Get category display name
  String get categoryDisplayName {
    switch (category) {
      case ReportCategory.sales:
        return 'Sales';
      case ReportCategory.purchases:
        return 'Purchases';
      case ReportCategory.stock:
        return 'Stock';
      case ReportCategory.financial:
        return 'Financial';
      case ReportCategory.customer:
        return 'Customer';
    }
  }

  /// Get date range display
  String get dateRangeDisplay {
    if (type == ReportType.daily) {
      return _formatDate(startDate);
    }
    return '${_formatDate(startDate)} - ${_formatDate(endDate)}';
  }

  /// Check if has PDF
  bool get hasPdf => pdfUrl != null && pdfUrl!.isNotEmpty;

  /// Check if has Excel
  bool get hasExcel => excelUrl != null && excelUrl!.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        serverId,
        type,
        category,
        title,
        startDate,
        endDate,
        companyId,
        generatedById,
        summary,
        items,
        charts,
        pdfUrl,
        excelUrl,
        generatedAt,
      ];

  @override
  String toString() {
    return 'ReportModel(id: $id, title: $title, type: $type, category: $category)';
  }
}

/// Report summary containing key metrics
class ReportSummary extends Equatable {
  final double totalPurchases;
  final double totalSales;
  final double grossProfit;
  final double netProfit;
  final int purchaseCount;
  final int saleCount;
  final double totalPaddyBought; // in kg
  final double totalRiceSold; // in kg
  final double totalPaddyStock; // Current stock
  final double totalRiceStock;
  final int newCustomersCount;
  final double outstandingReceivables; // Money customers owe us
  final double outstandingPayables; // Money we owe customers
  final Map<String, double>? categoryBreakdown;
  final Map<String, double>? varietyBreakdown;

  const ReportSummary({
    this.totalPurchases = 0,
    this.totalSales = 0,
    this.grossProfit = 0,
    this.netProfit = 0,
    this.purchaseCount = 0,
    this.saleCount = 0,
    this.totalPaddyBought = 0,
    this.totalRiceSold = 0,
    this.totalPaddyStock = 0,
    this.totalRiceStock = 0,
    this.newCustomersCount = 0,
    this.outstandingReceivables = 0,
    this.outstandingPayables = 0,
    this.categoryBreakdown,
    this.varietyBreakdown,
  });

  /// Create ReportSummary from JSON
  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    return ReportSummary(
      totalPurchases:
          _parseDouble(json['total_purchases'] ?? json['totalPurchases']),
      totalSales: _parseDouble(json['total_sales'] ?? json['totalSales']),
      grossProfit: _parseDouble(json['gross_profit'] ?? json['grossProfit']),
      netProfit: _parseDouble(json['net_profit'] ?? json['netProfit']),
      purchaseCount: _parseInt(json['purchase_count'] ?? json['purchaseCount']),
      saleCount: _parseInt(json['sale_count'] ?? json['saleCount']),
      totalPaddyBought:
          _parseDouble(json['total_paddy_bought'] ?? json['totalPaddyBought']),
      totalRiceSold:
          _parseDouble(json['total_rice_sold'] ?? json['totalRiceSold']),
      totalPaddyStock:
          _parseDouble(json['total_paddy_stock'] ?? json['totalPaddyStock']),
      totalRiceStock:
          _parseDouble(json['total_rice_stock'] ?? json['totalRiceStock']),
      newCustomersCount:
          _parseInt(json['new_customers_count'] ?? json['newCustomersCount']),
      outstandingReceivables: _parseDouble(
          json['outstanding_receivables'] ?? json['outstandingReceivables']),
      outstandingPayables: _parseDouble(
          json['outstanding_payables'] ?? json['outstandingPayables']),
      categoryBreakdown: json['category_breakdown'] != null
          ? Map<String, double>.from(
              (json['category_breakdown'] as Map).map(
                (k, v) => MapEntry(k.toString(), _parseDouble(v)),
              ),
            )
          : null,
      varietyBreakdown: json['variety_breakdown'] != null
          ? Map<String, double>.from(
              (json['variety_breakdown'] as Map).map(
                (k, v) => MapEntry(k.toString(), _parseDouble(v)),
              ),
            )
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'total_purchases': totalPurchases,
      'total_sales': totalSales,
      'gross_profit': grossProfit,
      'net_profit': netProfit,
      'purchase_count': purchaseCount,
      'sale_count': saleCount,
      'total_paddy_bought': totalPaddyBought,
      'total_rice_sold': totalRiceSold,
      'total_paddy_stock': totalPaddyStock,
      'total_rice_stock': totalRiceStock,
      'new_customers_count': newCustomersCount,
      'outstanding_receivables': outstandingReceivables,
      'outstanding_payables': outstandingPayables,
      'category_breakdown': categoryBreakdown,
      'variety_breakdown': varietyBreakdown,
    };
  }

  /// Copy with method
  ReportSummary copyWith({
    double? totalPurchases,
    double? totalSales,
    double? grossProfit,
    double? netProfit,
    int? purchaseCount,
    int? saleCount,
    double? totalPaddyBought,
    double? totalRiceSold,
    double? totalPaddyStock,
    double? totalRiceStock,
    int? newCustomersCount,
    double? outstandingReceivables,
    double? outstandingPayables,
    Map<String, double>? categoryBreakdown,
    Map<String, double>? varietyBreakdown,
  }) {
    return ReportSummary(
      totalPurchases: totalPurchases ?? this.totalPurchases,
      totalSales: totalSales ?? this.totalSales,
      grossProfit: grossProfit ?? this.grossProfit,
      netProfit: netProfit ?? this.netProfit,
      purchaseCount: purchaseCount ?? this.purchaseCount,
      saleCount: saleCount ?? this.saleCount,
      totalPaddyBought: totalPaddyBought ?? this.totalPaddyBought,
      totalRiceSold: totalRiceSold ?? this.totalRiceSold,
      totalPaddyStock: totalPaddyStock ?? this.totalPaddyStock,
      totalRiceStock: totalRiceStock ?? this.totalRiceStock,
      newCustomersCount: newCustomersCount ?? this.newCustomersCount,
      outstandingReceivables:
          outstandingReceivables ?? this.outstandingReceivables,
      outstandingPayables: outstandingPayables ?? this.outstandingPayables,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      varietyBreakdown: varietyBreakdown ?? this.varietyBreakdown,
    );
  }

  /// Parse helpers
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    return int.tryParse(value.toString()) ?? 0;
  }

  /// Get total transactions count
  int get totalTransactions => purchaseCount + saleCount;

  /// Get profit margin percentage
  double get profitMarginPercentage {
    if (totalSales == 0) return 0;
    return (grossProfit / totalSales) * 100;
  }

  /// Get formatted profit
  String get formattedProfit => 'Rs. ${grossProfit.toStringAsFixed(2)}';

  /// Get formatted purchases
  String get formattedPurchases => 'Rs. ${totalPurchases.toStringAsFixed(2)}';

  /// Get formatted sales
  String get formattedSales => 'Rs. ${totalSales.toStringAsFixed(2)}';

  /// Check if profitable
  bool get isProfitable => grossProfit > 0;

  @override
  List<Object?> get props => [
        totalPurchases,
        totalSales,
        grossProfit,
        netProfit,
        purchaseCount,
        saleCount,
        totalPaddyBought,
        totalRiceSold,
        totalPaddyStock,
        totalRiceStock,
        newCustomersCount,
        outstandingReceivables,
        outstandingPayables,
        categoryBreakdown,
        varietyBreakdown,
      ];
}

/// Individual report item (line item)
class ReportItem extends Equatable {
  final String id;
  final String label;
  final String? description;
  final double value;
  final double? previousValue; // For comparison
  final double? changePercentage;
  final String? unit;
  final Map<String, dynamic>? metadata;

  const ReportItem({
    required this.id,
    required this.label,
    this.description,
    required this.value,
    this.previousValue,
    this.changePercentage,
    this.unit,
    this.metadata,
  });

  /// Create ReportItem from JSON
  factory ReportItem.fromJson(Map<String, dynamic> json) {
    return ReportItem(
      id: json['id']?.toString() ?? '',
      label: json['label'] ?? '',
      description: json['description'],
      value: _parseDouble(json['value']),
      previousValue: _parseDoubleNullable(json['previous_value']),
      changePercentage: _parseDoubleNullable(json['change_percentage']),
      unit: json['unit'],
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'])
          : null,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'description': description,
      'value': value,
      'previous_value': previousValue,
      'change_percentage': changePercentage,
      'unit': unit,
      'metadata': metadata,
    };
  }

  /// Parse helpers
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    return _parseDouble(value);
  }

  /// Get formatted value
  String get formattedValue {
    if (unit == 'currency') {
      return 'Rs. ${value.toStringAsFixed(2)}';
    } else if (unit == 'kg') {
      return '${value.toStringAsFixed(2)} kg';
    } else if (unit == 'percentage') {
      return '${value.toStringAsFixed(1)}%';
    }
    return value.toStringAsFixed(2);
  }

  /// Get change indicator
  String get changeIndicator {
    if (changePercentage == null) return '';
    if (changePercentage! > 0) {
      return '↑ ${changePercentage!.toStringAsFixed(1)}%';
    }
    if (changePercentage! < 0) {
      return '↓ ${changePercentage!.abs().toStringAsFixed(1)}%';
    }
    return '→ 0%';
  }

  /// Check if positive change
  bool get isPositiveChange => (changePercentage ?? 0) > 0;

  /// Check if negative change
  bool get isNegativeChange => (changePercentage ?? 0) < 0;

  @override
  List<Object?> get props => [
        id,
        label,
        description,
        value,
        previousValue,
        changePercentage,
        unit,
        metadata,
      ];
}
