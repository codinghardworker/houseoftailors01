import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'shop_config_service.dart';

class LocationService {
  static const String _baseUrl = 'https://api.postcodes.io';
  static const String _nominatimUrl = 'https://nominatim.openstreetmap.org';
  
  // Get Firestore instance
  static FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Fetch available cities from ShopConfigService
  static Future<List<String>> fetchCitiesForCountry([String? countryCode]) async {
    try {
      final cities = ShopConfigService.getCities();
      return cities.map((city) => city['name'] as String).toList();
    } catch (e) {
      print('Error fetching cities: $e');
      return [];
    }
  }

  /// Fetch UK cities (legacy method - now uses ShopConfigService)
  static Future<List<String>> fetchUKCities() async {
    return fetchCitiesForCountry();
  }

  /// Fetch towns for a specific city from ShopConfigService
  static Future<List<String>> fetchAreasForCity(String cityName) async {
    try {
      final cities = ShopConfigService.getCities();
      
      // Find the city by name (case insensitive)
      final city = cities.cast<Map<String, dynamic>?>().firstWhere(
        (c) => c != null && (c['name'] as String).toLowerCase() == cityName.toLowerCase(),
        orElse: () => null,
      );
      
      if (city != null) {
        final cityId = city['id'] as String;
        return ShopConfigService.getTownsForCity(cityId);
      }
    } catch (e) {
      print('Error fetching towns: $e');
    }
    
    return [];
  }
  

  /// Validate postcode using Postcodes.io API
  static Future<Map<String, dynamic>?> validatePostcode(String postcode) async {
    try {
      final url = Uri.parse('$_baseUrl/postcodes/$postcode');
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['result'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get current location areas using postcode
  static Future<List<String>> getAreasFromPostcode(String postcode) async {
    try {
      final locationData = await validatePostcode(postcode);
      if (locationData != null) {
        List<String> areas = [];
        
        if (locationData['admin_district'] != null) {
          areas.add(locationData['admin_district']);
        }
        if (locationData['admin_ward'] != null) {
          areas.add(locationData['admin_ward']);
        }
        if (locationData['parish'] != null) {
          areas.add(locationData['parish']);
        }
        
        return areas.where((area) => area.isNotEmpty).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Search for cities by name (useful for autocomplete)
  static Future<List<String>> searchCities(String query) async {
    try {
      final cities = await fetchCitiesForCountry();
      if (query.isEmpty) return cities;
      
      return cities
          .where((city) => city.toLowerCase().contains(query.toLowerCase()))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// Subscribe to location updates from ShopConfigService
  static Stream<List<Map<String, dynamic>>> subscribeToLocationUpdates() {
    return ShopConfigService.configStream.map((config) {
      try {
        final locations = config['available_locations'] as Map<String, dynamic>?;
        if (locations != null) {
          final cities = locations['cities'] as List<dynamic>?;
          return cities?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
        }
        return <Map<String, dynamic>>[];
      } catch (e) {
        print('Error processing location updates: $e');
        return <Map<String, dynamic>>[];
      }
    });
  }

  /// Get coordinates for a city (basic coordinates for London and Newcastle)
  static Map<String, double>? getCityCoordinates(String cityName) {
    final coordinates = {
      'London': {'latitude': 51.5074, 'longitude': -0.1278},
      'Newcastle': {'latitude': 54.9783, 'longitude': -1.6178},
    };
    
    return coordinates[cityName];
  }
}