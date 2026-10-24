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

  factory OrderItemEntry.fromMap(Map<String, dynamic> map) {
    return OrderItemEntry(
      itemId: map['itemId']?.toString() ?? '',
      itemName: (map['itemName'] ?? map['name'])?.toString() ?? 'Item',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      priceLKR: (map['priceLKR'] as num?)?.toDouble() ?? 0.0,
      type: map['type']?.toString() ?? 'purchase',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'name': itemName,
      'quantity': quantity,
      'priceLKR': priceLKR,
      'type': type,
    };
  }
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

  factory OrderModel.fromMap(Map<String, dynamic> map, String docId) {
    var rawItems = map['items'];
    List<OrderItemEntry> parsedItems = [];
    if (rawItems is List) {
      parsedItems = rawItems
          .map((i) => OrderItemEntry.fromMap(Map<String, dynamic>.from(i as Map)))
          .toList();
    }

    return OrderModel(
      id: docId,
      orderCode: map['orderCode']?.toString() ?? docId,
      customerName: (map['customerName'] ?? map['contactName'])?.toString() ?? 'Customer',
      customerPhone: (map['customerPhone'] ?? map['contactPhone'])?.toString() ?? '',
      deliveryAddress: map['deliveryAddress']?.toString() ?? '',
      district: map['district']?.toString() ?? 'Colombo',
      items: parsedItems,
      totalAmountLKR: ((map['totalAmountLKR'] ?? map['total']) as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod']?.toString() ?? 'cod',
      paymentStatus: map['paymentStatus']?.toString() ?? 'pending_verification',
      bankSlipUrl: map['bankSlipUrl']?.toString(),
      orderStatus: (map['orderStatus'] ?? map['status'])?.toString() ?? 'pending',
      isRental: map['isRental'] as bool? ?? false,
      rentalStartDate: map['rentalStartDate']?.toString(),
      rentalEndDate: map['rentalEndDate']?.toString(),
      securityDepositLKR: (map['securityDepositLKR'] as num?)?.toDouble(),
      createdAt: map['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderCode': orderCode,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'deliveryAddress': deliveryAddress,
      'district': district,
      'items': items.map((i) => i.toMap()).toList(),
      'totalAmountLKR': totalAmountLKR,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'bankSlipUrl': bankSlipUrl,
      'orderStatus': orderStatus,
      'status': orderStatus,
      'isRental': isRental,
      'rentalStartDate': rentalStartDate,
      'rentalEndDate': rentalEndDate,
      'securityDepositLKR': securityDepositLKR,
      'createdAt': createdAt,
    };
  }
}
