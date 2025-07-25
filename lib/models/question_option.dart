class QuestionOption {
  final String id;
  final String answer;
  final int priceModifier;
  final int tailorPointsModifier;
  final bool deadEnd;
  final bool active;

  QuestionOption({
    required this.id,
    required this.answer,
    required this.priceModifier,
    required this.tailorPointsModifier,
    required this.deadEnd,
    required this.active,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return QuestionOption(
      id: json['id'] as String,
      answer: json['answer'] as String,
      priceModifier: (json['priceModifier'] is double) ? (json['priceModifier'] as double).toInt() : json['priceModifier'] as int? ?? 0,
      tailorPointsModifier: (json['tailorPointsModifier'] is double) ? (json['tailorPointsModifier'] as double).toInt() : json['tailorPointsModifier'] as int? ?? 0,
      deadEnd: json['deadEnd'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answer': answer,
      'priceModifier': priceModifier,
      'tailorPointsModifier': tailorPointsModifier,
      'deadEnd': deadEnd,
      'active': active,
    };
  }

  double get priceInDollars => priceModifier / 100.0;

  @override
  String toString() {
    return 'QuestionOption(id: $id, answer: $answer, priceModifier: $priceModifier)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QuestionOption && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 