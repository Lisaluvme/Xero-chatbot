import 'dart:convert';
import 'package:http/http.dart' as http;

class WordPressService {
  // WooCommerce API Configuration
  static const String _baseUrl = "https://genset.com.my/wp-json/wc/v3";
  static const String _consumerKey = "ck_0ae88b89b88148746699d7b1431f93fc5cc2c74d";
  static const String _consumerSecret = "cs_647396a56aff03ece7ac23935844b1eed1cf5fb2";
  static bool _isInitialized = false;

  // Cache configuration
  static const Duration _cacheDuration = Duration(minutes: 30);
  static Map<String, dynamic> _cache = {};
  static Map<String, DateTime> _cacheTimestamps = {};

  // Initialize WordPress service
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Test the connection if needed
      _isInitialized = true;
      print("WordPress service initialized successfully");
    } catch (e) {
      print("Error initializing WordPress service: $e");
    }
  }

  // Check if WordPress service is available
  static bool get isAvailable => _isInitialized;

  // Fetch products from WooCommerce API with authentication and caching
  static Future<List<Map<String, dynamic>>> fetchProducts() async {
    const String cacheKey = 'products';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print("Returning cached products");
      return _cache[cacheKey] as List<Map<String, dynamic>>;
    }

    try {
      // Build authenticated URL - only fetch published products
      final url = Uri.parse("$_baseUrl/products?per_page=100&status=publish&consumer_key=$_consumerKey&consumer_secret=$_consumerSecret&_embed");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final allProducts = data.map((item) => item as Map<String, dynamic>).toList();

        // Filter out products that are not published (double check in case API doesn't filter properly)
        final products = allProducts.where((product) {
          final status = product['status']?.toString().toLowerCase();
          return status == 'publish';
        }).toList();

        // Cache the result
        _cache[cacheKey] = products;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return products;
      } else {
        print("WooCommerce API error: ${response.statusCode} - ${response.body}");
        // Fallback to cached data if available
        if (_cache.containsKey(cacheKey)) {
          print("Returning cached products due to API error");
          return _cache[cacheKey] as List<Map<String, dynamic>>;
        }
        return [];
      }
    } catch (e) {
      print("Error fetching products from WooCommerce: $e");
      // Return cached data if available
      if (_cache.containsKey(cacheKey)) {
        print("Returning cached products due to error");
        return _cache[cacheKey] as List<Map<String, dynamic>>;
      }
      return [];
    }
  }

  // Fetch single product by ID
  static Future<Map<String, dynamic>?> fetchProductById(int productId) async {
    final String cacheKey = 'product_$productId';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print("Returning cached product $productId");
      return _cache[cacheKey] as Map<String, dynamic>;
    }

    try {
      final url = Uri.parse("$_baseUrl/products/$productId?consumer_key=$_consumerKey&consumer_secret=$_consumerSecret&_embed");

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final product = json.decode(response.body) as Map<String, dynamic>;

        // Cache the result
        _cache[cacheKey] = product;
        _cacheTimestamps[cacheKey] = DateTime.now();

        return product;
      } else {
        print("WooCommerce API error for product $productId: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Error fetching product $productId: $e");
      return null;
    }
  }

  // Search for genset products by model/type
  static Future<Map<String, dynamic>?> searchGensetProduct(String gensetType) async {
    final String cacheKey = 'genset_search_$gensetType';

    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print("Returning cached genset search for $gensetType");
      return _cache[cacheKey] as Map<String, dynamic>?;
    }

    try {
      // First fetch all products
      final products = await fetchProducts();

      // Search for matching genset product
      for (var product in products) {
        final name = (product['name'] ?? '').toString().toLowerCase();
        final description = (product['description'] ?? '').toString().toLowerCase();
        final shortDescription = (product['short_description'] ?? '').toString().toLowerCase();

        // Check if product matches the genset type
        if (_matchesGensetType(name, description, shortDescription, gensetType)) {
          // Cache the result
          _cache[cacheKey] = product;
          _cacheTimestamps[cacheKey] = DateTime.now();
          return product;
        }
      }

      return null;
    } catch (e) {
      print("Error searching for genset product $gensetType: $e");
      return null;
    }
  }

  // Check if product matches genset type
  static bool _matchesGensetType(String name, String description, String shortDescription, String gensetType) {
    final searchText = '$name $description $shortDescription'.toLowerCase();

    switch (gensetType.toLowerCase()) {
      case '15kva':
        return searchText.contains('15') && (searchText.contains('kva') || searchText.contains('kw'));
      case '30kva':
        return searchText.contains('30') && (searchText.contains('kva') || searchText.contains('kw'));
      case '60kva':
        return searchText.contains('60') && (searchText.contains('kva') || searchText.contains('kw'));
      case '100kva':
        return searchText.contains('100') && (searchText.contains('kva') || searchText.contains('kw'));
      case '160kva':
        return searchText.contains('160') && (searchText.contains('kva') || searchText.contains('kw'));
      case '250kva':
        return searchText.contains('250') && (searchText.contains('kva') || searchText.contains('kw'));
      case '350kva':
        return searchText.contains('350') && (searchText.contains('kva') || searchText.contains('kw'));
      case '500kva':
        return searchText.contains('500') && (searchText.contains('kva') || searchText.contains('kw'));
      case 'powerbank':
        return searchText.contains('power bank') || searchText.contains('battery');
      default:
        return false;
    }
  }

  // Get product image URLs
  static List<String> getProductImages(Map<String, dynamic> product) {
    final images = <String>[];

    try {
      // Handle WooCommerce images array
      final imagesData = product['images'];
      if (imagesData is List) {
        for (var image in imagesData) {
          if (image is Map<String, dynamic>) {
            final src = image['src'];
            if (src is String && src.isNotEmpty && src.startsWith('http')) {
              images.add(src);
            }
          }
        }
      } else if (imagesData is Map<String, dynamic>) {
        // Fallback for single image object
        final src = imagesData['src'];
        if (src is String && src.isNotEmpty && src.startsWith('http')) {
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
          if (src is String && src.isNotEmpty && src.startsWith('http')) {
            images.add(src);
          }
        }
      }
    } catch (e) {
      print('Error parsing product images: $e');
    }

    return images;
  }

  // Check if cache is valid
  static bool _isCacheValid(String key) {
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }

    final cacheTime = _cacheTimestamps[key]!;
    final now = DateTime.now();
    final difference = now.difference(cacheTime);

    return difference < _cacheDuration;
  }

  // Clear cache
  static void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  // Fetch maintenance parts (assuming custom post type or category)
  static Future<List<Map<String, dynamic>>> fetchMaintenanceParts() async {
    try {
      // Try custom post type 'maintenance_part'
      final url = "$_baseUrl/wp/v2/maintenance_part?per_page=100&_embed";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        // Fallback - use posts with maintenance category
        final postsUrl = "$_baseUrl/wp/v2/posts?categories=maintenance&per_page=100&_embed";
        final postsResponse = await http.get(Uri.parse(postsUrl));

        if (postsResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(postsResponse.body);
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      return [];
    } catch (e) {
      print("Error fetching maintenance parts from WordPress: $e");
      return [];
    }
  }

  // Fetch spare parts (assuming custom post type or category)
  static Future<List<Map<String, dynamic>>> fetchSpareParts() async {
    try {
      // Try custom post type 'spare_part'
      final url = "$_baseUrl/wp/v2/spare_part?per_page=100&_embed";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        // Fallback - use posts with spare-parts category
        final postsUrl = "$_baseUrl/wp/v2/posts?categories=spare-parts&per_page=100&_embed";
        final postsResponse = await http.get(Uri.parse(postsUrl));

        if (postsResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(postsResponse.body);
          return data.map((item) => item as Map<String, dynamic>).toList();
        }
      }

      return [];
    } catch (e) {
      print("Error fetching spare parts from WordPress: $e");
      return [];
    }
  }

  // Fetch popular products sorted by sales/popularity
  static Future<List<Map<String, dynamic>>> fetchPopularProducts() async {
    try {
      // Try WooCommerce API with popularity sorting
      final wooCommerceUrl = "$_baseUrl/wc/v3/products?per_page=20&orderby=popularity&order=desc&_embed";
      final response = await http.get(Uri.parse(wooCommerceUrl));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => item as Map<String, dynamic>).toList();
      } else {
        // Fallback to regular products if popularity sorting not available
        final fallbackUrl = "$_baseUrl/wc/v3/products?per_page=20&_embed";
        final fallbackResponse = await http.get(Uri.parse(fallbackUrl));

        if (fallbackResponse.statusCode == 200) {
          final List<dynamic> data = json.decode(fallbackResponse.body);
          return data.map((item) => item as Map<String, dynamic>).toList();
        } else {
          // Final fallback - use posts with product category
          final postsUrl = "$_baseUrl/wp/v2/posts?categories=product&per_page=20&_embed";
          final postsResponse = await http.get(Uri.parse(postsUrl));

          if (postsResponse.statusCode == 200) {
            final List<dynamic> data = json.decode(postsResponse.body);
            return data.map((item) => item as Map<String, dynamic>).toList();
          }
        }
      }

      return [];
    } catch (e) {
      print("Error fetching popular products from WordPress: $e");
      return [];
    }
  }

  // Build product context from WordPress API data
  static String _buildProductContext(List<dynamic> products, String userMessage) {
    StringBuffer context = StringBuffer();
    context.writeln("=== WORDPRESS PRODUCT DATABASE ===");

    String lowerMessage = userMessage.toLowerCase();

    // Filter relevant products based on user query
    List<dynamic> relevantProducts = [];

    for (var product in products) {
      String name = (product['name'] ?? '').toString().toLowerCase();
      String description = (product['description'] ?? '').toString().toLowerCase();
      String shortDescription = (product['short_description'] ?? '').toString().toLowerCase();

      // Check if product matches user query
      if (_isProductRelevant(product, lowerMessage)) {
        relevantProducts.add(product);
      }
    }

    // Limit to top 10 relevant products
    for (var product in relevantProducts.take(10)) {
      context.writeln("\n--- PRODUCT ---");
      context.writeln("Name: ${product['name'] ?? 'N/A'}");
      context.writeln("SKU: ${product['sku'] ?? 'N/A'}");
      context.writeln("Price: ${product['price'] ?? 'N/A'} ${product['currency'] ?? 'MYR'}");

      if (product['categories'] != null && product['categories'].isNotEmpty) {
        List<String> categoryNames = [];
        for (var category in product['categories']) {
          categoryNames.add(category['name'] ?? 'Unknown');
        }
        context.writeln("Categories: ${categoryNames.join(', ')}");
      }

      if (product['description'] != null && product['description'].isNotEmpty) {
        String description = product['description'].replaceAll('<[^>]*>', ''); // Remove HTML tags
        context.writeln("Description: ${description.substring(0, 200)}${description.length > 200 ? '...' : ''}");
      }

      if (product['short_description'] != null && product['short_description'].isNotEmpty) {
        String shortDesc = product['short_description'].replaceAll('<[^>]*>', '');
        context.writeln("Short Description: $shortDesc");
      }

      // Add product attributes if available
      if (product['attributes'] != null && product['attributes'].isNotEmpty) {
        context.writeln("Attributes:");
        for (var attribute in product['attributes']) {
          String name = attribute['name'] ?? 'Unknown';
          var options = attribute['options'];
          if (options != null && options.isNotEmpty) {
            String value = options is List ? options.join(', ') : options.toString();
            context.writeln("  $name: $value");
          }
        }
      }

      context.writeln("---");
    }

    return context.toString();
  }

  // Check if product is relevant to user query
  static bool _isProductRelevant(dynamic product, String message) {
    String name = (product['name'] ?? '').toString().toLowerCase();
    String description = (product['description'] ?? '').toString().toLowerCase();
    String shortDescription = (product['short_description'] ?? '').toString().toLowerCase();

    // Check for generator/equipment related keywords
    List<String> keywords = [
      'generator', 'genset', 'kva', 'kw', 'power', 'engine', 'diesel',
      'petrol', 'backup', 'emergency', 'standby', 'prime', 'ats', 'transfer',
      'switch', 'automatic', 'manual', 'control', 'panel', 'enclosure',
      'soundproof', 'weatherproof', 'silent', 'portable', 'mobile',
      'industrial', 'commercial', 'residential', 'maintenance', 'service'
    ];

    // Check if message contains product name or description keywords
    if (message.contains(name) || name.contains(message)) {
      return true;
    }

    // Check if message contains relevant keywords
    for (String keyword in keywords) {
      if (message.contains(keyword) ||
          name.contains(keyword) ||
          description.contains(keyword) ||
          shortDescription.contains(keyword)) {
        return true;
      }
    }

    return false;
  }

  // Generate response based on user message and product context
  static String _generateResponse(String userMessage, String productContext, String language) {
    String lowerMessage = userMessage.toLowerCase();

    // Handle different types of queries
    if (lowerMessage.contains('price') || lowerMessage.contains('cost') || lowerMessage.contains('harga')) {
      return _generatePriceResponse(productContext, language);
    } else if (lowerMessage.contains('available') || lowerMessage.contains('stock') || lowerMessage.contains('tersedia')) {
      return _generateAvailabilityResponse(productContext, language);
    } else if (lowerMessage.contains('specification') || lowerMessage.contains('spec') || lowerMessage.contains('spesifikasi')) {
      return _generateSpecificationResponse(productContext, language);
    } else if (lowerMessage.contains('recommend') || lowerMessage.contains('suggest') || lowerMessage.contains('syorkan')) {
      return _generateRecommendationResponse(productContext, userMessage, language);
    } else {
      return _generateGeneralResponse(productContext, userMessage, language);
    }
  }

  // Generate price-related response
  static String _generatePriceResponse(String productContext, String language) {
    if (language == 'ms') {
      return """
Berdasarkan produk yang tersedia:

$productContext

📞 **Untuk maklumat harga yang tepat dan terkini:**
• Telefon: +60 12-968 9816
• Email: genset@genset.com.my
• WhatsApp: +60 12-968 9816

Harga mungkin berbeza berdasarkan konfigurasi dan keperluan khusus anda.
""";
    } else if (language == 'zh') {
      return """
根据可用产品：

$productContext

📞 **获取准确和最新价格：**
• 电话：+60 12-968 9816
• 邮箱：genset@genset.com.my
• WhatsApp：+60 12-968 9816

价格可能因配置和您的具体需求而异。
""";
    } else {
      return """
Based on available products:

$productContext

📞 **For accurate and current pricing:**
• Phone: +60 12-968 9816
• Email: genset@genset.com.my
• WhatsApp: +60 12-968 9816

Prices may vary based on configuration and your specific requirements.
""";
    }
  }

  // Generate availability response
  static String _generateAvailabilityResponse(String productContext, String language) {
    if (language == 'ms') {
      return """
Produk tersedia:

$productContext

📞 **Untuk semak ketersediaan stok terkini:**
• Telefon: +60 12-968 9816
• Email: genset@genset.com.my

Kami akan mengesahkan ketersediaan dan masa penghantaran untuk anda.
""";
    } else if (language == 'zh') {
      return """
可用产品：

$productContext

📞 **检查最新库存：**
• 电话：+60 12-968 9816
• 邮箱：genset@genset.com.my

我们将为您确认库存和交货时间。
""";
    } else {
      return """
Available products:

$productContext

📞 **To check current stock availability:**
• Phone: +60 12-968 9816
• Email: genset@genset.com.my

We will confirm availability and delivery time for you.
""";
    }
  }

  // Generate specification response
  static String _generateSpecificationResponse(String productContext, String language) {
    if (language == 'ms') {
      return """
Spesifikasi produk:

$productContext

📞 **Untuk maklumat teknikal yang lebih terperinci:**
• Telefon: +60 12-968 9816
• Email: genset@genset.com.my

Pasukan teknikal kami boleh memberikan spesifikasi lengkap dan membantu anda memilih produk yang sesuai.
""";
    } else if (language == 'zh') {
      return """
产品规格：

$productContext

📞 **获取更详细的技术信息：**
• 电话：+60 12-968 9816
• 邮箱：genset@genset.com.my

我们的技术团队可以提供完整规格并帮助您选择合适的产品。
""";
    } else {
      return """
Product specifications:

$productContext

📞 **For more detailed technical information:**
• Phone: +60 12-968 9816
• Email: genset@genset.com.my

Our technical team can provide complete specifications and help you choose the right product.
""";
    }
  }

  // Generate recommendation response
  static String _generateRecommendationResponse(String productContext, String userMessage, String language) {
    if (language == 'ms') {
      return """
Berdasarkan keperluan anda: "$userMessage"

Saya cadangkan produk berikut:

$productContext

📞 **Untuk nasihat profesional dan cadangan yang diperibadikan:**
• Telefon: +60 12-968 9816
• Email: genset@genset.com.my

Jurutera kami boleh membantu menilai keperluan anda dan mencadangkan penyelesaian terbaik.
""";
    } else if (language == 'zh') {
      return """
根据您的需求："$userMessage"

我建议以下产品：

$productContext

📞 **获取专业建议和个性化推荐：**
• 电话：+60 12-968 9816
• 邮箱：genset@genset.com.my

我们的工程师可以帮助评估您的需求并推荐最佳解决方案。
""";
    } else {
      return """
Based on your requirements: "$userMessage"

I recommend the following products:

$productContext

📞 **For professional advice and personalized recommendations:**
• Phone: +60 12-968 9816
• Email: genset@genset.com.my

Our engineers can help assess your needs and recommend the best solution.
""";
    }
  }

  // Generate general response
  static String _generateGeneralResponse(String productContext, String userMessage, String language) {
    if (language == 'ms') {
      return """
$userMessage

Berdasarkan maklumat yang tersedia:

$productContext

📞 **Untuk maklumat lanjut atau bantuan:**
• Telefon: +60 12-968 9816
• Email: genset@genset.com.my
• WhatsApp: +60 12-968 9816

Kami di sini untuk membantu anda dengan sebarang pertanyaan tentang generator dan sistem kuasa.
""";
    } else if (language == 'zh') {
      return """
$userMessage

根据可用信息：

$productContext

📞 **获取更多信息或帮助：**
• 电话：+60 12-968 9816
• 邮箱：genset@genset.com.my
• WhatsApp：+60 12-968 9816

我们随时为您解答发电机和电力系统的任何问题。
""";
    } else {
      return """
$userMessage

Based on available information:

$productContext

📞 **For more information or assistance:**
• Phone: +60 12-968 9816
• Email: genset@genset.com.my
• WhatsApp: +60 12-968 9816

We're here to help you with any questions about generators and power systems.
""";
    }
  }

  // Get fallback response for errors
  static String _getFallbackResponse(String language, String message) {
    switch (language) {
      case 'ms':
        return "Maaf, saya menghadapi masalah teknikal. $message Sila hubungi pasukan jualan kami untuk bantuan.";
      case 'zh':
        return "抱歉，我遇到了技术问题。$message 请联系我们的销售团队寻求帮助。";
      default:
        return "I'm experiencing technical difficulties. $message Please contact our sales team for assistance.";
    }
  }

  // Find relevant products for context
  static List<dynamic> _findRelevantProducts(List<dynamic> products, String userMessage) {
    List<dynamic> relevantProducts = [];

    for (var product in products) {
      if (_isProductRelevant(product, userMessage.toLowerCase())) {
        relevantProducts.add(product);
      }
    }

    return relevantProducts;
  }

  // Generate conversational response using product context
  static String _getConversationalResponse(String userMessage, String language, List<dynamic>? relevantProducts) {
    String lowerMessage = userMessage.toLowerCase();

    // Handle different types of queries conversationally
    if (lowerMessage.contains('price') || lowerMessage.contains('cost') || lowerMessage.contains('harga')) {
      return _getConversationalPriceResponse(language, relevantProducts);
    } else if (lowerMessage.contains('available') || lowerMessage.contains('stock') || lowerMessage.contains('tersedia')) {
      return _getConversationalAvailabilityResponse(language, relevantProducts);
    } else if (lowerMessage.contains('specification') || lowerMessage.contains('spec') || lowerMessage.contains('spesifikasi')) {
      return _getConversationalSpecificationResponse(language, relevantProducts);
    } else if (lowerMessage.contains('recommend') || lowerMessage.contains('suggest') || lowerMessage.contains('syorkan')) {
      return _getConversationalRecommendationResponse(userMessage, language, relevantProducts);
    } else if (lowerMessage.contains('hello') || lowerMessage.contains('hi') || lowerMessage.contains('hai') || lowerMessage.contains('你好')) {
      return _getGreetingResponse(language);
    } else if (lowerMessage.contains('thank') || lowerMessage.contains('terima kasih') || lowerMessage.contains('谢谢')) {
      return _getThankYouResponse(language);
    } else if (lowerMessage.contains('help') || lowerMessage.contains('bantuan') || lowerMessage.contains('帮助')) {
      return _getHelpResponse(language, relevantProducts);
    } else {
      return _getGeneralConversationalResponse(userMessage, language, relevantProducts);
    }
  }

  // Conversational price response
  static String _getConversationalPriceResponse(String language, List<dynamic>? products) {
    String productList = products != null && products.isNotEmpty
        ? _formatProductList(products.take(3).toList(), language)
        : "our generator models";

    if (language == 'ms') {
      return "Untuk harga $productList, saya perlu menyemak dengan pasukan jualan kami untuk memberikan quotation yang tepat. Setiap projek adalah unik dan harga bergantung kepada spesifikasi dan keperluan anda.\n\n📞 **Boleh hubungi kami untuk quotation percuma:**\n• Telefon: +60 12-968 9816\n• WhatsApp: +60 12-968 9816\n• Email: genset@genset.com.my\n\nKami akan berikan harga terbaik dan nasihat profesional!";
    } else if (language == 'zh') {
      return "对于$productList的价格，我需要与我们的销售团队确认，以便为您提供准确的报价。每個项目都是独特的，价格取决于规格和您的具体需求。\n\n📞 **欢迎联系我们获取免费报价：**\n• 电话：+60 12-968 9816\n• WhatsApp：+60 12-968 9816\n• 邮箱：genset@genset.com.my\n\n我们将为您提供最优惠的价格和专业建议！";
    } else {
      return "For pricing on $productList, I need to check with our sales team to give you an accurate quotation. Every project is unique and pricing depends on specifications and your requirements.\n\n📞 **Feel free to contact us for a free quote:**\n• Phone: +60 12-968 9816\n• WhatsApp: +60 12-968 9816\n• Email: genset@genset.com.my\n\nWe'll give you the best price and professional advice!";
    }
  }

  // Conversational availability response
  static String _getConversationalAvailabilityResponse(String language, List<dynamic>? products) {
    if (language == 'ms') {
      return "Ya, kami mempunyai beberapa model generator yang tersedia sekarang. Boleh saya tahu jenis generator yang anda perlukan? Saya akan semak ketersediaan dan memberikan maklumat terkini.\n\n📞 **Hubungi kami untuk semak stok:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my";
    } else if (language == 'zh') {
      return "是的，我们现在有一些发电机型号可用。您能告诉我您需要什么类型的发电机吗？我会检查库存并提供最新信息。\n\n📞 **联系我们检查库存：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my";
    } else {
      return "Yes, we have several generator models available right now. Could you tell me what type of generator you're looking for? I'll check availability and give you the latest information.\n\n📞 **Contact us to check stock:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my";
    }
  }

  // Conversational specification response
  static String _getConversationalSpecificationResponse(String language, List<dynamic>? products) {
    if (language == 'ms') {
      return "Untuk spesifikasi lengkap, saya boleh kongsikan maklumat asas tentang model-model kami. Setiap generator mempunyai spesifikasi yang berbeza berdasarkan kuasa, jenis bahan api, dan aplikasi.\n\n📞 **Untuk spesifikasi terperinci:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my\n\nJurutera kami akan bantu pilih model yang sesuai untuk keperluan anda!";
    } else if (language == 'zh') {
      return "对于完整规格，我可以分享我们型号的基本信息。每台发电机都有不同的规格，基于功率、燃料类型和应用。\n\n📞 **获取详细规格：**\n• 电话：+60 12-968 9816\n• 邮箱：technical@gensetassistant.com\n\n我们的工程师将帮助您选择适合您需求的型号！";
    } else {
      return "For complete specifications, I can share basic information about our models. Each generator has different specifications based on power, fuel type, and application.\n\n📞 **For detailed specifications:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my\n\nOur engineers will help you choose the right model for your needs!";
    }
  }

  // Conversational recommendation response
  static String _getConversationalRecommendationResponse(String userMessage, String language, List<dynamic>? products) {
    if (language == 'ms') {
      return "Berdasarkan apa yang anda perlukan, saya cadangkan beberapa pilihan yang sesuai. Setiap keperluan adalah berbeza, jadi saya akan pilih model yang terbaik untuk situasi anda.\n\n📞 **Mari kita bincangkan keperluan anda:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my\n\nKami akan cadangkan penyelesaian yang paling sesuai dan berkesan untuk anda!";
    } else if (language == 'zh') {
      return "根据您的需求，我推荐几个合适的选择。每种需求都是不同的，我会为您选择最适合您情况的型号。\n\n📞 **让我们讨论您的需求：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my\n\n我们将为您推荐最合适和有效的解决方案！";
    } else {
      return "Based on what you're looking for, I recommend several suitable options. Every need is different, so I'll help you choose the best model for your situation.\n\n📞 **Let's discuss your requirements:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my\n\nWe'll recommend the most suitable and effective solution for you!";
    }
  }

  // Greeting response
  static String _getGreetingResponse(String language) {
    if (language == 'ms') {
      return "Hello! Selamat datang ke Genset Assistant! 👋\n\nSaya di sini untuk membantu anda dengan segala pertanyaan tentang generator, sistem ATS, AVS, power bank, dan modul oversight. Apa yang boleh saya bantu hari ini?\n\n📞 **Perlukan bantuan segera? Hubungi:**\n• Telefon: +60 12-968 9816\n• WhatsApp: +60 12-968 9816";
    } else if (language == 'zh') {
      return "你好！欢迎来到发电机助手！👋\n\n我在这里帮助您解答关于发电机、ATS系统、AVS、电源银行和监控模块的所有问题。今天我能为您做什么？\n\n📞 **需要立即帮助？请联系：**\n• 电话：+60 12-968 9816\n• WhatsApp：+60 12-968 9816";
    } else {
      return "Hello! Welcome to Genset Assistant! 👋\n\nI'm here to help you with any questions about generators, ATS systems, AVS, power banks, and oversight modules. What can I help you with today?\n\n📞 **Need immediate assistance? Contact:**\n• Phone: +60 12-968 9816\n• WhatsApp: +60 12-968 9816";
    }
  }

  // Thank you response
  static String _getThankYouResponse(String language) {
    if (language == 'ms') {
      return "Sama-sama! Terima kasih kerana menghubungi Genset Assistant! 😊\n\nAda lagi yang boleh saya bantu? Jangan segan untuk bertanya tentang generator atau sistem kuasa kami.\n\n📞 **Sentiasa di sini untuk membantu:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my";
    } else if (language == 'zh') {
      return "不客气！感谢您联系发电机助手！😊\n\n还有什么我可以帮助您的吗？随时询问我们关于发电机或电力系统的问题。\n\n📞 **随时为您服务：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my";
    } else {
      return "You're welcome! Thank you for contacting Genset Assistant! 😊\n\nIs there anything else I can help you with? Feel free to ask about our generators or power systems.\n\n📞 **Always here to help:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my";
    }
  }

  // Help response
  static String _getHelpResponse(String language, List<dynamic>? products) {
    if (language == 'ms') {
      return "Tentu! Saya boleh membantu anda dengan pelbagai perkara:\n\n🤖 **Maklumat Produk:**\n• Spesifikasi generator terkini\n• Model yang tersedia\n• Perbandingan produk\n\n💡 **Nasihat Teknikal:**\n• Cadangan berdasarkan keperluan\n• Pemasangan dan penyelenggaraan\n• Penyelesaian tersuai\n\n📞 **Untuk bantuan lanjut:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my\n• WhatsApp: +60 12-968 9816\n\nApa yang anda perlukan hari ini?";
    } else if (language == 'zh') {
      return "当然！我可以帮助您处理各种事务：\n\n🤖 **产品信息：**\n• 最新发电机规格\n• 可用型号\n• 产品比较\n\n💡 **技术建议：**\n• 根据需求推荐\n• 安装和维护\n• 定制解决方案\n\n📞 **获取进一步帮助：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my\n• WhatsApp：+60 12-968 9816\n\n今天您需要什么帮助？";
    } else {
      return "Of course! I can help you with various things:\n\n🤖 **Product Information:**\n• Latest generator specifications\n• Available models\n• Product comparisons\n\n💡 **Technical Advice:**\n• Recommendations based on your needs\n• Installation and maintenance\n• Custom solutions\n\n📞 **For further assistance:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my\n• WhatsApp: +60 12-968 9816\n\nWhat do you need help with today?";
    }
  }

  // General conversational response
  static String _getGeneralConversationalResponse(String userMessage, String language, List<dynamic>? products) {
    String productContext = products != null && products.isNotEmpty
        ? "Based on our current inventory, I can help you find the right generator for your needs."
        : "I can help you with information about our generator products and services.";

    if (language == 'ms') {
      return "$userMessage\n\n$productContext\n\nSaya akan membantu anda mencari penyelesaian terbaik untuk keperluan kuasa anda. Boleh beritahu lebih lanjut tentang apa yang anda perlukan?\n\n📞 **Mari kita bincangkan:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my";
    } else if (language == 'zh') {
      return "$userMessage\n\n$productContext\n\n我将帮助您找到最适合您电力需求的解决方案。您能告诉我更多关于您的需求吗？\n\n📞 **让我们讨论：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my";
    } else {
      return "$userMessage\n\n$productContext\n\nI'll help you find the best solution for your power needs. Can you tell me more about what you're looking for?\n\n📞 **Let's discuss:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my";
    }
  }

  // Format product list for conversational responses
  static String _formatProductList(List<dynamic> products, String language) {
    if (products.isEmpty) return "our products";

    List<String> productNames = products.map((p) => p['name']?.toString() ?? 'Unknown Product').toList();

    if (language == 'ms') {
      if (productNames.length == 1) return productNames.first;
      if (productNames.length == 2) return "${productNames.first} dan ${productNames.last}";
      return "${productNames.take(productNames.length - 1).join(', ')}, dan ${productNames.last}";
    } else if (language == 'zh') {
      if (productNames.length == 1) return productNames.first;
      if (productNames.length == 2) return "${productNames.first}和${productNames.last}";
      return "${productNames.take(productNames.length - 1).join('、')}和${productNames.last}";
    } else {
      if (productNames.length == 1) return productNames.first;
      if (productNames.length == 2) return "${productNames.first} and ${productNames.last}";
      return "${productNames.take(productNames.length - 1).join(', ')}, and ${productNames.last}";
    }
  }

  // Conversational fallback response
  static String _getConversationalFallback(String language) {
    if (language == 'ms') {
      return "Maaf, saya menghadapi masalah teknikal sebentar tadi. Jangan risau, saya masih boleh membantu anda dengan maklumat tentang generator dan sistem kuasa kami!\n\n📞 **Hubungi pasukan kami untuk bantuan segera:**\n• Telefon: +60 12-968 9816\n• Email: genset@genset.com.my\n• WhatsApp: +60 12-968 9816\n\nApa yang boleh saya bantu hari ini? 😊";
    } else if (language == 'zh') {
      return "抱歉，我刚才遇到了一些技术问题。别担心，我仍然可以帮助您了解我们的发电机和电力系统信息！\n\n📞 **联系我们的团队获取即时帮助：**\n• 电话：+60 12-968 9816\n• 邮箱：genset@genset.com.my\n• WhatsApp：+60 12-968 9816\n\n今天我能为您做什么？😊";
    } else {
      return "Sorry, I experienced a technical issue just now. Don't worry, I can still help you with information about our generators and power systems!\n\n📞 **Contact our team for immediate assistance:**\n• Phone: +60 12-968 9816\n• Email: genset@genset.com.my\n• WhatsApp: +60 12-968 9816\n\nWhat can I help you with today? 😊";
    }
  }

}
