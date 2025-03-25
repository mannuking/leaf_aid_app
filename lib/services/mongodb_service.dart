import 'dart:async';
import 'package:mongo_dart/mongo_dart.dart';
import '../config/app_config.dart';
import '../models/plant_disease.dart';
import '../models/scan_history.dart';

class MongoDBService {
  // Mock database flag - set to true to use mock data instead of real MongoDB
  static const bool useMockDatabase = true;
  static Db? _db;
  static DbCollection? _plantsCollection;
  static DbCollection? _historyCollection;
  static bool isInitialized = false; // Add this property
  
  // Mock data
  static final List<Map<String, dynamic>> _mockPlantDiseases = [
    {
      'id': '1',
      'name': 'Apple Black Rot',
      'scientificName': 'Botryosphaeria obtusa',
      'description': 'A fungal disease affecting apples, causing dark lesions on fruits and leaves.',
      'symptoms': [
        'Dark circular lesions on fruits',
        'Reddish-brown spots on leaves',
        'Fruit mummification',
      ],
      'causes': 'Fungal infection, poor air circulation, wet conditions',
      'treatment': 'Prune infected branches, apply fungicide, ensure proper spacing',
      'preventiveMeasures': 'Regular pruning, proper spacing, fungicide application',
    },
    {
      'id': '2',
      'name': 'Tomato Late Blight',
      'scientificName': 'Phytophthora infestans',
      'description': 'A destructive disease of tomatoes and potatoes, causing rapid plant death.',
      'symptoms': [
        'Dark water-soaked spots on leaves',
        'White fuzzy growth on leaf undersides',
        'Brown lesions on stems and fruits',
      ],
      'causes': 'Fungus-like organism, cool wet weather, poor air circulation',
      'treatment': 'Remove infected plants, apply copper-based fungicide',
      'preventiveMeasures': 'Plant resistant varieties, avoid overhead watering, ensure good spacing',
    },
  ];
  
  static final List<Map<String, dynamic>> _mockScanHistory = [];
  
  static Future<void> initialize() async {
    if (useMockDatabase) {
      print('Using mock MongoDB database');
      isInitialized = true; // Set to true for mock database
      return;
    }
    
    try {
      _db = await Db.create(AppConfig.mongoDBConnectionString);
      await _db!.open();
      
      _plantsCollection = _db!.collection(AppConfig.mongoDBCollectionName);
      _historyCollection = _db!.collection('scan_history');
      
      isInitialized = true; // Set to true after successful connection
      print('Connected to MongoDB successfully');
    } catch (e) {
      print('Failed to connect to MongoDB: $e');
      // Fallback to mock data if connection fails
      isInitialized = true; // Set to true for fallback mock data
      print('Using mock data as fallback');
    }
  }
  
  static Future<List<PlantDisease>> getPlantDiseases() async {
    if (useMockDatabase || _db == null) {
      // Return mock data
      return _mockPlantDiseases.map((data) => PlantDisease.fromJson(data)).toList();
    }
    
    try {
      final plantDiseases = await _plantsCollection!.find().toList();
      return plantDiseases.map((data) => PlantDisease.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching plant diseases: $e');
      // Fallback to mock data
      return _mockPlantDiseases.map((data) => PlantDisease.fromJson(data)).toList();
    }
  }
  
  static Future<PlantDisease?> getPlantDiseaseById(String id) async {
    if (useMockDatabase || _db == null) {
      // Return from mock data
      final disease = _mockPlantDiseases.firstWhere(
        (disease) => disease['id'] == id,
        orElse: () => {},
      );
      return disease.isEmpty ? null : PlantDisease.fromJson(disease);
    }
    
    try {
      final disease = await _plantsCollection!.findOne(where.eq('id', id));
      return disease == null ? null : PlantDisease.fromJson(disease);
    } catch (e) {
      print('Error fetching plant disease by ID: $e');
      return null;
    }
  }
  
  static Future<void> saveScanHistory(ScanHistory scanHistory) async {
    if (useMockDatabase || _db == null) {
      // Add to mock data
      _mockScanHistory.add(scanHistory.toJson());
      return;
    }
    
    try {
      await _historyCollection!.insert(scanHistory.toJson());
    } catch (e) {
      print('Error saving scan history: $e');
    }
  }
  
  static Future<List<ScanHistory>> getScanHistory() async {
    if (useMockDatabase || _db == null) {
      // Return mock data
      return _mockScanHistory.map((data) => ScanHistory.fromJson(data)).toList();
    }
    
    try {
      final history = await _historyCollection!.find().toList();
      return history.map((data) => ScanHistory.fromJson(data)).toList();
    } catch (e) {
      print('Error fetching scan history: $e');
      return [];
    }
  }
  
  // Add this method for saving scan results
  static Future<void> saveScanResult(Map<String, dynamic> scanData) async {
    if (useMockDatabase || _db == null) {
      // Add to mock data
      _mockScanHistory.add(scanData);
      return;
    }
    
    try {
      await _historyCollection!.insert(scanData);
    } catch (e) {
      print('Error saving scan result: $e');
    }
  }
  
  static Future<void> close() async {
    if (_db != null && !useMockDatabase) {
      await _db!.close();
    }
  }
}
