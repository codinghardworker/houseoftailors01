import 'media.dart';
import 'question.dart';
import 'subservice.dart';

class Service {
  final String id;
  final String name;
  final String description;
  final String serviceType;
  final List<String> fittingChoices;
  final int price;
  final int tailorPoints;
  final Media? coverImage;
  final List<Question> questions;
  final List<Subservice> subservices;
  final bool deadEnd;
  final bool active;

  Service({
    required this.id,
    required this.name,
    required this.description,
    required this.serviceType,
    required this.fittingChoices,
    required this.price,
    required this.tailorPoints,
    this.coverImage,
    required this.questions,
    required this.subservices,
    required this.deadEnd,
    required this.active,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
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

    List<Subservice> subservices = [];
    if (json['subservices'] != null && json['subservices'] is List) {
      subservices = (json['subservices'] as List)
          .map((subserviceJson) => Subservice.fromJson(subserviceJson))
          .toList();
    }

    List<String> fittingChoices = [];
    if (json['fittingChoices'] != null && json['fittingChoices'] is List) {
      fittingChoices = List<String>.from(json['fittingChoices']);
    }

    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      serviceType: json['serviceType'] as String,
      fittingChoices: fittingChoices,
      price: (json['price'] is double) ? (json['price'] as double).toInt() : json['price'] as int,
      tailorPoints: (json['tailorPoints'] is double) ? (json['tailorPoints'] as double).toInt() : json['tailorPoints'] as int,
      coverImage: coverImage,
      questions: questions,
      subservices: subservices,
      deadEnd: json['deadEnd'] as bool? ?? false,
      active: json['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'serviceType': serviceType,
      'fittingChoices': fittingChoices,
      'price': price,
      'tailorPoints': tailorPoints,
      'coverImage': coverImage != null ? {
        'relationTo': 'media',
        'value': coverImage!.toJson(),
      } : null,
      'questions': questions.map((q) => q.toJson()).toList(),
      'subservices': subservices.map((s) => s.toJson()).toList(),
      'deadEnd': deadEnd,
      'active': active,
    };
  }

  double get priceInDollars => price / 100.0;
  bool get isAlteration => serviceType == 'alteration';
  bool get isRepair => serviceType == 'repair';
  bool get hasQuestions => questions.isNotEmpty;
  bool get hasSubservices => subservices.isNotEmpty;
  bool get hasMatchFitting => fittingChoices.contains('match');
  bool get hasPinFitting => fittingChoices.contains('pin');
  bool get hasMeasureFitting => fittingChoices.contains('measure');
  bool get hasInPersonFitting => fittingChoices.contains('in_person');

  List<Subservice> get activeSubservices => subservices.where((s) => s.active).toList();

  @override
  String toString() {
    return 'Service(id: $id, name: $name, type: $serviceType, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Service && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 