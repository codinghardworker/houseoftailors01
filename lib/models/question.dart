import 'question_option.dart';

class Question {
  final String id;
  final String question;
  final String questionType;
  final String? explainer;
  final List<QuestionOption> options;
  final String? questionAnswerExclusion;
  final bool deadEnd;
  final bool active;

  Question({
    required this.id,
    required this.question,
    required this.questionType,
    this.explainer,
    required this.options,
    this.questionAnswerExclusion,
    required this.deadEnd,
    required this.active,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    List<QuestionOption> options = [];
    
    if (json['option'] != null && json['option'] is List) {
      options = (json['option'] as List)
          .map((optionJson) => QuestionOption.fromJson(optionJson))
          .toList();
    }

    return Question(
      id: json['id'] as String,
      question: json['question'] as String,
      questionType: json['questionType'] as String,
      explainer: json['explainer'] as String?,
      options: options,
      questionAnswerExclusion: json['questionAnswerExclusion'] as String?,
      deadEnd: json['deadEnd'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'questionType': questionType,
      'explainer': explainer,
      'option': options.map((option) => option.toJson()).toList(),
      'questionAnswerExclusion': questionAnswerExclusion,
      'deadEnd': deadEnd,
      'active': active,
    };
  }

  bool get isRadioType => questionType == 'radio';
  bool get isTextType => questionType == 'text';
  bool get hasOptions => options.isNotEmpty;

  @override
  String toString() {
    return 'Question(id: $id, question: $question, type: $questionType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 