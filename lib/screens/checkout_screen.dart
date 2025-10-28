import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:longtea_mobile/models/cart.dart';
import 'package:longtea_mobile/models/cart_item.dart';
import 'package:longtea_mobile/models/order.dart';
import 'package:longtea_mobile/models/payment.dart';
import 'package:longtea_mobile/screens/main_navigation.dart';
import 'package:longtea_mobile/services/cart_service.dart';
import 'package:longtea_mobile/services/order_service.dart';
import 'package:longtea_mobile/services/payment_service.dart';
import 'package:url_launcher/url_launcher.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late Cart _cartSnapshot;
  late DateTime _pickupTime;

  bool _isSubmitting = false;
  Order? _order;
  PaymentIntent? _paymentIntent;
  PaymentStatus? _paymentStatus;
  String? _errorMessage;
  PaymentMethod _selectedMethod = PaymentMethod.telbirr;

  @override
  void initState() {
    super.initState();
    _cartSnapshot = widget.cart;
    _pickupTime = DateTime.now().add(const Duration(minutes: 30));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _order == null ? 'Checkout' : 'Order Placed',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1F2937),
          ),
        ),
      ),
      body: _order == null ? _buildCheckoutBody() : _buildSuccessBody(),
    );
  }

  Widget _buildCheckoutBody() {
    final cartItems = _cartSnapshot.items;
    final subtotal = _cartSnapshot.totalprice;
    const serviceCharge = 0.0;
    final total = subtotal + serviceCharge;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_errorMessage != null)
            _InfoBanner(message: _errorMessage!, isError: true),
          _buildStoreCard(),
          const SizedBox(height: 16),
          ...cartItems.map((item) => _buildItemCard(item)).toList(),
          const SizedBox(height: 16),
          _buildPickupCard(),
          const SizedBox(height: 16),
          _buildPaymentMethodCard(),
          const SizedBox(height: 16),
          _buildSummaryCard(
            subtotal: subtotal,
            serviceCharge: serviceCharge,
            total: total,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Confirm & Pay',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBody() {
    final order = _order!;
    final intent = _paymentIntent;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFDBEAFE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 32,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Order #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF374151),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (_errorMessage != null)
            _InfoBanner(message: _errorMessage!, isError: true),
          _buildOrderDetailsCard(order),
          const SizedBox(height: 16),
          _buildItemsSummaryCard(),
          const SizedBox(height: 16),
          _buildPaymentSummaryCard(intent),
          const SizedBox(height: 24),
          if (intent != null && intent.paymentUrl != null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _openPaymentUrl,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Open Payment Page',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          if (intent == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _retryPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E3A8A),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Retry Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          const SizedBox(height: 12),
          if (intent != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isSubmitting ? null : _refreshPaymentStatus,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF1E3A8A)),
                  foregroundColor: const Color(0xFF1E3A8A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF1E3A8A),
                          ),
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Refresh Payment Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          if (intent != null)
            TextButton(
              onPressed: _isSubmitting ? null : _retryPayment,
              child: const Text(
                'Retry Payment',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _isSubmitting ? null : _goHome,
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Location',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _cartSnapshot.storeName ?? 'Selected Store',
            style: const TextStyle(fontSize: 14, color: Color(0xFF374151)),
          ),
          if (_cartSnapshot.storeId != null) ...[
            const SizedBox(height: 4),
            Text(
              'Store ID: ${_cartSnapshot.storeId}',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemCard(CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
              image: item.productImage != null
                  ? DecorationImage(
                      image: NetworkImage(item.productImage!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productImage == null
                ? const Icon(Icons.image, color: Colors.grey)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Size: ${item.size} | Qty: ${item.quantity}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B7280),
                  ),
                ),
                if (item.toppings.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Toppings: ${item.toppings.join(", ")}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            _formatCurrency(item.totalPrice),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPickupCard() {
    final timeOfDay = TimeOfDay.fromDateTime(_pickupTime);
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: false,
    );
    final formattedDate =
        '${_pickupTime.day}/${_pickupTime.month}/${_pickupTime.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pickup Time',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF374151),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formattedTime,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _selectPickupTime,
                icon: const Icon(Icons.schedule, color: Color(0xFF1E3A8A)),
                label: const Text(
                  'Change',
                  style: TextStyle(
                    color: Color(0xFF1E3A8A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    final methods = PaymentMethod.values.toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ...methods.map(
            (method) => RadioListTile<PaymentMethod>(
              contentPadding: EdgeInsets.zero,
              value: method,
              groupValue: _selectedMethod,
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _selectedMethod = value;
                });
              },
              title: Text(
                method.label,
                style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
              ),
              activeColor: const Color(0xFF1E3A8A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required double subtotal,
    required double serviceCharge,
    required double total,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Summary',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildSummaryRow('Subtotal', subtotal),
          const SizedBox(height: 8),
          _buildSummaryRow('Service Charge', serviceCharge),
          const Divider(height: 32),
          _buildSummaryRow('Total', total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(Order order) {
    final timeOfDay = TimeOfDay.fromDateTime(order.pickupTime);
    final localizations = MaterialLocalizations.of(context);
    final formattedTime = localizations.formatTimeOfDay(
      timeOfDay,
      alwaysUse24HourFormat: false,
    );
    final formattedDate =
        '${order.pickupTime.day}/${order.pickupTime.month}/${order.pickupTime.year}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            label: 'Order ID',
            value: order.id,
            onCopy: () => _copyToClipboard('Order ID', order.id),
          ),
          const SizedBox(height: 8),
          _buildInfoRow(label: 'Status', value: order.status),
          const SizedBox(height: 8),
          _buildInfoRow(label: 'Pickup Date', value: formattedDate),
          const SizedBox(height: 8),
          _buildInfoRow(label: 'Pickup Time', value: formattedTime),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Paid',
                  style: TextStyle(fontSize: 14, color: Color(0xFF312E81)),
                ),
                Text(
                  _formatCurrency(order.total),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Items Ordered',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          ..._cartSnapshot.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.productName,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Size: ${item.size} | Qty: ${item.quantity}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatCurrency(item.totalPrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E3A8A),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(PaymentIntent? intent) {
    final status = _paymentStatus;
    final statusText =
        status?.status ?? (intent == null ? 'Not initiated' : 'Pending');
    final color = _statusColor(statusText);
    final paidAt = status?.paidAt;
    String? paidAtDisplay;

    if (paidAt != null) {
      paidAtDisplay =
          '${paidAt.day}/${paidAt.month}/${paidAt.year} ${paidAt.hour.toString().padLeft(2, '0')}:${paidAt.minute.toString().padLeft(2, '0')}';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(fontSize: 14, color: Color(0xFF374151)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(label: 'Method', value: _selectedMethod.label),
          if (intent != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Transaction ID',
              value: intent.transactionId,
              onCopy: () =>
                  _copyToClipboard('Transaction ID', intent.transactionId),
            ),
            if (intent.referenceCode != null &&
                intent.referenceCode!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildInfoRow(
                  label: 'Reference',
                  value: intent.referenceCode!,
                  onCopy: () =>
                      _copyToClipboard('Reference code', intent.referenceCode!),
                ),
              ),
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Amount',
              value: _formatCurrency(intent.amount),
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              label: 'Retry Count',
              value: intent.retryCount.toString(),
            ),
          ],
          if (status != null && paidAtDisplay != null) ...[
            const SizedBox(height: 8),
            _buildInfoRow(label: 'Paid At', value: paidAtDisplay),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: const Color(0xFF4B5563),
          ),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    VoidCallback? onCopy,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              if (onCopy != null) ...[
                const SizedBox(width: 4),
                InkWell(
                  onTap: onCopy,
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.copy, size: 16, color: Color(0xFF9CA3AF)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;

    if (_cartSnapshot.items.isEmpty) {
      _showSnackBar('Your cart is empty', isError: true);
      return;
    }
    if (_cartSnapshot.storeId == null || _cartSnapshot.storeId!.isEmpty) {
      _showSnackBar(
        'Missing store information. Please reload your cart.',
        isError: true,
      );
      return;
    }

    final minimumPickup = DateTime.now().add(const Duration(minutes: 5));
    if (_pickupTime.isBefore(minimumPickup)) {
      setState(() {
        _pickupTime = minimumPickup;
      });
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = _cartSnapshot.items
          .map(OrderItemPayload.fromCartItem)
          .toList();

      final order = await OrderService.instance.createOrder(
        storeId: _cartSnapshot.storeId!,
        pickupTime: _pickupTime,
        items: payload,
      );

      PaymentIntent? intent;
      String? paymentError;

      try {
        intent = await PaymentService.instance.initiatePayment(
          orderId: order.id,
          method: _selectedMethod,
        );
      } on PaymentException catch (e) {
        paymentError = e.message;
        _showSnackBar(paymentError, isError: true);
      } catch (e) {
        paymentError = 'Payment initiation failed: $e';
        _showSnackBar(paymentError, isError: true);
      }

      await _clearCartSilently();

      if (!mounted) return;
      setState(() {
        _order = order;
        _paymentIntent = intent;
        _paymentStatus = null;
        _errorMessage = paymentError;
      });
    } on OrderException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
      _showSnackBar(e.toString(), isError: true);
    } catch (e) {
      if (!mounted) return;
      final message = 'Checkout failed: $e';
      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _retryPayment() async {
    if (_order == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final intent = await PaymentService.instance.initiatePayment(
        orderId: _order!.id,
        method: _selectedMethod,
      );
      if (!mounted) return;
      setState(() {
        _paymentIntent = intent;
        _paymentStatus = null;
      });
      _showSnackBar('Payment link refreshed');
    } on PaymentException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
      });
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      final message = 'Payment retry failed: $e';
      setState(() {
        _errorMessage = message;
      });
      _showSnackBar(message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _refreshPaymentStatus() async {
    if (_paymentIntent == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final status = await PaymentService.instance.getPaymentStatus(
        _paymentIntent!.transactionId,
      );
      if (!mounted) return;
      setState(() {
        _paymentStatus = status;
        _errorMessage = null;
      });
      _showSnackBar('Payment status updated');
    } on PaymentException catch (e) {
      if (!mounted) return;
      _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Unable to refresh payment status: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _selectPickupTime() async {
    final currentDate = DateTime.now();
    final initialDate = _pickupTime.isAfter(currentDate)
        ? _pickupTime
        : currentDate.add(const Duration(minutes: 30));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: currentDate,
      lastDate: currentDate.add(const Duration(days: 7)),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (time == null || !mounted) return;

    final selected = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      _pickupTime = selected;
    });
  }

  Future<void> _openPaymentUrl() async {
    final url = _paymentIntent?.paymentUrl;
    if (url == null || url.isEmpty) {
      _showSnackBar('No payment URL available yet.', isError: true);
      return;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      _showSnackBar('Invalid payment URL: $url', isError: true);
      return;
    }

    final canLaunch = await canLaunchUrl(uri);
    if (!canLaunch) {
      _showSnackBar('Cannot open payment link on this device.', isError: true);
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _clearCartSilently() async {
    try {
      await CartService.instance.clearCart();
    } catch (_) {
      CartService.instance.clearLocalCart();
    }
  }

  void _copyToClipboard(String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    _showSnackBar('$label copied to clipboard');
  }

  void _goHome() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const MainNavigation(initialTab: 0),
      ),
      (route) => false,
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF1E3A8A),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
      case 'paid':
      case 'confirmed':
        return const Color(0xFF15803D);
      case 'failed':
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF1E3A8A);
    }
  }

  String _formatCurrency(double value) {
    return '${value.toStringAsFixed(2)} ETB';
  }
}

class _InfoBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const _InfoBanner({required this.message, this.isError = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError ? const Color(0xFFFEE2E2) : const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isError ? const Color(0xFFDC2626) : const Color(0xFF3730A3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: isError ? const Color(0xFFB91C1C) : const Color(0xFF312E81),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: isError
                    ? const Color(0xFF7F1D1D)
                    : const Color(0xFF312E81),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
