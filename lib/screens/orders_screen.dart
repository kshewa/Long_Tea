import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:longtea_mobile/models/order.dart';
import 'package:longtea_mobile/services/order_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final DateFormat _dateFormat = DateFormat('MMM d, h:mm a');

  bool _isLoading = true;
  String? _errorMessage;
  List<Order> _orders = const [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final orders = await OrderService.instance.fetchOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
        _errorMessage = null;
      });
    } on OrderException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to load orders: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _loadOrders(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          children: [
            const SizedBox(height: 120),
            Center(
              child: Column(
                children: [
                  const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No orders yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your recent orders will appear here.',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final order = _orders[index];
          return _OrderCard(
            order: order,
            formattedPickup: _formatDate(order.pickupTime),
            formattedCreated: _formatDate(order.createdAt),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: _orders.length,
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unknown';
    return _dateFormat.format(date.toLocal());
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  final String formattedPickup;
  final String formattedCreated;

  const _OrderCard({
    required this.order,
    required this.formattedPickup,
    required this.formattedCreated,
  });

  @override
  Widget build(BuildContext context) {
    final items = order.items;
    final color = _statusColor(order.status);
    final paymentStatus = order.paymentStatus;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.storeName ?? 'Store ${order.storeId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Order #${order.id.substring(0, 6).toUpperCase()}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.schedule, size: 18, color: Color(0xFF1E3A8A)),
                const SizedBox(width: 6),
                Text(
                  'Pickup: $formattedPickup',
                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: Color(0xFF6B7280),
                ),
                const SizedBox(width: 6),
                Text(
                  'Placed: $formattedCreated',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isNotEmpty) _buildItemsPreview(items),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${items.length} item${items.length == 1 ? '' : 's'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  '${order.total.toStringAsFixed(2)} ETB',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E3A8A),
                  ),
                ),
              ],
            ),
            if (paymentStatus != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 18,
                    color: _paymentColor(paymentStatus),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Payment: ${paymentStatus.toUpperCase()}',
                    style: TextStyle(
                      fontSize: 13,
                      color: _paymentColor(paymentStatus),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildItemsPreview(List<OrderItem> items) {
    final previewItems = items.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final item in previewItems) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
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
                    ? const Icon(Icons.local_cafe, color: Color(0xFF6B7280))
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName ?? 'Product ${item.productId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Size: ${item.size} • Qty: ${item.quantity}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.totalPrice.toStringAsFixed(2)} ETB',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item != previewItems.last) const SizedBox(height: 8),
        ],
        if (items.length > previewItems.length)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+${items.length - previewItems.length} more item(s)',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'preparing':
      case 'ready_for_pickup':
        return const Color(0xFF1E3A8A);
      case 'completed':
        return const Color(0xFF047857);
      case 'cancelled':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }

  static Color _paymentColor(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return const Color(0xFF047857);
      case 'failed':
        return const Color(0xFFB91C1C);
      default:
        return const Color(0xFF6B7280);
    }
  }
}
