import 'package:flutter/material.dart';
import 'package:my_pro9/services/cart_service.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = CartService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: ValueListenableBuilder(
        valueListenable: cart.itemsNotifier,
        builder: (context, items, _) {
          final list = items as List;
          if (list.isEmpty) return const Center(child: Text('Your cart is empty'));
          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: list.length,
                  itemBuilder: (_, i) {
                    final it = list[i];
                    return ListTile(
                      leading: it.imageUrl != null ? Image.network(it.imageUrl!) : null,
                      title: Text(it.name),
                      subtitle: Text('x${it.quantity}'),
                      trailing: Text('\$${(it.unitPrice * it.quantity).toStringAsFixed(2)}'),
                      onLongPress: () => cart.remove(it.productId),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text('\$${cart.subtotal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          cart.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cart cleared!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Clear Cart'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Place order logic goes here; for now we just clear
                          cart.clear();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        },
                        child: const Text('Place Order'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}