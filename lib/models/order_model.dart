class OrderItemEntry {
  final String itemId;
  final String itemName;
  final int quantity;
  final double priceLKR;
  final String type; // purchase or rental

  OrderItemEntry({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.priceLKR,
    required this.type,
  });
}

class OrderModel {
  final String id;
  final String orderCode;
  final String customerName;
  final String customerPhone;
  final String deliveryAddress;
  final String district;
  final List<OrderItemEntry> items;
  final double totalAmountLKR;
  final String paymentMethod; // cod, bank_transfer, online_card
  final String paymentStatus; // paid, pending_verification, cod_pending
  final String? bankSlipUrl;
  final String orderStatus; // pending, dispatched, delivered, cancelled
  final bool isRental;
  final String? rentalStartDate;
  final String? rentalEndDate;
  final double? securityDepositLKR;
  final String createdAt;

  OrderModel({
    required this.id,
    required this.orderCode,
    required this.customerName,
    required this.customerPhone,
    required this.deliveryAddress,
    required this.district,
    required this.items,
    required this.totalAmountLKR,
    required this.paymentMethod,
    required this.paymentStatus,
    this.bankSlipUrl,
    required this.orderStatus,
    this.isRental = false,
    this.rentalStartDate,
    this.rentalEndDate,
    this.securityDepositLKR,
    required this.createdAt,
  });

  OrderModel copyWith({
    String? id,
    String? orderCode,
    String? customerName,
    String? customerPhone,
    String? deliveryAddress,
    String? district,
    List<OrderItemEntry>? items,
    double? totalAmountLKR,
    String? paymentMethod,
    String? paymentStatus,
    String? bankSlipUrl,
    String? orderStatus,
    bool? isRental,
    String? rentalStartDate,
    String? rentalEndDate,
    double? securityDepositLKR,
    String? createdAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      orderCode: orderCode ?? this.orderCode,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      district: district ?? this.district,
      items: items ?? this.items,
      totalAmountLKR: totalAmountLKR ?? this.totalAmountLKR,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      bankSlipUrl: bankSlipUrl ?? this.bankSlipUrl,
      orderStatus: orderStatus ?? this.orderStatus,
      isRental: isRental ?? this.isRental,
      rentalStartDate: rentalStartDate ?? this.rentalStartDate,
      rentalEndDate: rentalEndDate ?? this.rentalEndDate,
      securityDepositLKR: securityDepositLKR ?? this.securityDepositLKR,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
