import 'package:flutter/material.dart';

class PreOrderScreen extends StatelessWidget {
  final List<Map<String, dynamic>> preOrders;
  const PreOrderScreen({required this.preOrders, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pre-Orders')),
      body: preOrders.isEmpty
          ? const Center(child: Text('No pre-orders yet.'))
          : ListView.builder(
              itemCount: preOrders.length,
              itemBuilder: (context, index) {
                final order = preOrders[index];
                final items = order['items'] as List<Map<String, dynamic>>;
                final total = order['total'];
                final timestamp = order['timestamp'] as DateTime;
                return Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    title: Text('Order #${index + 1}'),
                    subtitle: Text(
                        'Total: $total ETB\n${timestamp.toLocal().toString().split('.')[0]}'),
                    trailing: Text('${items.length} items'),
                  ),
                );
              },
            ),
    );
  }
}