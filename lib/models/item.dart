import 'media.dart';
import 'item_category.dart';
import 'service.dart';
import 'question.dart';

class Item {
  final String id;
  final String name;
  final DateTime updatedAt;
  final List<ItemCategory> itemCategories;
  final Media? coverImage;
  final List<Question> questions;
  final List<Service> services;
  final bool deadEnd;
  final bool active;
  final DateTime createdAt;

  Item({
    required this.id,
    required this.name,
    required this.updatedAt,
    required this.itemCategories,
    this.coverImage,
    required this.questions,
    required this.services,
    required this.deadEnd,
    required this.active,
    required this.createdAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    Media? coverImage;
    
    if (json['coverImage'] != null && 
        json['coverImage']['relationTo'] == 'media' &&
        json['coverImage']['value'] != null) {
      coverImage = Media.fromJson(json['coverImage']['value']);
    }

    List<ItemCategory> itemCategories = [];
    if (json['itemCategory'] != null && json['itemCategory'] is List) {
      itemCategories = (json['itemCategory'] as List)
          .map((categoryJson) => ItemCategory.fromJson(categoryJson))
          .toList();
    }

    List<Question> questions = [];
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((questionJson) => Question.fromJson(questionJson))
          .toList();
    }

    List<Service> services = [];
    if (json['services'] != null && json['services'] is List) {
      services = (json['services'] as List)
          .map((serviceJson) => Service.fromJson(serviceJson))
          .toList();
    }

    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      itemCategories: itemCategories,
      coverImage: coverImage,
      questions: questions,
      services: services,
      deadEnd: json['deadEnd'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'updatedAt': updatedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'itemCategory': itemCategories.map((c) => c.toJson()).toList(),
      'coverImage': coverImage != null ? {
        'relationTo': 'media',
        'value': coverImage!.toJson(),
      } : null,
      'questions': questions.map((q) => q.toJson()).toList(),
      'services': services.map((s) => s.toJson()).toList(),
      'deadEnd': deadEnd,
      'active': active,
    };
  }

  List<Service> get activeServices => services.where((s) => s.active).toList();
  List<Service> get alterationServices => services.where((s) => s.isAlteration && s.active).toList();
  List<Service> get repairServices => services.where((s) => s.isRepair && s.active).toList();
  bool get hasServices => services.isNotEmpty;
  bool get hasQuestions => questions.isNotEmpty;

  @override
  String toString() {
    return 'Item(id: $id, name: $name, services: ${services.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 