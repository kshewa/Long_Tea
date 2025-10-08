import 'package:flutter/material.dart';
import 'package:longtea_mobile/services/cart_service.dart';
import 'package:longtea_mobile/models/cart_item.dart';

class ProductCard extends StatefulWidget {
  final String name;
  final String subtitle;
  final String price;
  final String imagePath;
  final bool showSizeBadges;
  final VoidCallback onAddPressed;
  final VoidCallback onFavoritePressed;
  final bool isFavorite;

  const ProductCard({
    super.key,
    required this.name,
    required this.subtitle,
    required this.price,
    required this.imagePath,
    required this.onAddPressed,
    required this.onFavoritePressed,
    required this.isFavorite,
    this.showSizeBadges = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Section - Fixed to be more visible
          Stack(
            children: [
              Container(
                height: 100, // Increased from 80 to 100 for better visibility
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    widget.imagePath,
                    fit:
                        BoxFit.contain, // Changed to contain to show full image
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
                ),
              ),

              Positioned(
                top: 4,
                right: 4,
                child: GestureDetector(
                  onTap: widget.onFavoritePressed,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(1, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: widget.isFavorite ? Colors.red : Colors.grey,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Size badges
              if (widget.showSizeBadges)
                Positioned(
                  bottom: 4,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSizeBadge('M'),
                      const SizedBox(width: 8),
                      _buildSizeBadge('L'),
                    ],
                  ),
                ),
            ],
          ),

          // Product info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 248, 3, 3),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  widget.subtitle,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 5, 27, 88),
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        CartService.instance.addOrIncrease(
                          CartItem(
                            productId: widget
                                .name, // replace with real product id if available
                            name: widget.name,
                            unitPrice:
                                double.tryParse(
                                  widget.price.replaceAll(
                                    RegExp(r'[^0-9\.]'),
                                    '',
                                  ),
                                ) ??
                                0,
                            quantity: 1,
                            imageUrl: widget.imagePath,
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Added to cart'),
                            backgroundColor: Colors.green,
                          ),
                        );
                        // still call external callback if provided
                        widget.onAddPressed();
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: Color.fromARGB(255, 5, 27, 88),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeBadge(String size) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: size == 'M'
            ? const Color.fromARGB(255, 5, 27, 88)
            : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          size,
          style: TextStyle(
            color: size == 'M' ? Colors.white : Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
