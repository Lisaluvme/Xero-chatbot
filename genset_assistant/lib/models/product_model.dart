class WooCommerceProduct {
  final int id;
  final String name;
  final String? description;
  final String? shortDescription;
  final String? sku;
  final String? price;
  final String? regularPrice;
  final String? salePrice;
  final bool onSale;
  final String? stockStatus;
  final int? stockQuantity;
  final List<WooCommerceImage> images;
  final List<WooCommerceCategory> categories;
  final List<WooCommerceAttribute> attributes;
  final Map<String, dynamic> rawData;

  WooCommerceProduct({
    required this.id,
    required this.name,
    this.description,
    this.shortDescription,
    this.sku,
    this.price,
    this.regularPrice,
    this.salePrice,
    this.onSale = false,
    this.stockStatus,
    this.stockQuantity,
    this.images = const [],
    this.categories = const [],
    this.attributes = const [],
    required this.rawData,
  });

  factory WooCommerceProduct.fromJson(Map<String, dynamic> json) {
    return WooCommerceProduct(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown Product',
      description: json['description'],
      shortDescription: json['short_description'],
      sku: json['sku'],
      price: json['price'],
      regularPrice: json['regular_price'],
      salePrice: json['sale_price'],
      onSale: json['on_sale'] ?? false,
      stockStatus: json['stock_status'],
      stockQuantity: json['stock_quantity'],
      images: (json['images'] as List<dynamic>?)
          ?.map((img) => WooCommerceImage.fromJson(img as Map<String, dynamic>))
          .toList() ?? [],
      categories: (json['categories'] as List<dynamic>?)
          ?.map((cat) => WooCommerceCategory.fromJson(cat as Map<String, dynamic>))
          .toList() ?? [],
      attributes: (json['attributes'] as List<dynamic>?)
          ?.map((attr) => WooCommerceAttribute.fromJson(attr as Map<String, dynamic>))
          .toList() ?? [],
      rawData: json,
    );
  }

  Map<String, dynamic> toJson() => rawData;

  String get displayPrice {
    if (salePrice != null && salePrice!.isNotEmpty && salePrice != '0') {
      return 'RM $salePrice';
    }
    final displayPrice = price ?? regularPrice ?? 'Contact for price';
    if (displayPrice == 'Contact for price') {
      return displayPrice;
    }
    return 'RM $displayPrice';
  }

  String get formattedPrice {
    if (salePrice != null && salePrice!.isNotEmpty && salePrice != '0') {
      final regular = regularPrice != null && regularPrice!.isNotEmpty
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

  List<String> get imageUrls {
    return images.map((img) => img.src).where((src) => src.isNotEmpty).toList();
  }

  List<String> get categoryNames {
    return categories.map((cat) => cat.name).where((name) => name.isNotEmpty).toList();
  }

  bool get isInStock {
    return stockStatus == 'instock';
  }

  bool get isOutOfStock {
    return stockStatus == 'outofstock';
  }

  bool get isOnBackorder {
    return stockStatus == 'onbackorder';
  }
}

class WooCommerceImage {
  final int id;
  final String src;
  final String? name;
  final String? alt;

  WooCommerceImage({
    required this.id,
    required this.src,
    this.name,
    this.alt,
  });

  factory WooCommerceImage.fromJson(Map<String, dynamic> json) {
    return WooCommerceImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      name: json['name'],
      alt: json['alt'],
    );
  }
}

class WooCommerceCategory {
  final int id;
  final String name;
  final String slug;

  WooCommerceCategory({
    required this.id,
    required this.name,
    required this.slug,
  });

  factory WooCommerceCategory.fromJson(Map<String, dynamic> json) {
    return WooCommerceCategory(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      slug: json['slug'] ?? '',
    );
  }
}

class WooCommerceAttribute {
  final int id;
  final String name;
  final String? position;
  final bool visible;
  final bool variation;
  final List<String> options;

  WooCommerceAttribute({
    required this.id,
    required this.name,
    this.position,
    this.visible = true,
    this.variation = false,
    this.options = const [],
  });

  factory WooCommerceAttribute.fromJson(Map<String, dynamic> json) {
    return WooCommerceAttribute(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      position: json['position']?.toString(),
      visible: json['visible'] ?? true,
      variation: json['variation'] ?? false,
      options: (json['options'] as List<dynamic>?)?.map((opt) => opt.toString()).toList() ?? [],
    );
  }
}
