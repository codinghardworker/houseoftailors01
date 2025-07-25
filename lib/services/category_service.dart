import 'dart:convert';
import 'package:flutter/services.dart';
import '../providers/cart_provider.dart';

class CategoryService {
  static Future<List<ItemCategory>> loadCategories() async {
    try {
      // Load the categories JSON file
      final String jsonString = await rootBundle.loadString('extracted_data/categories.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Convert JSON data to ItemCategory objects
      return jsonData.map((json) => ItemCategory(
        id: json['id'] as String,
        name: json['name'] as String,
        coverImageUrl: json['coverImage']?['value']?['url'] as String?,
        updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      )).toList();
    } catch (e) {
      print('Error loading categories: $e');
      return [];
    }
  }

  static Future<List<Service>> loadItemsForCategory(String categoryId) async {
    try {
      // Load all items JSON file
      final String jsonString = await rootBundle.loadString('extracted_data/all_items.json');
      final List<dynamic> jsonData = json.decode(jsonString);
      
      // Filter items by category ID and convert to Service objects
      return jsonData.where((json) {
        final categories = (json['itemCategory'] as List<dynamic>?) ?? [];
        return categories.any((cat) => cat['id'] == categoryId);
      }).map((json) => _parseService(json)).toList();
    } catch (e) {
      print('Error loading items for category: $e');
      return [];
    }
  }

  static Service _parseService(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceType: json['serviceType'] as String? ?? 'alteration',
      fittingChoices: (json['fittingChoices'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList() ?? [],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      tailorPoints: (json['tailorPoints'] as num?)?.toInt() ?? 0,
      questions: _parseQuestions(json['questions'] as List<dynamic>? ?? []),
      subservices: _parseSubservices(json['subservices'] as List<dynamic>? ?? []),
      active: json['active'] as bool? ?? true,
      description: json['description'] as String?,
      deadEnd: json['deadEnd'] as bool? ?? false,
      coverImageUrl: json['coverImage']?['value']?['url'] as String?,
    );
  }

  static List<Question> _parseQuestions(List<dynamic> jsonList) {
    return jsonList.map((json) => Question(
      id: json['id'] as String,
      question: json['question'] as String,
      explainer: json['explainer'] as String?,
      questionType: json['questionType'] as String,
      options: _parseQuestionOptions(json['option'] as List<dynamic>? ?? []),
    )).toList();
  }

  static List<QuestionOption> _parseQuestionOptions(List<dynamic> jsonList) {
    return jsonList.map((json) => QuestionOption(
      id: json['id'] as String,
      answer: json['answer'] as String,
      priceModifier: (json['priceModifier'] as num?)?.toDouble() ?? 0.0,
      tailorPointsModifier: (json['tailorPointsModifier'] as num?)?.toInt() ?? 0,
    )).toList();
  }

  static List<Subservice> _parseSubservices(List<dynamic> jsonList) {
    return jsonList.map((json) => Subservice(
      id: json['id'] as String,
      name: json['name'] as String,
      fittingChoices: (json['fittingChoices'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      priceModifier: (json['priceModifier'] as num?)?.toDouble() ?? 0.0,
      tailorPointsModifier: (json['tailorPointsModifier'] as num?)?.toInt() ?? 0,
      questions: _parseQuestions(json['questions'] as List<dynamic>? ?? []),
      active: json['active'] as bool? ?? true,
      description: json['description'] as String?,
      deadEnd: json['deadEnd'] as bool? ?? false,
      coverImageUrl: json['coverImage']?['value']?['url'] as String?,
    )).toList();
  }
} 