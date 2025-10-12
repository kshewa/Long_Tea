import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:longtea_mobile/services/api_service.dart';
import 'package:longtea_mobile/services/cart_service.dart';
import 'package:longtea_mobile/models/product.dart';
import 'package:longtea_mobile/screens/checkout_screen.dart';
import 'package:longtea_mobile/providers/auth_notifier.dart';
import '../widgets/product_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  List<Map<String, dynamic>> cartItems = [];
  bool showCartSummary = false;

  // Product state management
  List<Product> productList = [];
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  bool isRefreshing = false;

  // Selected category
  String selectedCategory = 'All Tea';

  // Dynamic categories list (will be built from products)
  List<String> categories = ['All Tea'];

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
    _loadCartFromBackend();
  }

  /// Load cart from backend to ensure store is synced
  Future<void> _loadCartFromBackend() async {
    try {
      await CartService.instance.getCart();
    } catch (e) {
      // Silently fail - cart might be empty
    }
  }

  Future<void> _loadProductsSafely() async {
    try {
      setState(() {
        hasError = false;
        errorMessage = null;
        if (productList.isEmpty) {
          isLoading = true;
        } else {
          isRefreshing = true;
        }
      });

      final products = await fetchProducts();

      if (!mounted) return;

      setState(() {
        productList = products;
        isLoading = false;
        isRefreshing = false;
        hasError = false;
      });

      // Build categories from products after loading
      _buildCategoriesFromProducts(products);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        isRefreshing = false;
        hasError = true;
        errorMessage = e.toString().contains('Exception')
            ? 'Failed to load products. Please check your connection.'
            : 'Something went wrong. Please try again.';
      });
    }
  }

  Future<void> _refreshProducts() async {
    await _loadProductsSafely();
  }

  void _retryLoading() {
    _loadProductsSafely();
  }

  void _buildCategoriesFromProducts(List<Product> products) {
    // Create a set of unique series from products with comprehensive filtering
    final Set<String> uniqueSeries = <String>{};

    for (final product in products) {
      final series = product.series.trim();

      // Only add non-empty, valid series
      if (series.isNotEmpty &&
          series != 'null' &&
          series != 'undefined' &&
          series.length > 0 &&
          !series.contains('\u0000')) {
        // Filter out null characters
        uniqueSeries.add(series);
      }
    }

    // Convert set to list and sort alphabetically
    final List<String> dynamicCategories = ['All Tea'];
    dynamicCategories.addAll(uniqueSeries.toList()..sort());

    // Debug print to see what categories are being generated
    debugPrint('=== CATEGORY BUILDING DEBUG ===');
    debugPrint('Total products: ${products.length}');
    debugPrint(
      'Raw product series: ${products.map((p) => '"${p.series}"').toList()}',
    );
    debugPrint('Unique series found: ${uniqueSeries.toList()}');
    debugPrint('Final categories: $dynamicCategories');
    debugPrint('==============================');

    // Update categories if they've changed
    if (dynamicCategories.toString() != categories.toString()) {
      setState(() {
        categories = dynamicCategories;
        // Reset selected category if it's no longer available
        if (!categories.contains(selectedCategory)) {
          selectedCategory = 'All Tea';
        }
      });
    }
  }

  Widget _buildProductsGrid() {
    // Loading state
    if (isLoading && productList.isEmpty) {
      return SliverFillRemaining(child: _buildLoadingState());
    }

    // Error state
    if (hasError && productList.isEmpty) {
      return SliverFillRemaining(child: _buildErrorState());
    }

    // Filter products based on selected category
    final filteredProducts = selectedCategory == 'All Tea'
        ? productList
        : productList
              .where((product) => product.series == selectedCategory)
              .toList();

    // Empty state (no products at all or no products in selected category)
    if (!isLoading && filteredProducts.isEmpty && !hasError) {
      return SliverFillRemaining(
        child: selectedCategory == 'All Tea'
            ? _buildEmptyState()
            : _buildCategoryEmptyState(),
      );
    }

    // Products grid
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final product = filteredProducts[index];
          return ProductCard(
            key: ValueKey(product.id), // Better performance with keys
            product: product,
            isFavorite: favorites[product.name] ?? false,
            onAddPressed: () => addToCart(
              product.name,
              product.description,
              product.minPrice.toString(),
            ),
            onFavoritePressed: () => toggleFavorite(product.name),
          );
        }, childCount: filteredProducts.length),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1E3A8A)),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Loading products...',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A).withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Failed to Load Products',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Something went wrong. Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.all(Radius.circular(40)),
              ),
              child: const Icon(
                Icons.local_drink_outlined,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Products Available',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'There are no products available at the moment.\nPlease check back later.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: Color(0xFFF3F4F6),
                borderRadius: BorderRadius.all(Radius.circular(40)),
              ),
              child: const Icon(
                Icons.category_outlined,
                size: 40,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No $selectedCategory Products',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'There are no products in the "$selectedCategory" category.\nTry selecting a different category.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  selectedCategory = 'All Tea';
                });
              },
              icon: const Icon(Icons.view_list_rounded, size: 18),
              label: const Text('View All Products'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A8A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    double totalAmount = cartItems.length * 110.0;
    String firstItemName = cartItems.isNotEmpty ? cartItems[0]['name'] : '';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Fixed Header - Always Visible
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A1E3A8A),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User Info Section
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const CircleAvatar(
                            radius: 24,
                            backgroundImage: AssetImage(
                              'assets/images/profile.png',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Guest',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.3,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dembel, Addis Ababa',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: Colors.white.withOpacity(0.9),
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search for tea...',
                          hintStyle: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey[600],
                            size: 22,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshProducts,
              color: const Color(0xFF1E3A8A),
              child: CustomScrollView(
                slivers: [
                  // Fixed Category Chips with Reduced Gap
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _CategoryHeaderDelegate(
                      minHeight: 56,
                      maxHeight: 56,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFAFAFA),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: categories
                              .where((cat) => cat.isNotEmpty)
                              .length, // Only count non-empty categories
                          separatorBuilder: (context, index) =>
                              const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            // Get only non-empty categories for rendering
                            final validCategories = categories
                                .where((cat) => cat.isNotEmpty)
                                .toList();
                            final category = validCategories[index];
                            final isSelected = selectedCategory == category;

                            // Debug print to see what categories are being rendered
                            debugPrint(
                              'Rendering category chip: "$category" (index: $index)',
                            );

                            return FilterChip(
                              label: Text(category),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  selectedCategory = category;
                                });
                              },
                              backgroundColor: Colors.grey[100],
                              selectedColor: const Color(0xFF1E3A8A),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF1E3A8A),
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                fontSize: 14,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              elevation: isSelected ? 2 : 0,
                              checkmarkColor: Colors.white,
                            );
                          },
                        ),
                      ),
                    ),
                  ),

                  // Products Grid with proper state management
                  _buildProductsGrid(),

                  // Refresh indicator overlay
                  if (isRefreshing)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF1E3A8A),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Bottom padding for cart summary
                  if (showCartSummary && cartItems.isNotEmpty)
                    const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
                ],
              ),
            ),
          ),
        ],
      ),

      // Floating Cart Summary
      floatingActionButton: showCartSummary && cartItems.isNotEmpty
          ? null
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomSheet: showCartSummary && cartItems.isNotEmpty
          ? Container(
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
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (cartItems.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${cartItems.length} items',
                          style: const TextStyle(
                            color: Colors.white,
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
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.shopping_cart,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${totalAmount.toStringAsFixed(2)} ETB',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  firstItemName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.white70,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (cartItems.length > 1)
                                  Text(
                                    'and ${cartItems.length - 1} more items',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Buy Now',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}

// Custom delegate for sticky category header
class _CategoryHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _CategoryHeaderDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_CategoryHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
