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
  final String? customer;
  final String? maintenanceStatus;
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
    this.customer,
    this.maintenanceStatus,
    this.specifications,
    this.features,
    this.applications,
  });

  factory Genset.fromJson(Map<String, dynamic> json) {
    // Map SmartGen API fields to our model
    return Genset(
      id: json['id']?.toString() ?? '',
      name: json['gsname'] ?? json['name'] ?? '',
      status: json['status_name'] ?? json['status'] ?? '',
      location: json['gsaddress'] ?? json['location'] ?? '',
      model: json['modulename'] ?? json['model'] ?? '',
      brand: 'MGM', // Default brand
      power: _extractPowerFromName(json['gsname'] ?? ''),
      category: 'Diesel Generator',
      price: '',
      description: json['gsname'] ?? '',
      image: json['gsimg'] ?? json['image'] ?? '',
      fuel: 'Diesel',
      customer: null,
      maintenanceStatus: null,
      specifications: {
        'token': json['token'],
        'moduleid': json['moduleid'],
        'hostid': json['hostid'],
        'totalhour': json['totalhour'],
        'totalminute': json['totalminute'],
        'alarmnum': json['alarmnum'],
        'longitude': json['longitude'],
        'latitude': json['latitude'],
      },
      features: null,
      applications: null,
    );
  }

  // Helper method to extract power rating from genset name
  static String _extractPowerFromName(String name) {
    // Try to extract KVA rating from name like "250KVA 2421313 Chuang Seng"
    final kvaMatch = RegExp(r'(\d+)KVA').firstMatch(name);
    if (kvaMatch != null) {
      return '${kvaMatch.group(1)}KVA';
    }

    // Try other patterns
    final kwMatch = RegExp(r'(\d+)KW').firstMatch(name);
    if (kwMatch != null) {
      return '${kwMatch.group(1)}KW';
    }

    return '';
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
      'customer': customer,
      'maintenanceStatus': maintenanceStatus,
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
