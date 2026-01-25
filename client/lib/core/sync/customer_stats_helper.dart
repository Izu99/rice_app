// The entire content of this file is commented out because it relies on DbHelper,
// which is part of the removed local SQLite storage.
// This file is no longer relevant for the API-only architecture.

/*
import 'package:logger/logger.dart';
import '../database/db_helper.dart';

class CustomerStatsHelper {
  final DbHelper _dbHelper;
  final Logger _logger = Logger();

  CustomerStatsHelper({required DbHelper dbHelper}) : _dbHelper = dbHelper;

  /// Get customer statistics (total bags, total spent, discount)
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    _logger.i('📊 Calculating stats for customer: $customerId');

    // Get all transactions for this customer
    final transactions = await _dbHelper.query(
      'transactions',
      where: 'customerId = ? AND isActive = 1',
      whereArgs: [customerId],
    );

    if (transactions.isEmpty) {
      _logger.i('   No transactions found');
      return {
        'customerId': customerId,
        'totalBags': 0.0,
        'totalSpent': 0.0,
        'purchaseCount': 0,
        'lastPurchaseDate': null,
        'discountPercentage': 0.0,
        'discountReason': 'New customer',
      };
    }

    // Calculate totals
    double totalBags = 0;
    double totalSpent = 0;
    DateTime? lastPurchaseDate;

    for (final tx in transactions) {
      final bags = (tx['totalBags'] ?? 0) as num;
      final amount = (tx['totalAmount'] ?? 0) as num;

      totalBags += bags.toDouble();
      totalSpent += amount.toDouble();

      final txDate = DateTime.parse(tx['createdAt'] ?? '');
      if (lastPurchaseDate == null || txDate.isAfter(lastPurchaseDate)) {
        lastPurchaseDate = txDate;
      }
    }

    // Calculate discount based on total bags
    double discount = 0.0;
    String reason = '';

    if (totalBags >= 50) {
      discount = 0.15;
      reason = 'Loyal customer (50+ bags)';
    } else if (totalBags >= 20) {
      discount = 0.10;
      reason = 'Regular customer (20+ bags)';
    } else if (totalBags >= 10) {
      discount = 0.05;
      reason = 'Frequent customer (10+ bags)';
    } else if (totalBags > 0) {
      discount = 0.0;
      reason = 'New customer';
    }

    final stats = {
      'customerId': customerId,
      'totalBags': totalBags,
      'totalSpent': totalSpent,
      'purchaseCount': transactions.length,
      'lastPurchaseDate': lastPurchaseDate?.toIso8601String(),
      'discountPercentage': discount,
      'discountReason': reason,
    };

    _logger.i('   ✅ Stats calculated:');
    _logger.i('      Total bags: $totalBags');
    _logger.i('      Total spent: $totalSpent');
    _logger.i('      Discount: ${(discount * 100).toStringAsFixed(0)}%');

    return stats;
  }

  /// Update customer record with calculated stats
  Future<void> updateCustomerStats(String customerId) async {
    _logger.i('📝 Updating customer stats: $customerId');

    final stats = await getCustomerStats(customerId);

    await _dbHelper.update(
      'customers',
      {
        'totalPurchased': stats['totalBags'],
        'totalSpent': stats['totalSpent'],
        'purchaseCount': stats['purchaseCount'],
        'lastPurchaseDate': stats['lastPurchaseDate'],
        'discountPercentage': stats['discountPercentage'],
        'discountReason': stats['discountReason'],
        'updatedAt': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [customerId],
    );

    _logger.i('   ✅ Customer stats updated');
  }

  /// Get customer details with stats
  Future<Map<String, dynamic>?> getCustomerWithStats(String customerId) async {
    _logger.i('👥 Fetching customer with stats: $customerId');

    final customers = await _dbHelper.query(
      'customers',
      where: 'id = ? AND isActive = 1',
      whereArgs: [customerId],
    );

    if (customers.isEmpty) {
      _logger.w('   Customer not found');
      return null;
    }

    final customer = customers.first;
    final stats = await getCustomerStats(customerId);

    return {
      ...customer,
      ...stats,
    };
  }

  /// Get all customers with stats
  Future<List<Map<String, dynamic>>> getAllCustomersWithStats() async {
    _logger.i('👥 Fetching all customers with stats');

    final customers = await _dbHelper.query(
      'customers',
      where: 'isActive = 1',
      orderBy: 'name ASC',
    );

    final result = <Map<String, dynamic>>[];

    for (final customer in customers) {
      final stats = await getCustomerStats(customer['id']);
      result.add({...customer, ...stats});
    }

    _logger.i('   ✅ Fetched ${result.length} customers');
    return result;
  }

  /// Get top customers by purchase volume
  Future<List<Map<String, dynamic>>> getTopCustomers({int limit = 10}) async {
    _logger.i('🏆 Fetching top $limit customers');

    final customers = await getAllCustomersWithStats();

    // Sort by total bags (descending)
    customers.sort((a, b) {
      final bagsA = (a['totalBags'] ?? 0) as num;
      final bagsB = (b['totalBags'] ?? 0) as num;
      return bagsB.compareTo(bagsA);
    });

    final top = customers.take(limit).toList();
    _logger.i('   ✅ Top customers:');
    for (final customer in top) {
      _logger.i('      ${customer['name']}: ${customer['totalBags']} bags');
    }

    return top;
  }

  /// Get customers by discount tier
  Future<Map<String, List<Map<String, dynamic>>>> getCustomersByDiscountTier() async {
    _logger.i('💰 Grouping customers by discount tier');

    final customers = await getAllCustomersWithStats();

    final tiers = {
      'loyal': <Map<String, dynamic>>[],      // 15% discount
      'regular': <Map<String, dynamic>>[],    // 10% discount
      'frequent': <Map<String, dynamic>>[],   // 5% discount
      'new': <Map<String, dynamic>>[],        // 0% discount
    };

    for (final customer in customers) {
      final discount = (customer['discountPercentage'] ?? 0) as num;

      if (discount >= 0.15) {
        tiers['loyal']!.add(customer);
      } else if (discount >= 0.10) {
        tiers['regular']!.add(customer);
      } else if (discount >= 0.05) {
        tiers['frequent']!.add(customer);
      } else {
        tiers['new']!.add(customer);
      }
    }

    _logger.i('   ✅ Customers by tier:');
    _logger.i('      Loyal (15%): ${tiers['loyal']!.length}');
    _logger.i('      Regular (10%): ${tiers['regular']!.length}');
    _logger.i('      Frequent (5%): ${tiers['frequent']!.length}');
    _logger.i('      New (0%): ${tiers['new']!.length}');

    return tiers;
  }

  /// Calculate discount for a transaction
  Future<double> getDiscountForCustomer(String customerId) async {
    final stats = await getCustomerStats(customerId);
    return (stats['discountPercentage'] ?? 0) as double;
  }

  /// Apply discount to price
  double applyDiscount(double price, double discountPercentage) {
    return price * (1 - discountPercentage);
  }

  /// Get customer transaction history
  Future<List<Map<String, dynamic>>> getCustomerTransactions(String customerId) async {
    _logger.i('📜 Fetching transactions for customer: $customerId');

    final transactions = await _dbHelper.query(
      'transactions',
      where: 'customerId = ? AND isActive = 1',
      whereArgs: [customerId],
      orderBy: 'createdAt DESC',
    );

    _logger.i('   ✅ Found ${transactions.length} transactions');
    return transactions;
  }

  /// Get customer transaction details with items
  Future<List<Map<String, dynamic>>> getCustomerTransactionDetails(String customerId) async {
    _logger.i('📋 Fetching transaction details for customer: $customerId');

    final transactions = await getCustomerTransactions(customerId);
    final result = <Map<String, dynamic>>[];

    for (final tx in transactions) {
      final items = await _dbHelper.query(
        'transaction_items',
        where: 'transactionId = ?',
        whereArgs: [tx['id']],
      );

      result.add({
        ...tx,
        'items': items,
      });
    }

    _logger.i('   ✅ Fetched ${result.length} transactions with items');
    return result;
  }

  /// Update all customer stats (call after sync)
  Future<void> updateAllCustomerStats() async {
    _logger.i('🔄 Updating all customer stats');

    final customers = await _dbHelper.query('customers', where: 'isActive = 1');

    for (final customer in customers) {
      await updateCustomerStats(customer['id']);
    }

    _logger.i('   ✅ Updated ${customers.length} customers');
  }

  /// Get customer summary for display
  Future<String> getCustomerSummary(String customerId) async {
    final customer = await getCustomerWithStats(customerId);

    if (customer == null) return 'Customer not found';

    final name = customer['name'] ?? 'Unknown';
    final phone = customer['phone'] ?? 'N/A';
    final totalBags = (customer['totalBags'] ?? 0).toStringAsFixed(1);
    final totalSpent = (customer['totalSpent'] ?? 0).toStringAsFixed(0);
    final purchaseCount = customer['purchaseCount'] ?? 0;
    final discount = ((customer['discountPercentage'] ?? 0) * 100).toStringAsFixed(0);
    final reason = customer['discountReason'] ?? 'N/A';

    return '''
╔════════════════════════════════════╗
║     CUSTOMER DETAILS               ║
╠════════════════════════════════════╣
║ Name: $name
║ Phone: $phone
║
║ PURCHASE HISTORY:
║ • Total Bags: $totalBags
║ • Total Spent: Rs. $totalSpent
║ • Purchases: $purchaseCount
║
║ DISCOUNT:
║ • Percentage: $discount%
║ • Reason: $reason
╚════════════════════════════════════╝
''';
  }
}
*/

