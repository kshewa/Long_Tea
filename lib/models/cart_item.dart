class CartItem {
  final String productId;
  final String name;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;

  const CartItem({
    required this.productId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
  });

  double get total => unitPrice * quantity;
}