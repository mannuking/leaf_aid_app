import 'package:mongo_dart/mongo_dart.dart';
import 'package:geolocator/geolocator.dart';
import '../config/app_config.dart';
import 'dart:io';

class MongoDBService {
  static Db? _db;
  static bool _isInitialized = false;
  static const int _maxRetries = 3;
  
  static Future<void> connect() async {
    if (_isInitialized) return;

    int retryCount = 0;
    while (retryCount < _maxRetries) {
      try {
        _db = await Db.create(AppConfig.mongoDbUrl);
        await _db!.open();
        print('Connected to MongoDB');

        // Create indexes for better query performance
        try {
          final scansCollection = _db!.collection(AppConfig.scansCollection);
          
          // Create indexes if they don't exist
          await Future.wait([
            scansCollection.createIndex(
              keys: {'userId': 1},
              unique: false,
              background: true
            ),
            scansCollection.createIndex(
              keys: {'timestamp': -1},
              background: true
            ),
            scansCollection.createIndex(
              keys: {'location.coordinates': '2dsphere'},
              background: true
            )
          ]).catchError((e) {
            // Ignore index exists errors
            print('Warning: Some indexes may already exist: $e');
          });
        } catch (e) {
          print('Warning: Error creating indexes: $e');
          // Don't rethrow index errors - the app can still function
        }

        _isInitialized = true;
        break;
      } catch (e) {
        print('Error connecting to MongoDB (attempt ${retryCount + 1}): $e');
        retryCount++;
        if (retryCount < _maxRetries) {
          // Wait for 1 second before retrying
          await Future.delayed(const Duration(seconds: 1));
        } else {
          rethrow;
        }
      }
    }
  }

  static bool get isInitialized => _isInitialized;

  static Future<void> _ensureConnected() async {
    if (!_isInitialized || _db == null || !_db!.isConnected) {
      await connect();
    }
  }

  static Future<Map<String, dynamic>> createUser({
    required String userId,
    required String email,
    required String authProvider,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      
      final user = {
        'userId': userId,
        'email': email,
        'authProvider': authProvider,
        'createdAt': DateTime.now(),
        'lastLoginAt': DateTime.now(),
        ...?additionalData,
      };

      await usersCollection.insert(user);
      return user;
    } catch (e) {
      print('Error creating user: $e');
      rethrow;
    }
  }

  static Future<void> updateUserLastLogin(String userId) async {
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      await usersCollection.update(
        where.eq('userId', userId),
        modify.set('lastLoginAt', DateTime.now()),
      );
    } catch (e) {
      print('Error updating user last login: $e');
      rethrow;
    }
  }

  static Future<void> saveScanResult({
    required String userId,
    required String imagePath,
    required String diseaseName,
    required double confidence,
    required Position location,
    Map<String, dynamic>? additionalData,
  }) async {
    await _ensureConnected();
    
    try {
      final scansCollection = _db!.collection(AppConfig.scansCollection);
      
      final scan = {
        'userId': userId,
        'imagePath': imagePath,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'location': {
          'type': 'Point',
          'coordinates': [location.longitude, location.latitude]
        },
        'deviceInfo': {
          'platform': Platform.operatingSystem,
          'version': Platform.operatingSystemVersion,
        },
        'timestamp': DateTime.now(),
        ...?additionalData,
      };

      await scansCollection.insert(scan);
      await _saveAnalytics(userId, diseaseName, confidence);
    } catch (e) {
      print('Error saving scan result: $e');
      rethrow;
    }
  }

  static Future<void> _saveAnalytics(String userId, String diseaseName, double confidence) async {
    await _ensureConnected();
    
    try {
      final analyticsCollection = _db!.collection(AppConfig.analyticsCollection);
      
      final analytics = {
        'userId': userId,
        'diseaseName': diseaseName,
        'confidence': confidence,
        'timestamp': DateTime.now(),
        'hour': DateTime.now().hour,
        'dayOfWeek': DateTime.now().weekday,
        'month': DateTime.now().month,
      };

      await analyticsCollection.insert(analytics);
    } catch (e) {
      print('Error saving analytics: $e');
      // Don't rethrow - analytics errors shouldn't block main functionality
    }
  }

  static Future<List<Map<String, dynamic>>> getUserScans(String userId) async {
    await _ensureConnected();
    
    try {
      final scansCollection = _db!.collection(AppConfig.scansCollection);
      
      final cursor = scansCollection.find(
        where.eq('userId', userId)
            .sortBy('timestamp', descending: true)
      );
      
      return await cursor.toList();
    } catch (e) {
      print('Error getting user scans: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> getAnalyticsSummary(String userId) async {
    await _ensureConnected();
    
    try {
      final analyticsCollection = _db!.collection(AppConfig.analyticsCollection);
      
      final pipeline = AggregationPipelineBuilder()
        .addStage(Match(where.eq('userId', userId)))
        .addStage(Group(
          id: null,
          fields: {
            'totalScans': Sum(1),
            'avgConfidence': Avg('confidence'),
            'diseaseCount': AddToSet('diseaseName'),
          },
        ))
        .build();

      final result = await analyticsCollection.aggregateToStream(pipeline).toList();
      return result.isNotEmpty ? result.first : {'totalScans': 0, 'avgConfidence': 0.0, 'diseaseCount': []};
    } catch (e) {
      print('Error getting analytics summary: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> createOrUpdateUser(Map<String, dynamic> data) async {
    try {
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      final userId = data['id'];
      final email = data['email_addresses']?[0]?['email_address'];
      final authProvider = data['oauth_provider'] ?? 'email';
      
      final user = {
        'userId': userId,
        'email': email,
        'authProvider': authProvider,
        'lastLoginAt': DateTime.now(),
        'metadata': data['metadata'],
      };

      // Try to update existing user
      final result = await usersCollection.updateOne(
        where.eq('userId', userId),
        {
          r'$set': user,
          r'$setOnInsert': {'createdAt': DateTime.now()},
        },
        upsert: true,
      );

      return user;
    } catch (e) {
      print('Error creating/updating user: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getUserById(String userId) async {
    try {
      await _ensureConnected();
      final usersCollection = _db!.collection(AppConfig.usersCollection);
      final userData = await usersCollection.findOne(where.eq('userId', userId));
      return userData;
    } catch (e) {
      print('Error fetching user data by ID: $e');
      return null;
    }
  }

  static void close() {
    if (_db != null && _db!.isConnected) {
      _db!.close();
      _isInitialized = false;
    }
  }

  static Db? get db => _db;
}
