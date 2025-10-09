class Store {
  final String id;
  final String name;
  final StoreLocation location;
  final String phone;
  final String email;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Store({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.email,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Store.fromJson(Map<String, dynamic> json) {
    // Handle address from root level or location object
    final address = json['address'] ?? json['location']?['address'] ?? '';

    // Merge location data with address
    final locationData = Map<String, dynamic>.from(json['location'] ?? {});
    if (address.isNotEmpty) {
      locationData['address'] = address;
    }

    return Store(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      location: StoreLocation.fromJson(locationData),
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location.toJson(),
      'phone': phone,
      'email': email,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class StoreLocation {
  final String address;
  final double latitude;
  final double longitude;

  StoreLocation({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory StoreLocation.fromJson(Map<String, dynamic> json) {
    // Handle both lat/lng and latitude/longitude formats
    final lat =
        (json['lat'] as num?)?.toDouble() ??
        (json['latitude'] as num?)?.toDouble() ??
        0.0;
    final lng =
        (json['lng'] as num?)?.toDouble() ??
        (json['longitude'] as num?)?.toDouble() ??
        0.0;

    return StoreLocation(
      address: json['address'] ?? '',
      latitude: lat,
      longitude: lng,
    );
  }

  Map<String, dynamic> toJson() {
    return {'address': address, 'latitude': latitude, 'longitude': longitude};
  }
}
