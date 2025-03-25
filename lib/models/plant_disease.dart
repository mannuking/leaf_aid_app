class PlantDisease {
  final String id;
  final String name;
  final String scientificName;
  final String description;
  final List<String> symptoms;
  final String causes;
  final String treatment;
  final String preventiveMeasures;
  final String? imageUrl;

  PlantDisease({
    required this.id,
    required this.name,
    required this.scientificName,
    required this.description,
    required this.symptoms,
    required this.causes,
    required this.treatment,
    required this.preventiveMeasures,
    this.imageUrl,
  });

  factory PlantDisease.fromJson(Map<String, dynamic> json) {
    return PlantDisease(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      scientificName: json['scientificName'] ?? '',
      description: json['description'] ?? '',
      symptoms: List<String>.from(json['symptoms'] ?? []),
      causes: json['causes'] ?? '',
      treatment: json['treatment'] ?? '',
      preventiveMeasures: json['preventiveMeasures'] ?? '',
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'scientificName': scientificName,
      'description': description,
      'symptoms': symptoms,
      'causes': causes,
      'treatment': treatment,
      'preventiveMeasures': preventiveMeasures,
      'imageUrl': imageUrl,
    };
  }
}
