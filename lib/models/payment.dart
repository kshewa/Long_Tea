class PaymentIntent {
  final String orderId;
  final String transactionId;
  final String? referenceCode;
  final double amount;
  final int retryCount;
  final String? paymentUrl;

  const PaymentIntent({
    required this.orderId,
    required this.transactionId,
    this.referenceCode,
    required this.amount,
    required this.retryCount,
    this.paymentUrl,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> json) {
    return PaymentIntent(
      orderId: json['orderId']?.toString() ?? '',
      transactionId: json['transactionId']?.toString() ?? '',
      referenceCode: json['referenceCode']?.toString(),
      amount: _asDouble(json['amount']),
      retryCount: json['retryCount'] is num
          ? (json['retryCount'] as num).toInt()
          : int.tryParse(json['retryCount']?.toString() ?? '') ?? 0,
      paymentUrl: json['paymentUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'transactionId': transactionId,
      'referenceCode': referenceCode,
      'amount': amount,
      'retryCount': retryCount,
      'paymentUrl': paymentUrl,
    };
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class PaymentStatus {
  final String transactionId;
  final String status;
  final String orderStatus;
  final double amount;
  final int retryCount;
  final DateTime? paidAt;
  final String orderId;

  const PaymentStatus({
    required this.transactionId,
    required this.status,
    required this.orderStatus,
    required this.amount,
    required this.retryCount,
    required this.orderId,
    this.paidAt,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;

    return PaymentStatus(
      transactionId: data['transactionId']?.toString() ?? '',
      status: data['Paymentstatus']?.toString() ?? 'pending',
      orderStatus: data['orderStatus']?.toString() ?? 'pending',
      amount: _asDouble(data['amount']),
      retryCount: data['retryCount'] is num
          ? (data['retryCount'] as num).toInt()
          : int.tryParse(data['retryCount']?.toString() ?? '') ?? 0,
      orderId: data['orderId']?.toString() ?? '',
      paidAt: _parseDate(data['paidAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  static double _asDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

enum PaymentMethod {
  telbirr('telbirr', 'Telebirr'),
  mobileBanking('mobilebanking', 'Mobile Banking'),
  cash('cash', 'Cash'),
  card('card', 'Card');

  final String value;
  final String label;

  const PaymentMethod(this.value, this.label);
}
