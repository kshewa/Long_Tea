import 'package:flutter/foundation.dart';
import 'package:my_pro9/models/cart_item.dart';

class CartService {
  CartService._();
  static final CartService instance = CartService._();

  final ValueNotifier<List<CartItem>> itemsNotifier = ValueNotifier<List<CartItem>>(<CartItem>[]);

  List<CartItem> get items => itemsNotifier.value;

  void addOrIncrease(CartItem item) {
    final list = List<CartItem>.from(itemsNotifier.value);
    final i = list.indexWhere((e) => e.productId == item.productId);
    if (i >= 0) {
      final e = list[i];
      list[i] = CartItem(
        productId: e.productId,
        name: e.name,
        unitPrice: e.unitPrice,
        quantity: e.quantity + item.quantity,
        imageUrl: e.imageUrl,
      );
    } else {
      list.add(item);
    }
    itemsNotifier.value = list;
  }

  void remove(String productId) {
    final list = List<CartItem>.from(itemsNotifier.value)..removeWhere((e) => e.productId == productId);
    itemsNotifier.value = list;
  }

  void clear() => itemsNotifier.value = <CartItem>[];

  int get totalItems => items.fold(0, (s, e) => s + e.quantity);
  double get subtotal => items.fold(0.0, (s, e) => s + e.total);
}