class ScanHistory {
  final String id;
  final String plantDiseaseId;
  final String plantName;
  final String diseaseName;
  final DateTime scanDate;
  final double confidence;
  final String? imagePath;
  final Map<String, double>? allPredictions;
  final Map<String, dynamic>? metadata;

  ScanHistory({
    required this.id,
    required this.plantDiseaseId,
    required this.plantName,
    required this.diseaseName,
    required this.scanDate,
    required this.confidence,
    this.imagePath,
    this.allPredictions,
    this.metadata,
  });

  factory ScanHistory.fromJson(Map<String, dynamic> json) {
    return ScanHistory(
      id: json['id'] ?? '',
      plantDiseaseId: json['plantDiseaseId'] ?? '',
      plantName: json['plantName'] ?? '',
      diseaseName: json['diseaseName'] ?? '',
      scanDate: json['scanDate'] != null
          ? DateTime.parse(json['scanDate'])
          : DateTime.now(),
      confidence: json['confidence']?.toDouble() ?? 0.0,
      imagePath: json['imagePath'],
      allPredictions: json['allPredictions'] != null
          ? Map<String, double>.from(json['allPredictions'])
          : null,
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plantDiseaseId': plantDiseaseId,
      'plantName': plantName,
      'diseaseName': diseaseName,
      'scanDate': scanDate.toIso8601String(),
      'confidence': confidence,
      'imagePath': imagePath,
      'allPredictions': allPredictions,
      'metadata': metadata,
    };
  }
}
