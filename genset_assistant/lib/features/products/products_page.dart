import 'package:flutter/material.dart';
import '../../services/wordpress_service.dart';
import 'product_details_page.dart';

class ProductsScreen extends StatefulWidget {
  final int initialCategory;

  const ProductsScreen({super.key, this.initialCategory = 0});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // API data
  List<Map<String, dynamic>> gensets = [];
  List<Map<String, dynamic>> maintenanceParts = [];

  // Loading states
  bool isLoadingGensets = true;
  bool isLoadingMaintenance = true;

  // Error states
  String gensetsError = '';
  String maintenanceError = '';





  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);

    // Fetch data from WordPress API
    _fetchProducts();
    _fetchMaintenanceParts();
  }

  Future<void> _fetchProducts() async {
    try {
      final products = await WordPressService.fetchProducts();
      if (mounted) {
        setState(() {
          gensets = products;
          isLoadingGensets = false;
          gensetsError = '';
        });
      }
    } catch (e) {
      print('Error fetching products: $e');
      if (mounted) {
        setState(() {
          gensets = [];
          isLoadingGensets = false;
          gensetsError = 'Unable to load products. Please try again.';
        });
      }
    }
  }

  Future<void> _fetchMaintenanceParts() async {
    try {
      final parts = await WordPressService.fetchMaintenanceParts();
      if (mounted) {
        setState(() {
          maintenanceParts = parts;
          isLoadingMaintenance = false;
          maintenanceError = '';
        });
      }
    } catch (e) {
      print('Error fetching maintenance parts: $e');
      if (mounted) {
        setState(() {
          maintenanceParts = []; // Show nothing if API fails
          isLoadingMaintenance = false;
          maintenanceError = '';
        });
      }
    }
  }



  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF1E3A8A), // Primary Color
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            // Search bar with Premium Industrial Blue theme
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white.withOpacity(0.1), // Semi-transparent overlay
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: const Color(0xFF1E3A8A).withOpacity(0.2), // Primary Color with opacity
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1E3A8A).withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: const Color(0xFF6B7280)), // Text Secondary
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: Color(0xFF111827)), // Text Primary
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: const Color(0xFF6B7280).withOpacity(0.7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  _buildGensetsSection(),
                  _buildMaintenancePartsSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildGensetsSection() {
    if (isLoadingGensets) {
      return Container(
        color: const Color(0xFFF3F4F6), // Background Color
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Seller',
              style: TextStyle(
                color: Color(0xFF111827), // Text Primary
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(child: CircularProgressIndicator(color: const Color(0xFF1E3A8A))), // Primary Color
          ],
        ),
      );
    }

    if (gensetsError.isNotEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6), // Background Color
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Seller',
              style: TextStyle(
                color: Color(0xFF111827), // Text Primary
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Unable to load latest products',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Showing cached data. Tap to retry.',
                          style: TextStyle(
                            color: Colors.orange.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: _fetchProducts,
                    icon: Icon(Icons.refresh, color: Colors.orange.shade700),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Filter gensets based on search query only
    final filteredGensets = _searchQuery.isEmpty
        ? gensets
        : gensets.where((genset) {
            final name = (genset['name'] ?? genset['title']?['rendered'] ?? '').toLowerCase();
            final description = (genset['description'] ?? genset['excerpt']?['rendered'] ?? '').toLowerCase();
            return name.contains(_searchQuery) || description.contains(_searchQuery);
          }).toList();

    if (filteredGensets.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        color: const Color(0xFFF3F4F6), // Background Color
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Best Seller',
              style: TextStyle(
                color: Color(0xFF111827), // Text Primary
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: const Color(0xFF6B7280), // Text Secondary
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No products found matching "$_searchQuery"',
                    style: const TextStyle(
                      color: Color(0xFF6B7280), // Text Secondary
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      color: const Color(0xFFF3F4F6), // Background Color
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Best Seller',
                style: TextStyle(
                  color: Color(0xFF111827), // Text Primary
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6), // Accent Color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${filteredGensets.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredGensets.length,
            itemBuilder: (context, index) {
              final genset = filteredGensets[index];

              // Handle different data structures from API vs hardcoded data
              String name = genset['name'] ?? genset['title']?['rendered'] ?? 'Unknown Product';
              String description = genset['description'] ?? genset['excerpt']?['rendered'] ?? '';
              // Remove HTML tags from description
              description = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

              // Follow WooCommerce pricing structure
              String price = _formatWooCommercePrice(genset);

              // Handle image - WooCommerce API structure
              String? imageUrl;
              try {
                final imagesData = genset['images'];
                if (imagesData is List && imagesData.isNotEmpty) {
                  final firstImage = imagesData[0];
                  if (firstImage is Map<String, dynamic>) {
                    imageUrl = firstImage['src'] as String?;
                  }
                } else if (imagesData is Map<String, dynamic>) {
                  imageUrl = imagesData['src'] as String?;
                }

                // Fallback to single image field
                if (imageUrl == null || imageUrl.isEmpty) {
                  final singleImage = genset['image'];
                  if (singleImage is String && singleImage.startsWith('http')) {
                    imageUrl = singleImage;
                  } else if (singleImage is Map<String, dynamic>) {
                    imageUrl = singleImage['src'] as String?;
                  }
                }
              } catch (e) {
                print('Error parsing product image: $e');
              }

              Widget imageWidget;
              if (imageUrl != null && imageUrl.isNotEmpty) {
                // Network image from WooCommerce API
                imageWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    height: 80,
                    width: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.electrical_services,
                          size: 32,
                          color: Color(0xFF6B7280),
                        ),
                      );
                    },
                  ),
                );
              } else if (genset['image'] is String && (genset['image'] as String).startsWith('assets/')) {
                // Asset image from hardcoded fallback data
                imageWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    genset['image'] as String,
                    fit: BoxFit.cover,
                    height: 80,
                    width: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.electrical_services,
                          size: 32,
                          color: Color(0xFF6B7280),
                        ),
                      );
                    },
                  ),
                );
              } else {
                // Icon fallback
                imageWidget = Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.electrical_services,
                    size: 32,
                    color: Color(0xFF6B7280),
                  ),
                );
              }

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductDetailsPage(product: genset),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1E3A8A).withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1E3A8A).withOpacity(0.1),
                            width: 1,
                          ),
                        ),
                        child: imageWidget,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF111827), // Text Primary
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              description,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF6B7280), // Text Secondary
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  price,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1E3A8A), // Primary Color
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: const Color(0xFF6B7280),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenancePartsSection() {
    if (isLoadingMaintenance) {
      return Container(
        color: Theme.of(context).colorScheme.background,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Maintenance Parts',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            SizedBox(height: 16),
            Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
          ],
        ),
      );
    }

    // Show nothing if no maintenance parts from WooCommerce
    if (maintenanceParts.isEmpty) {
      return Container(); // Return empty container - shows nothing
    }

    return Container(
      color: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Maintenance Parts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: maintenanceParts.length,
            itemBuilder: (context, index) {
              final part = maintenanceParts[index];

              // Handle different data structures from API vs hardcoded data
              String name = part['name'] ?? part['title']?['rendered'] ?? 'Unknown Part';
              String price = part['price'] ?? part['regular_price'] ?? 'Contact for price';
              if (price != 'Contact for price' && !price.startsWith('RM') && !price.startsWith('\$')) {
                price = 'RM $price';
              }

              // Handle image - API might have different structure
              dynamic imageData = part['image'] ?? part['images'] ?? part['_embedded']?['wp:featuredmedia']?[0]?['source_url'];
              Widget imageWidget;

              if (imageData is String && imageData.startsWith('http')) {
                // Network image from API
                imageWidget = ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    imageData,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.settings,
                        size: 30,
                        color: Theme.of(context).colorScheme.onSecondary,
                      );
                    },
                  ),
                );
              } else if (imageData is IconData) {
                // Icon from hardcoded data
                imageWidget = Icon(
                  imageData,
                  size: 30,
                  color: Theme.of(context).colorScheme.tertiary,
                );
              } else {
                // Default icon
                imageWidget = Icon(
                  Icons.settings,
                  size: 30,
                  color: Theme.of(context).colorScheme.tertiary,
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: imageWidget,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.tertiary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Format price according to WooCommerce structure
  String _formatWooCommercePrice(Map<String, dynamic> product) {
    // WooCommerce pricing hierarchy:
    // 1. sale_price (if on sale)
    // 2. price (current price)
    // 3. regular_price (regular price)
    // 4. Fallback to hardcoded or contact

    String? salePrice = product['sale_price'];
    String? currentPrice = product['price'];
    String? regularPrice = product['regular_price'];

    // If there's a sale price and it's different from regular price, show sale price
    if (salePrice != null && salePrice.isNotEmpty && salePrice != '0' && salePrice != regularPrice) {
      return 'RM $salePrice';
    }

    // Otherwise use current price or regular price
    String price = currentPrice ?? regularPrice ?? product['price'] ?? 'Contact for price';

    // Format the price with RM prefix if it's not already formatted
    if (price != 'Contact for price' && !price.startsWith('RM') && !price.startsWith('\$')) {
      price = 'RM $price';
    }

    return price;
  }




}
