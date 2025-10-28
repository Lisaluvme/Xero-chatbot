import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../features/learn/learn_page.dart';
import '../features/maintenance/maintenance_page.dart';
import '../features/troubleshooting/troubleshooting_page.dart';
import '../features/service_records/service_records_page.dart';
import '../features/contact/contact_page.dart';
import '../features/dashboard/dashboard_page.dart';
import 'news_detail_page.dart';
import '../features/ai_chat/ai_chat_page.dart';
import '../features/products/products_page.dart';
import '../features/products/product_details_page.dart';
import '../features/auth/login_page.dart';
import '../features/auth/profile_page.dart';
import '../services/wordpress_service.dart';
import '../services/airtable_service.dart';
import '../services/customer_mapping_service.dart';
import '../models/genset_model.dart';
import '../providers/genset_provider.dart';


class HomePageWidget extends StatefulWidget {
  const HomePageWidget({super.key});

  @override
  State<HomePageWidget> createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  List<dynamic> posts = [];
  bool isLoading = true;
  String errorMessage = '';
  // Removed old Airtable variables - now using GensetProvider
  List<Map<String, dynamic>> popularProducts = [];
  bool popularProductsLoading = true;
  String popularProductsError = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> serviceItems = const [
    {'icon': Icons.shopping_cart, 'label': 'Buy Genset', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.book, 'label': 'Instructions', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.build_circle, 'label': 'Fix Issues', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.engineering, 'label': 'Service', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.cable, 'label': 'My Genset', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.chat, 'label': 'Contact Us', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.monitor, 'label': 'Service', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
    {'icon': Icons.message, 'label': 'WhatsApp', 'color': const Color(0xFF1E3A8A), 'gradient': [Color(0xFF1E3A8A), Color(0xFF14B8A6)]},
  ];

  @override
  void initState() {
    super.initState();
    fetchPosts();
    fetchPopularProducts();
    // Auto-fetch genset data when home page loads (after login)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gensetProvider = Provider.of<GensetProvider>(context, listen: false);
      if (gensetProvider.gensets.isEmpty && !gensetProvider.isLoading) {
        gensetProvider.fetchGensets();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _sendSearchMessage() {
    if (_searchController.text.isNotEmpty) {
      // Navigate to AI Chat page with the message
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AiChatPage(initialMessage: _searchController.text),
        ),
      );
      _searchController.clear();
    }
  }

  Future<void> fetchPosts() async {
    try {
      final response = await http.get(Uri.parse(
          'https://genset.com.my/wp-json/wp/v2/posts?_embed&per_page=5'));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            posts = json.decode(response.body);
            isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            errorMessage = 'Failed to load news: ${response.statusCode}';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading news: $e';
          isLoading = false;
        });
      }
    }
  }



  Future<void> fetchPopularProducts() async {
    try {
      // Fetch all products first, then filter for specific popular ones
      final allProducts = await WordPressService.fetchProducts();

      // Find specific products in order of preference
      final targetProducts = [
        '30kVA MGM Compact Generator Mark 5',
        '60kVA MGM Premium Generator',
        '100kVA MGM Premium Generator'
      ];

      final selectedProducts = <Map<String, dynamic>>[];

      // Find each target product
      for (final targetName in targetProducts) {
        try {
          final foundProduct = allProducts.firstWhere(
            (product) {
              final productName = (product['name'] ?? '').toString().toLowerCase();
              return productName.contains(targetName.toLowerCase()) ||
                     targetName.toLowerCase().contains(productName);
            },
          );
          selectedProducts.add(foundProduct);
        } catch (e) {
          // Product not found, continue to next one
          continue;
        }
      }

      // If we don't have 3 products, fill with other products
      if (selectedProducts.length < 3) {
        final remainingProducts = allProducts.where((product) =>
          !selectedProducts.any((selected) => selected['id'] == product['id'])
        ).take(3 - selectedProducts.length);

        selectedProducts.addAll(remainingProducts);
      }

      if (mounted) {
        setState(() {
          popularProducts = selectedProducts.take(3).toList(); // Ensure max 3 products
          popularProductsLoading = false;
          popularProductsError = '';
        });
      }
    } catch (e) {
      print('Error fetching popular products: $e');
      if (mounted) {
        setState(() {
          popularProductsLoading = false;
          popularProductsError = 'Failed to load popular products';
        });
      }
    }
  }

  /// Show simple account menu
  void _showAccountMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Account",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.person, color: Color(0xFF1E3A8A)),
                title: const Text("Profile"),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to profile page (implement when needed)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Profile page coming soon")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Color(0xFF1E3A8A)),
                title: const Text("Settings"),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to settings page (implement when needed)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Settings page coming soon")),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help, color: Color(0xFF1E3A8A)),
                title: const Text("Help & Support"),
                onTap: () {
                  Navigator.pop(context);
                  // Navigate to help page (implement when needed)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Help page coming soon")),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text("Logout", style: TextStyle(color: Colors.red)),
                onTap: () => _logout(context),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Logout functionality
  void _logout(BuildContext context) {
    Navigator.pop(context); // Close the dialog first

    // Clear chat history on logout
    _clearChatHistory();

    // Sign out from Firebase Auth
    FirebaseAuth.instance.signOut();

    // Clear user session and reset providers
    Provider.of<GensetProvider>(context, listen: false).reset();

    // Navigation will be handled by StreamBuilder in main.dart
  }

  /// Clear chat history from SharedPreferences
  Future<void> _clearChatHistory() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.remove('chat_history');
      await prefs.remove('chat_language');
      print("DEBUG: Chat history cleared on logout");
    } catch (e) {
      print("Error clearing chat history: $e");
    }
  }

  void _onServiceItemTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => const ProductsScreen(initialCategory: 0)),
        );
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LearnPage()),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const TroubleshootingPage()),
        );
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MaintenancePage()),
        );
        break;
      case 4:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
        break;
      case 5:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ContactPage()),
        );
        break;
      case 6:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ServiceRecordsPage()),
        );
        break;
      case 7:
        // WhatsApp quick action
        _launchWhatsApp();
        break;
    }
  }

  Future<void> _launchWhatsApp() async {
    const String phoneNumber = '+60129689816';
    const String message = 'Hello from Genset Assistant';
    final String whatsappUrl = 'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}';
    final Uri uri = Uri.parse(whatsappUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Fallback: try to open WhatsApp directly
      final String fallbackUrl = 'whatsapp://send?phone/$phoneNumber?text=${Uri.encodeComponent(message)}';
      final Uri fallbackUri = Uri.parse(fallbackUrl);
      if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        // Show error message if WhatsApp is not installed
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('WhatsApp is not installed on this device'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildActivityItem(
      String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  time,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.black38,
          ),
        ],
      ),
    );
  }

  Widget _buildNewsItem(dynamic post) {
    String title = post['title']['rendered'] ?? 'No Title';
    String excerpt = post['excerpt']['rendered'] ?? '';
    excerpt = excerpt.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    String date = post['date'] ?? '';
    if (date.isNotEmpty) {
      date = DateTime.parse(date).toLocal().toString().split(' ')[0];
    }

    String imageUrl = '';
    if (post['_embedded'] != null &&
        post['_embedded']['wp:featuredmedia'] != null &&
        post['_embedded']['wp:featuredmedia'].isNotEmpty) {
      imageUrl = post['_embedded']['wp:featuredmedia'][0]['source_url'] ?? '';
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => NewsDetailPage(post: post)),
        );
      },
      child: SizedBox(
        width: 280,
        height: 200,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    imageUrl,
                    height: 100,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFFFFF),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Text(
                          excerpt,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFFB3B3B3),
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            date,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB3B3B3),
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: Theme.of(context).colorScheme.tertiary,
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
      ),
    );
  }

  Widget _buildPopularProductItem(Map<String, dynamic> product) {
    // Handle different data structures from API vs hardcoded data
    String name = product['name'] ?? product['title']?['rendered'] ?? 'Unknown Product';
    String description = product['description'] ?? product['excerpt']?['rendered'] ?? '';
    // Remove HTML tags from description
    description = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();

    // Follow WooCommerce pricing structure
    String price = _formatWooCommercePrice(product);

    // Handle image - WooCommerce API structure
    String? imageUrl;
    try {
      final imagesData = product['images'];
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
        final singleImage = product['image'];
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
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          height: 120,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.electrical_services,
                size: 40,
                color: Color(0xFF6B7280),
              ),
            );
          },
        ),
      );
    } else if (product['image'] is String && (product['image'] as String).startsWith('assets/')) {
      // Asset image from hardcoded fallback data
      imageWidget = ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        child: Image.asset(
          product['image'] as String,
          fit: BoxFit.cover,
          height: 120,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Icon(
                Icons.electrical_services,
                size: 40,
                color: Color(0xFF6B7280),
              ),
            );
          },
        ),
      );
    } else {
      // Icon fallback
      imageWidget = Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: const Icon(
          Icons.electrical_services,
          size: 40,
          color: Color(0xFF6B7280),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: Container(
        width: 140,
        height: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            SizedBox(
              height: 100,
              width: double.infinity,
              child: imageWidget,
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827), // Text Primary
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Text(
                      price,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A), // Primary Color
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildProductItem(Map<String, dynamic> product) {
    String name = product['name'] ?? product['title']?['rendered'] ?? 'Unknown Product';
    String description = product['description'] ?? product['short_description'] ?? '';
    description = description.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    String price = product['price'] ?? product['regular_price'] ?? 'Contact for price';
    if (price != 'Contact for price' && !price.startsWith('RM')) {
      price = 'RM $price';
    }

    String imageUrl = '';
    if (product['images'] != null && product['images'].isNotEmpty) {
      imageUrl = product['images'][0]['src'] ?? '';
    } else if (product['_embedded'] != null &&
        product['_embedded']['wp:featuredmedia'] != null &&
        product['_embedded']['wp:featuredmedia'].isNotEmpty) {
      imageUrl = product['_embedded']['wp:featuredmedia'][0]['source_url'] ?? '';
    }

    return GestureDetector(
      onTap: () {
        // Navigate to Products page for now since there's no product detail page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProductsScreen(initialCategory: 0),
          ),
        );
      },
      child: SizedBox(
        width: 160,
        height: 200,
        child: Container(
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              Container(
                height: 100,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: imageUrl.isNotEmpty
                    ? ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.electrical_services,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.electrical_services,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),

              // Product Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Text(
                        price,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<List<Widget>> _buildMirrorGensetSection() async {
    // Check if user has Airtable tagging using the same service as live status page
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return []; // Not logged in, don't show gensets
    }

    try {
      final customerMapping = await CustomerMappingService.fetchCustomerMappingByEmail();

      // Only show gensets if user has valid tokens (tagging)
      if (customerMapping == null || customerMapping.tokens.isEmpty) {
        // User doesn't have tagging - show access denied message
        return [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'My Gensets',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A), // Text Color
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
                      Icon(Icons.lock, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Genset Access Required',
                              style: TextStyle(
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Contact support to get access to your gensets. You need to be tagged in our system.',
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ];
      }

      // User has tagging - show gensets
      return [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'My Gensets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A), // Text Color
                    ),
                  ),
                  Consumer<GensetProvider>(
                    builder: (context, gensetProvider, child) {
                      return TextButton(
                        onPressed: () => gensetProvider.refreshGensets(),
                        child: const Text(
                          'Refresh',
                          style: TextStyle(
                            color: Color(0xFF38BDF8), // Highlight Color
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer<GensetProvider>(
                builder: (context, gensetProvider, child) {
                  if (gensetProvider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    );
                  }

                  if (gensetProvider.hasError) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Unable to load genset data',
                                  style: TextStyle(
                                    color: Colors.red.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  gensetProvider.error,
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => gensetProvider.fetchGensets(),
                            icon: Icon(Icons.refresh, color: Colors.red.shade700),
                          ),
                        ],
                      ),
                    );
                  }

                  if (gensetProvider.gensets.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.electrical_services, color: Colors.grey.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'No gensets assigned to your account.\nContact support to get access to your gensets.',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return SizedBox(
                    height: 200,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: gensetProvider.gensets.length,
                      itemBuilder: (context, index) {
                        return _buildGensetItem(gensetProvider.gensets[index]);
                      },
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ];
    } catch (e) {
      print('Error checking user permissions: $e');
      // On error, don't show gensets
      return [];
    }
  }

  String _translateStatus(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('离线')) {
      return 'Offline';
    } else if (lowerStatus.contains('在线') || lowerStatus.contains('online')) {
      return 'Online';
    } else if (lowerStatus.contains('空闲') || lowerStatus.contains('idle')) {
      return 'Idle';
    } else if (lowerStatus.contains('运行') || lowerStatus.contains('running')) {
      return 'Running';
    } else if (lowerStatus.contains('报警') || lowerStatus.contains('alarm')) {
      return 'Alarm';
    } else if (lowerStatus.contains('故障') || lowerStatus.contains('error')) {
      return 'Error';
    } else if (lowerStatus.contains('待机') || lowerStatus.contains('standby')) {
      return 'Standby';
    } else {
      return status;
    }
  }

  Widget _buildGensetItem(Genset genset) {
    // Determine status color based on genset status
    Color statusColor;
    String statusText = _translateStatus(genset.status ?? 'Unknown');
    if (statusText.toLowerCase().contains('running') ||
        statusText.toLowerCase().contains('online') ||
        statusText.toLowerCase().contains('active')) {
      statusColor = Colors.green;
    } else if (statusText.toLowerCase().contains('alarm') ||
               statusText.toLowerCase().contains('error') ||
               statusText.toLowerCase().contains('fault')) {
      statusColor = Colors.red;
    } else if (statusText.toLowerCase().contains('standby') ||
               statusText.toLowerCase().contains('off') ||
               statusText.toLowerCase().contains('idle')) {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.blue;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const DashboardPage()),
        );
      },
      child: Container(
        width: 200,
        height: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E3A8A).withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.electrical_services,
                    color: statusColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      genset.name ?? 'Unnamed Genset',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Genset Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ID: ${genset.id ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Status: $statusText',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Power: ${genset.power ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    Text(
                      'Location: ${genset.location ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Model: ${genset.model ?? 'N/A'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF6B7280),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Show maintenance status if available
                    if (genset.maintenanceStatus != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                 genset.maintenanceStatus!.toLowerCase().contains('overdue')
                              ? Colors.red.shade50 : Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                   genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                ? Colors.red.shade200 : Colors.green.shade200,
                          ),
                        ),
                        child: Text(
                          genset.maintenanceStatus!,
                          style: TextStyle(
                            fontSize: 10,
                            color: genset.maintenanceStatus!.toLowerCase().contains('due') ||
                                   genset.maintenanceStatus!.toLowerCase().contains('overdue')
                                ? Colors.red : Colors.green,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
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
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewPadding.bottom + 200, // Increased padding for navigation bar and safe area
            left: 0,
            right: 0,
            top: 0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: TextField(
                              controller: _searchController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(color: Colors.white70),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              onSubmitted: (_) => _sendSearchMessage(),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _sendSearchMessage,
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ProfilePage()),
                            );
                          },
                          icon: const Icon(Icons.account_circle, color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),



              // Services Grid
              Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: serviceItems.length,
                  itemBuilder: (context, index) {
                    final item = serviceItems[index];
                    return GestureDetector(
                      onTap: () => _onServiceItemTap(context, index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 55,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: item['gradient'] as List<Color>,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (item['color'] as Color).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              item['icon'],
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Flexible(
                            child: Text(
                              item['label'],
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: (item['label'] == 'Fix Issues' || item['label'] == 'Service') ? Colors.black : const Color(0xFF0F172A), // Text Color
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),



              // Popular Products Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Popular Products',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A), // Text Color
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProductsScreen(initialCategory: 0),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: Color(0xFF38BDF8), // Highlight Color
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (popularProductsLoading)
                      const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF2563EB),
                        ),
                      )
                    else if (popularProductsError.isNotEmpty)
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
                                    'Unable to load popular products',
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
                              onPressed: fetchPopularProducts,
                              icon: Icon(Icons.refresh, color: Colors.orange.shade700),
                            ),
                          ],
                        ),
                      )
                    else if (popularProducts.isEmpty)
                      const Center(
                        child: Text(
                          'No popular products available',
                          style: TextStyle(color: Color(0xFFB3B3B3)),
                        ),
                      )
                    else
                      SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: popularProducts.length,
                          itemBuilder: (context, index) {
                            return _buildPopularProductItem(popularProducts[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mirror Gensets Section (only show if user is logged in and no access error)
              FutureBuilder<List<Widget>>(
                future: _buildMirrorGensetSection(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Gensets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(height: 24),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My Gensets',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 16),
                          SizedBox(height: 24),
                        ],
                      ),
                    );
                  } else {
                    return Column(children: snapshot.data ?? []);
                  }
                },
              ),

              // Latest News
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Latest News',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A), // Text Color
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (isLoading) const Center(child: CircularProgressIndicator()),
                    if (errorMessage.isNotEmpty)
                      Center(
                        child: Text(
                          errorMessage,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    if (posts.isEmpty && !isLoading && errorMessage.isEmpty)
                      const Center(child: Text('No news available')),
                    if (!isLoading && errorMessage.isEmpty && posts.isNotEmpty)
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            return _buildNewsItem(posts[index]);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
    ),
  );
  }
}
