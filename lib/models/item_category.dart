import 'media.dart';

class ItemCategory {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Media? coverImage;

  ItemCategory({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.coverImage,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    Media? coverImage;
    
    if (json['coverImage'] != null && 
        json['coverImage']['relationTo'] == 'media' &&
        json['coverImage']['value'] != null) {
      coverImage = Media.fromJson(json['coverImage']['value']);
    }

    return ItemCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      coverImage: coverImage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'coverImage': coverImage != null ? {
        'relationTo': 'media',
        'value': coverImage!.toJson(),
      } : null,
    };
  }

  @override
  String toString() {
    return 'ItemCategory(id: $id, name: $name)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemCategory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 