import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/wordpress_service.dart';
import '../../widgets/quotation_form.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  Map<String, dynamic>? _detailedProduct;
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadProductDetails();
  }

  Future<void> _loadProductDetails() async {
    try {
      // If we have an ID, fetch detailed product data
      final productId = widget.product['id'];
      if (productId != null) {
        final detailedProduct = await WordPressService.fetchProductById(productId);
        if (detailedProduct != null) {
          setState(() {
            _detailedProduct = detailedProduct;
            _isLoading = false;
          });
          return;
        }
      }

      // Use the passed product data if detailed fetch fails
      setState(() {
        _detailedProduct = widget.product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load product details';
        _isLoading = false;
        _detailedProduct = widget.product; // Fallback to basic data
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product Details'),
        backgroundColor: const Color(0xFF1E3A8A), // Primary Color
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: const Color(0xFF1E3A8A).withOpacity(0.3),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF1E3A8A),
              ),
            )
          : _buildProductDetails(),
    );
  }

  Widget _buildProductDetails() {
    if (_detailedProduct == null) {
      return const Center(
        child: Text('Product not found'),
      );
    }

    final product = _detailedProduct!;
    final images = _getProductImages(product);
    final name = product['name'] ?? 'Unknown Product';
    final description = _cleanHtml(product['description'] ?? '');
    final shortDescription = _cleanHtml(product['short_description'] ?? '');
    final price = _formatPrice(product);
    final sku = product['sku'];
    final categories = _getCategories(product);
    final stockStatus = product['stock_status'];
    final stockQuantity = product['stock_quantity'];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Images Carousel
          if (images.isNotEmpty) _buildImageCarousel(images),

          // Product Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827), // Text Primary
                  ),
                ),
                const SizedBox(height: 8),

                // SKU and Categories
                Row(
                  children: [
                    if (sku != null) ...[
                      Text(
                        'SKU: $sku',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280), // Text Secondary
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    if (categories.isNotEmpty)
                      Expanded(
                        child: Text(
                          'Category: ${categories.join(', ')}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Price
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E3A8A), // Primary Color
                  ),
                ),
                const SizedBox(height: 8),

                // Stock Status
                _buildStockStatus(stockStatus, stockQuantity),
                const SizedBox(height: 16),

                // Short Description
                if (shortDescription.isNotEmpty) ...[
                  Text(
                    shortDescription,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111827),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Full Description
                if (description.isNotEmpty) ...[
                  const Text(
                    'Description',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF111827),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      QuotationForm.show(
                        context,
                        productName: name,
                        productDescription: shortDescription.isNotEmpty ? shortDescription : description,
                        productPrice: price,
                      );
                    },
                    icon: const Icon(Icons.assignment),
                    label: const Text('Order Now!!'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB), // Button Color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                // Error message if any
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCarousel(List<String> images) {
    return SizedBox(
      height: 300,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return CachedNetworkImage(
            imageUrl: images[index],
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: const Color(0xFFF3F4F6), // Background Color
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF1E3A8A),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              color: const Color(0xFFF3F4F6),
              child: const Icon(
                Icons.image_not_supported,
                size: 50,
                color: Color(0xFF6B7280),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockStatus(String? stockStatus, dynamic stockQuantity) {
    Color statusColor;
    String statusText;

    switch (stockStatus) {
      case 'instock':
        statusColor = Colors.green;
        statusText = stockQuantity != null && stockQuantity > 0
            ? '$stockQuantity in stock'
            : 'In stock';
        break;
      case 'outofstock':
        statusColor = Colors.red;
        statusText = 'Out of stock';
        break;
      case 'onbackorder':
        statusColor = Colors.orange;
        statusText = 'On backorder';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusText = 'Stock status unknown';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  List<String> _getProductImages(Map<String, dynamic> product) {
    final images = <String>[];

    try {
      // Handle WooCommerce images array
      final imagesData = product['images'];
      if (imagesData is List) {
        for (var image in imagesData) {
          if (image is Map<String, dynamic>) {
            final src = image['src'];
            if (src is String && src.isNotEmpty) {
              images.add(src);
            }
          }
        }
      } else if (imagesData is Map<String, dynamic>) {
        // Fallback for single image object
        final src = imagesData['src'];
        if (src is String && src.isNotEmpty) {
          images.add(src);
        }
      }

      // Fallback to single image field if images array is empty
      if (images.isEmpty) {
        final singleImage = product['image'];
        if (singleImage is String && singleImage.isNotEmpty && singleImage.startsWith('http')) {
          images.add(singleImage);
        } else if (singleImage is Map<String, dynamic>) {
          final src = singleImage['src'];
          if (src is String && src.isNotEmpty) {
            images.add(src);
          }
        }
      }
    } catch (e) {
      print('Error parsing product images: $e');
    }

    return images;
  }

  List<String> _getCategories(Map<String, dynamic> product) {
    try {
      final categoriesData = product['categories'];
      if (categoriesData is List) {
        return categoriesData
            .map((cat) {
              if (cat is Map<String, dynamic>) {
                return cat['name'] as String?;
              }
              return null;
            })
            .where((name) => name != null && name.isNotEmpty)
            .cast<String>()
            .toList();
      }
    } catch (e) {
      print('Error parsing product categories: $e');
    }
    return [];
  }

  String _formatPrice(Map<String, dynamic> product) {
    final regularPrice = product['regular_price'];
    final salePrice = product['sale_price'];
    final price = product['price'];

    if (salePrice != null && salePrice.isNotEmpty && salePrice != '0') {
      final regular = regularPrice != null && regularPrice.isNotEmpty
          ? 'RM $regularPrice'
          : '';
      return 'RM $salePrice ${regular.isNotEmpty ? '(was $regular)' : ''}';
    }

    final displayPrice = price ?? regularPrice ?? 'Contact for price';
    if (displayPrice == 'Contact for price') {
      return displayPrice;
    }

    return 'RM $displayPrice';
  }

  String _cleanHtml(String html) {
    // Remove HTML tags
    final cleanText = html.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decode HTML entities
    return cleanText
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&', '&')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }
}
