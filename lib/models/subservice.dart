import 'media.dart';
import 'question.dart';

class Subservice {
  final String id;
  final String name;
  final String? description;
  final int priceModifier;
  final int tailorPointsModifier;
  final Media? coverImage;
  final List<Question> questions;
  final List<String>? fittingChoices;
  final String? questionAnswerExclusion;
  final bool deadEnd;
  final bool active;

  Subservice({
    required this.id,
    required this.name,
    this.description,
    required this.priceModifier,
    required this.tailorPointsModifier,
    this.coverImage,
    required this.questions,
    this.fittingChoices,
    this.questionAnswerExclusion,
    required this.deadEnd,
    required this.active,
  });

  factory Subservice.fromJson(Map<String, dynamic> json) {
    Media? coverImage;
    
    if (json['coverImage'] != null && 
        json['coverImage']['relationTo'] == 'media' &&
        json['coverImage']['value'] != null) {
      coverImage = Media.fromJson(json['coverImage']['value']);
    }

    List<Question> questions = [];
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((questionJson) => Question.fromJson(questionJson))
          .toList();
    }

    List<String>? fittingChoices;
    if (json['fittingChoices'] != null && json['fittingChoices'] is List) {
      fittingChoices = (json['fittingChoices'] as List).cast<String>();
    }

    return Subservice(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      priceModifier: (json['priceModifier'] is double) ? (json['priceModifier'] as double).toInt() : json['priceModifier'] as int? ?? 0,
      tailorPointsModifier: (json['tailorPointsModifier'] is double) ? (json['tailorPointsModifier'] as double).toInt() : json['tailorPointsModifier'] as int? ?? 0,
      coverImage: coverImage,
      questions: questions,
      fittingChoices: fittingChoices,
      questionAnswerExclusion: json['questionAnswerExclusion'] as String?,
      deadEnd: json['deadEnd'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'priceModifier': priceModifier,
      'tailorPointsModifier': tailorPointsModifier,
      'coverImage': coverImage != null ? {
        'relationTo': 'media',
        'value': coverImage!.toJson(),
      } : null,
      'questions': questions.map((q) => q.toJson()).toList(),
      'fittingChoices': fittingChoices,
      'questionAnswerExclusion': questionAnswerExclusion,
      'deadEnd': deadEnd,
      'active': active,
    };
  }

  double get priceModifierInDollars => priceModifier / 100.0;
  bool get hasQuestions => questions.isNotEmpty;

  @override
  String toString() {
    return 'Subservice(id: $id, name: $name, priceModifier: $priceModifier)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Subservice && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 