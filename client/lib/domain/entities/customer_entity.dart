// lib/domain/entities/customer_entity.dart

import 'package:equatable/equatable.dart';
import '../../core/constants/enums.dart';

/// Customer Entity - Core business representation of a customer
class CustomerEntity extends Equatable {
  final String id;
  final String? serverId;
  final String name;
  final String phone;
  final String? secondaryPhone;
  final String? email;
  final String? address;
  final String? city;
  final String? nic;
  final String? notes;
  final double balance; // + means they owe us, - means we owe them
  final CustomerType customerType;
  final bool isActive;

  const CustomerEntity({
    required this.id,
    this.serverId,
    required this.name,
    required this.phone,
    this.secondaryPhone,
    this.email,
    this.address,
    this.city,
    this.nic,
    this.notes,
    this.balance = 0,
    this.customerType = CustomerType.seller,
    this.isActive = true,
  });

  /// Check if customer has outstanding balance
  bool get hasOutstandingBalance => balance != 0;

  /// Check if customer owes us money (positive balance)
  bool get customerOwesUs => balance > 0;

  /// Check if we owe the customer money (negative balance)
  bool get weOweCustomer => balance < 0;

  /// Get absolute balance amount
  double get absoluteBalance => balance.abs();

  /// Get formatted balance
  String get formattedBalance {
    final prefix = balance >= 0 ? '' : '-';
    return '${prefix}Rs. ${absoluteBalance.toStringAsFixed(2)}';
  }

  /// Get balance status text
  String get balanceStatus {
    if (balance == 0) return 'Settled';
    if (customerOwesUs) return 'Receivable';
    return 'Payable';
  }

  /// Get user initials for avatar fallback
  String get initials {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return 'C';

    final parts = trimmedName.split(' ');
    if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return trimmedName[0].toUpperCase();
  }

  /// Get formatted phone number
  String get formattedPhone {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');
    if (cleanPhone.length == 10) {
      return '${cleanPhone.substring(0, 3)} ${cleanPhone.substring(3, 6)} ${cleanPhone.substring(6)}';
    }
    return phone;
  }

  /// Get short address
  String get shortAddress {
    if (city != null && city!.isNotEmpty) return city!;
    if (address == null || address!.isEmpty) return '';
    final firstLine = address!.split('\n').first;
    if (firstLine.length <= 30) return firstLine;
    return '${firstLine.substring(0, 27)}...';
  }

  /// Check if customer can be used for buying transactions
  bool get canBuyFrom => isActive && customerType.canBuy;

  /// Check if customer can be used for selling transactions
  bool get canSellTo => isActive && customerType.canSell;

  /// Create a copy with updated fields
  CustomerEntity copyWith({
    String? id,
    String? serverId,
    String? name,
    String? phone,
    String? secondaryPhone,
    String? email,
    String? address,
    String? city,
    String? nic,
    String? notes,
    double? balance,
    CustomerType? customerType,
    bool? isActive,
  }) {
    return CustomerEntity(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      secondaryPhone: secondaryPhone ?? this.secondaryPhone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      nic: nic ?? this.nic,
      notes: notes ?? this.notes,
      balance: balance ?? this.balance,
      customerType: customerType ?? this.customerType,
      isActive: isActive ?? this.isActive,
    );
  }

  /// Create an empty customer entity
  factory CustomerEntity.empty() {
    return const CustomerEntity(
      id: '',
      name: '',
      phone: '',
    );
  }

  /// Check if entity is empty/invalid
  bool get isEmpty => id.isEmpty;
  bool get isNotEmpty => id.isNotEmpty;

  @override
  List<Object?> get props => [
        id,
        serverId,
        name,
        phone,
        secondaryPhone,
        email,
        address,
        city,
        nic,
        notes,
        balance,
        customerType,
        isActive,
      ];
}
