import 'package:flutter/material.dart';
import 'package:longtea_mobile/services/api_service.dart';
import 'package:longtea_mobile/models/product.dart';
import 'package:longtea_mobile/screens/checkout_screen.dart';
import '../widgets/category_tab.dart';
import '../widgets/product_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool showCartSummary = false;

  // FIX: Initialize productList to avoid LateInitializationError
  List<Product> productList = [];

  // Track favorite status for products
  Map<String, bool> favorites = {
    'Matcha Milk Tea': true,
    'Boba Tea': false,
    'Red Bean Milk Tea': false,
    'Pudding with Ice': true,
    'Signature Milk Tea': false,
    'Milk tea': false,
  };

  void addToCart(String name, String subtitle, String price) {
    setState(() {
      cartItems.add({'name': name, 'subtitle': subtitle, 'price': price});
      showCartSummary = true;
    });
  }

  void clearCart() {
    setState(() {
      cartItems.clear();
      showCartSummary = false;
    });
  }

  void toggleFavorite(String productName) {
    setState(() {
      favorites[productName] = !(favorites[productName] ?? false);
    });
  }

  @override
  void initState() {
    super.initState();
    _loadProductsSafely();
  }

  Future<void> _loadProductsSafely() async {
    try {
      final products = await fetchProducts();
      if (!mounted) return;
      setState(() {
        productList = products;
      });
    } catch (e) {
      // Keep the app alive and show an empty state if loading fails
      if (!mounted) return;
      setState(() {
        productList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = cartItems.length * 110.0;
    String firstItemName = cartItems.isNotEmpty ? cartItems[0]['name'] : '';

    return Scaffold(
      backgroundColor: const Color(0xFF1E3A8A),
      body: SafeArea(
        child: Column(
          children: [
            // Header section
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: AssetImage(
                          'assets/images/profile.png',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Betty Tesfaye',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                'Dembel, Addis Ababa',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: Colors.white,
                                size: 16,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: TextField(
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search Tea',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Colors.white,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Stack(
                children: [
                  // White background
                  Positioned.fill(
                    top: 60,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                  ),

                  // Banner image (increased size, no overflow)
                  Positioned(
                    top: 0,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 200, // Increased height
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/banner.png'),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Content below banner
                  Positioned.fill(
                    top: 180, // Adjusted for increased banner height
                    child: productList.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                // Category tabs
                                SizedBox(
                                  height: 90,
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.keyboard_arrow_left,
                                        color: Color(0xFF1E3A8A),
                                        size: 20,
                                      ),
                                      Expanded(
                                        child: SingleChildScrollView(
                                          scrollDirection: Axis.horizontal,
                                          child: Row(
                                            children: const [
                                              CategoryTab(
                                                title: 'All Tea',
                                                isSelected: true,
                                              ),
                                              SizedBox(width: 8),
                                              CategoryTab(
                                                title: 'Smoothie Series',
                                                isSelected: false,
                                              ),
                                              SizedBox(width: 8),
                                              CategoryTab(
                                                title: 'Fresh Ice Cream',
                                                isSelected: false,
                                              ),
                                              SizedBox(width: 8),
                                              CategoryTab(
                                                title: 'Kashmiri Tea',
                                                isSelected: false,
                                              ),
                                              SizedBox(width: 8),
                                              CategoryTab(
                                                title: 'Masala Tea',
                                                isSelected: false,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Products grid
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                  ),
                                  child: GridView.builder(
                                    itemCount: productList.length,
                                    shrinkWrap: true, // ✅ important
                                    physics:
                                        const NeverScrollableScrollPhysics(), // ✅ important
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 10,
                                          crossAxisSpacing: 10,
                                          childAspectRatio: 0.7,
                                        ),
                                    itemBuilder: (context, index) {
                                      final product = productList[index];
                                      final hasSizes = product.sizes.isNotEmpty;
                                      final firstPrice = hasSizes
                                          ? product.sizes.first.price.toString()
                                          : '0';
                                      final imageUrl =
                                          (product.image.url.isNotEmpty)
                                          ? product.image.url
                                          : 'https://via.placeholder.com/300x300.png?text=No+Image';
                                      return ProductCard(
                                        name: product.name,
                                        subtitle: product.description,
                                        price: firstPrice,
                                        imagePath: imageUrl,
                                        isFavorite:
                                            favorites[product.name] ?? false,
                                        onAddPressed: () => addToCart(
                                          product.name,
                                          product.name,
                                          firstPrice,
                                        ),
                                        onFavoritePressed: () =>
                                            toggleFavorite(product.name),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                  ),

                  // Cart summary overlay
                  if (showCartSummary && cartItems.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3A8A),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (cartItems.length > 1)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${cartItems.length} items',
                                  style: const TextStyle(
                                    color: Color(0xFF1E3A8A),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF1E3A8A,
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Image(
                                        image: AssetImage(
                                          'assets/images/shopping_cart.png',
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${totalAmount.toStringAsFixed(2)} ETB',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          firstItemName,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        if (cartItems.length > 1)
                                          Text(
                                            'and ${cartItems.length - 1} more items',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutScreen(
                                          cartItems: cartItems,
                                          totalAmount: totalAmount,
                                        ),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: const Text(
                                    'Buy Now',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
