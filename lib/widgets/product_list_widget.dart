import 'package:flutter/material.dart';
import 'package:longtea_mobile/models/product.dart';
import 'package:longtea_mobile/models/pagination.dart';
import 'package:longtea_mobile/services/api_service.dart';
import 'package:longtea_mobile/widgets/product_card.dart';

class ProductListWidget extends StatefulWidget {
  final Function(Product) onProductTap;
  final Function(Product) onAddToCart;
  final Function(Product) onToggleFavorite;
  final Map<String, bool> favorites;

  const ProductListWidget({
    super.key,
    required this.onProductTap,
    required this.onAddToCart,
    required this.onToggleFavorite,
    required this.favorites,
  });

  @override
  State<ProductListWidget> createState() => _ProductListWidgetState();
}

class _ProductListWidgetState extends State<ProductListWidget> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<String> availableSeries = [];
  String? selectedSeries;
  String searchQuery = '';
  String sortBy = 'name';
  bool isLoading = false;
  bool isLoadingMore = false;
  bool hasError = false;
  String errorMessage = '';
  Pagination? pagination;
  int currentPage = 1;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadSeries();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreProducts();
    }
  }

  Future<void> _loadProducts({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        currentPage = 1;
        products.clear();
        filteredProducts.clear();
      });
    }

    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await ApiService.fetchProducts(
        page: currentPage,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        series: selectedSeries,
        sortBy: sortBy,
      );

      setState(() {
        if (refresh || currentPage == 1) {
          products = response.products;
        } else {
          products.addAll(response.products);
        }
        filteredProducts = products;
        pagination = response.pagination;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        hasError = true;
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadMoreProducts() async {
    if (isLoadingMore || pagination?.hasNextPage != true) return;

    setState(() {
      isLoadingMore = true;
    });

    try {
      final response = await ApiService.fetchProducts(
        page: currentPage + 1,
        search: searchQuery.isNotEmpty ? searchQuery : null,
        series: selectedSeries,
        sortBy: sortBy,
      );

      setState(() {
        products.addAll(response.products);
        filteredProducts = products;
        pagination = response.pagination;
        currentPage++;
        isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        isLoadingMore = false;
      });
    }
  }

  Future<void> _loadSeries() async {
    try {
      final series = await ApiService.fetchSeries();
      setState(() {
        availableSeries = series;
      });
    } catch (e) {
      // Series loading failure shouldn't break the main functionality
      print('Failed to load series: $e');
    }
  }

  void _applyFilters() {
    setState(() {
      filteredProducts = products.where((product) {
        bool matchesSearch =
            searchQuery.isEmpty ||
            product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
            product.description.toLowerCase().contains(
              searchQuery.toLowerCase(),
            ) ||
            product.series.toLowerCase().contains(searchQuery.toLowerCase());

        bool matchesSeries =
            selectedSeries == null || product.series == selectedSeries;

        return matchesSearch && matchesSeries;
      }).toList();

      // Apply sorting
      switch (sortBy) {
        case 'name':
          filteredProducts.sort((a, b) => a.name.compareTo(b.name));
          break;
        case 'price_low':
          filteredProducts.sort((a, b) => a.minPrice.compareTo(b.minPrice));
          break;
        case 'price_high':
          filteredProducts.sort((a, b) => b.minPrice.compareTo(a.minPrice));
          break;
        case 'newest':
          filteredProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'oldest':
          filteredProducts.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search and Filter Bar
        _buildSearchAndFilterBar(),

        // Product Grid
        Expanded(child: _buildProductGrid()),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          searchQuery = '';
                        });
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
              _applyFilters();
            },
          ),

          const SizedBox(height: 12),

          // Filter Row
          Row(
            children: [
              // Series Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedSeries,
                  decoration: InputDecoration(
                    labelText: 'Series',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Series'),
                    ),
                    ...availableSeries.map(
                      (series) => DropdownMenuItem<String>(
                        value: series,
                        child: Text(series),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedSeries = value;
                    });
                    _applyFilters();
                  },
                ),
              ),

              const SizedBox(width: 12),

              // Sort Filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sortBy,
                  decoration: InputDecoration(
                    labelText: 'Sort By',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem<String>(
                      value: 'name',
                      child: Text('Name'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'price_low',
                      child: Text('Price: Low to High'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'price_high',
                      child: Text('Price: High to Low'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'newest',
                      child: Text('Newest'),
                    ),
                    DropdownMenuItem<String>(
                      value: 'oldest',
                      child: Text('Oldest'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      sortBy = value!;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    if (isLoading && products.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (hasError && products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Error loading products',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _loadProducts(refresh: true),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (filteredProducts.isEmpty && !isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              'No products found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProducts(refresh: true),
      child: GridView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: filteredProducts.length + (isLoadingMore ? 2 : 0),
        itemBuilder: (context, index) {
          if (index >= filteredProducts.length) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = filteredProducts[index];
          return ProductCard(
            product: product,
            isFavorite: widget.favorites[product.id] ?? false,
            onAddPressed: () => widget.onAddToCart(product),
            onFavoritePressed: () => widget.onToggleFavorite(product),
          );
        },
      ),
    );
  }
}
