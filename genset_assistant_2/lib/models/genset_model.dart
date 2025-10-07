class Genset {
  final String id;
  final String name;
  final String status;
  final String location;
  final String model;
  final String brand;
  final String power;
  final String category;
  final String price;
  final String description;
  final String image;
  final String fuel;
  final Map<String, dynamic>? specifications;
  final List<String>? features;
  final List<String>? applications;

  Genset({
    required this.id,
    required this.name,
    required this.status,
    required this.location,
    this.model = '',
    this.brand = 'MGM',
    this.power = '',
    this.category = 'Diesel Generator',
    this.price = '',
    this.description = '',
    this.image = '',
    this.fuel = 'Diesel',
    this.specifications,
    this.features,
    this.applications,
  });

  factory Genset.fromJson(Map<String, dynamic> json) {
    return Genset(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      status: json['status'] ?? '',
      location: json['location'] ?? '',
      model: json['model'] ?? '',
      brand: json['brand'] ?? 'MGM',
      power: json['power'] ?? '',
      category: json['category'] ?? 'Diesel Generator',
      price: json['price'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      fuel: json['fuel'] ?? 'Diesel',
      specifications: json['specifications'],
      features: json['features'] != null ? List<String>.from(json['features']) : null,
      applications: json['applications'] != null ? List<String>.from(json['applications']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'status': status,
      'location': location,
      'model': model,
      'brand': brand,
      'power': power,
      'category': category,
      'price': price,
      'description': description,
      'image': image,
      'fuel': fuel,
      'specifications': specifications,
      'features': features,
      'applications': applications,
    };
  }

  // Helper method to get formatted display name
  String get displayName => '$brand $name';

  // Helper method to get power rating for easy access
  String get powerRating => power.isNotEmpty ? power : 'N/A';

  // Helper method to check if this is a specific kVA rating
  bool hasKvaRating(String kva) {
    return power.toLowerCase().contains(kva.toLowerCase());
  }
}
