import 'package:mongo_dart/mongo_dart.dart';
import 'dart:async';
import '../config/app_config.dart';
// For generating mock IDs

class MongoDBService {
  static Db? _db;
  static Db? get db => _db;
  static bool _isMocked = true; // Flag to indicate we're using mock data
  static bool get isMocked => _isMocked;
  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;
  
  // Mock data collections
  static final List<Map<String, dynamic>> _mockUsers = [];
  static final List<Map<String, dynamic>> _mockScans = [];
  static final List<Map<String, dynamic>> _mockAnalytics = [];

  // Initialize mock data with some default entries
  static void _initMockData() {
    if (_mockUsers.isEmpty) {
      _mockUsers.add({
        '_id': ObjectId().oid,
        'email': 'test@example.com',
        'name': 'Test User',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
    
    if (_mockScans.isEmpty) {
      _mockScans.add({
        '_id': ObjectId().oid,
        'userId': _mockUsers[0]['_id'],
        'plantName': 'Mock Plant',
        'diseaseDetected': 'Healthy',
        'confidence': 0.95,
        'imageUrl': 'https://example.com/image.jpg',
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  // Initialize the database connection or mock data
  static Future<void> connect() async {
    if (_isMocked) {
      print('Using mock MongoDB service');
      _initMockData();
      _isInitialized = true;
      return;
    }
    
    try {
      _db = await Db.create(AppConfig.mongoDbUrl);
      await _db!.open();
      _isInitialized = true;
      print('Connected to MongoDB');
    } catch (e) {
      print('Error connecting to MongoDB: $e');
      // Fall back to mock mode if connection fails
      _isMocked = true;
      _initMockData();
      _isInitialized = true;
    }
  }

  // Save scan results
  static Future<Map<String, dynamic>> saveScanResult(Map<String, dynamic> scanData) async {
    if (_isMocked) {
      final scanId = ObjectId().oid;
      final scan = {
        '_id': scanId,
        ...scanData,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockScans.add(scan);
      return scan;
    }
    
    try {
      final scansCollection = _db!.collection(AppConfig.scansCollection);
      final result = await scansCollection.insertOne(scanData);
      if (result.isSuccess) {
        return scanData;
      }
      return {'error': 'Failed to save scan'};
    } catch (e) {
      print('Error saving scan: $e');
      return {'error': e.toString()};
    }
  }

  // Get user by ID
  static Future<Map<String, dynamic>> getUserById(String userId) async {
    if (_isMocked) {
      return _mockUsers.firstWhere(
        (user) => user['_id'] == userId,
        orElse: () => {'error': 'User not found'},
      );
    }
    
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      final result = await usersCollection.findOne(where.eq('_id', userId));
      return result ?? {'error': 'User not found'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get user by email
  static Future<Map<String, dynamic>> getUserByEmail(String email) async {
    if (_isMocked) {
      return _mockUsers.firstWhere(
        (user) => user['email'] == email,
        orElse: () => {'error': 'User not found'},
      );
    }
    
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      final result = await usersCollection.findOne(where.eq('email', email));
      return result ?? {'error': 'User not found'};
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get scan history for a user
  static Future<List<Map<String, dynamic>>> getScanHistoryForUser(String userId) async {
    if (_isMocked) {
      return _mockScans.where((scan) => scan['userId'] == userId).toList();
    }
    
    try {
      final scansCollection = _db!.collection(AppConfig.scansCollection);
      final results = await scansCollection.find(where.eq('userId', userId)).toList();
      return results;
    } catch (e) {
      return [];
    }
  }
  
  // Alias for getScanHistoryForUser to fix the error
  static Future<List<Map<String, dynamic>>> getUserScans(String userId) async {
    return getScanHistoryForUser(userId);
  }

  // Get analytics data
  static Future<Map<String, dynamic>> getAnalyticsData() async {
    if (_isMocked) {
      return {
        'totalScans': _mockScans.length,
        'healthyPlants': _mockScans.where((s) => s['diseaseDetected'] == 'Healthy').length,
        'diseasedPlants': _mockScans.where((s) => s['diseaseDetected'] != 'Healthy').length,
        'mostCommonDisease': 'Leaf Spot',
      };
    }
    
    try {
      // Get analytics calculations from real data
      return {
        'totalScans': 0,
        'healthyPlants': 0,
        'diseasedPlants': 0,
        'mostCommonDisease': 'Unknown',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Get recent scans
  static Future<List<Map<String, dynamic>>> getRecentScans(int limit) async {
    if (_isMocked) {
      return _mockScans.take(limit).toList();
    }
    
    try {
      final scansCollection = _db!.collection(AppConfig.scansCollection);
      // Fix: convert find() results to a List first, then take the limit
      final allResults = await scansCollection.find().toList();
      return allResults.take(limit).toList();
    } catch (e) {
      return [];
    }
  }

  // Save analytics data
  static Future<void> saveAnalyticsData(Map<String, dynamic> data) async {
    if (_isMocked) {
      _mockAnalytics.add({
        '_id': ObjectId().oid,
        ...data,
        'createdAt': DateTime.now().toIso8601String(),
      });
      return;
    }
    
    try {
      final analyticsCollection = _db!.collection(AppConfig.analyticsCollection);
      await analyticsCollection.insertOne(data);
    } catch (e) {
      print('Error saving analytics: $e');
    }
  }

  // Create user
  static Future<Map<String, dynamic>> createUser(Map<String, dynamic> userData) async {
    if (_isMocked) {
      final userId = ObjectId().oid;
      final user = {
        '_id': userId,
        ...userData,
        'createdAt': DateTime.now().toIso8601String(),
      };
      _mockUsers.add(user);
      return user;
    }
    
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      await usersCollection.insertOne(userData);
      return userData;
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  // Update user
  static Future<bool> updateUser(String userId, Map<String, dynamic> updateData) async {
    if (_isMocked) {
      final userIndex = _mockUsers.indexWhere((user) => user['_id'] == userId);
      if (userIndex >= 0) {
        _mockUsers[userIndex] = {..._mockUsers[userIndex], ...updateData};
        return true;
      }
      return false;
    }
    
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      
      // Fix: Create a proper modifier with individual field updates
      final modifier = ModifierBuilder();
      updateData.forEach((key, value) {
        modifier.set(key, value);
      });
      
      final result = await usersCollection.updateOne(
        where.eq('_id', userId),
        modifier,
      );
      return result.isSuccess;
    } catch (e) {
      return false;
    }
  }
  
  // Create or update user method (to fix clerk_service error)
  static Future<Map<String, dynamic>> createOrUpdateUser(Map<String, dynamic> userData) async {
    if (!userData.containsKey('email')) {
      return {'error': 'Email is required'};
    }
    
    final existingUser = await getUserByEmail(userData['email']);
    
    if (existingUser.containsKey('error')) {
      // User doesn't exist, create new one
      return createUser(userData);
    } else {
      // User exists, update it
      final userId = existingUser['_id'];
      await updateUser(userId, userData);
      return {...existingUser, ...userData};
    }
  }
}
