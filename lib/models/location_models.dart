class City {
  final String name;
  final String? country;
  final double? latitude;
  final double? longitude;
  final List<Area> areas;

  City({
    required this.name,
    this.country,
    this.latitude,
    this.longitude,
    this.areas = const [],
  });

  factory City.fromJson(Map<String, dynamic> json) {
    return City(
      name: json['name'] ?? '',
      country: json['country'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'areas': areas.map((area) => area.toJson()).toList(),
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && name == other.name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

class Area {
  final String name;
  final String cityName;
  final String? type; // district, ward, parish, etc.
  final String? postcode;

  Area({
    required this.name,
    required this.cityName,
    this.type,
    this.postcode,
  });

  factory Area.fromJson(Map<String, dynamic> json) {
    return Area(
      name: json['name'] ?? '',
      cityName: json['cityName'] ?? '',
      type: json['type'],
      postcode: json['postcode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'cityName': cityName,
      'type': type,
      'postcode': postcode,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Area &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          cityName == other.cityName;

  @override
  int get hashCode => Object.hash(name, cityName);

  @override
  String toString() => name;
}

class LocationResult {
  final City? city;
  final Area? area;
  final String? postcode;
  final double? latitude;
  final double? longitude;
  final bool isCurrentLocation;

  LocationResult({
    this.city,
    this.area,
    this.postcode,
    this.latitude,
    this.longitude,
    this.isCurrentLocation = false,
  });

  factory LocationResult.fromCurrentLocation({
    required double latitude,
    required double longitude,
    String? postcode,
    City? city,
    Area? area,
  }) {
    return LocationResult(
      city: city,
      area: area,
      postcode: postcode,
      latitude: latitude,
      longitude: longitude,
      isCurrentLocation: true,
    );
  }

  factory LocationResult.fromManualSelection({
    required City city,
    required Area area,
  }) {
    return LocationResult(
      city: city,
      area: area,
      isCurrentLocation: false,
    );
  }

  String get displayName {
    if (city != null && area != null) {
      return '${area!.name}, ${city!.name}';
    } else if (city != null) {
      return city!.name;
    } else if (area != null) {
      return area!.name;
    }
    return 'Unknown Location';
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city?.toJson(),
      'area': area?.toJson(),
      'postcode': postcode,
      'latitude': latitude,
      'longitude': longitude,
      'isCurrentLocation': isCurrentLocation,
    };
  }

  @override
  String toString() => displayName;
}