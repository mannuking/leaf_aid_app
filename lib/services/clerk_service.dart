import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import 'mongodb_service.dart';

class ClerkService {
  static const String _baseUrl = 'https://present-pheasant-35.clerk.accounts.dev/v1';
  
  static Future<Map<String, dynamic>> signInWithEmail(String email, String password) async {
    try {
      // First, create a sign-in attempt
      final signInAttempt = await http.post(
        Uri.parse('$_baseUrl/client/sign_ins'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'identifier': email,
          'password': password,
        }),
      );

      if (signInAttempt.statusCode != 200) {
        final error = json.decode(signInAttempt.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to sign in');
      }

      final data = json.decode(signInAttempt.body);
      if (data['status'] == 'complete') {
        await _handleAuthSuccess(data);
        return data;
      } else {
        throw Exception('Authentication incomplete');
      }
    } catch (e) {
      print('Error signing in with email: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      // Create sign-up attempt
      final signUpAttempt = await http.post(
        Uri.parse('$_baseUrl/client/sign_ups'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email_address': email,
          'password': password,
          'first_name': name.split(' ').first,
          'last_name': name.split(' ').length > 1 ? name.split(' ').skip(1).join(' ') : '',
        }),
      );

      if (signUpAttempt.statusCode != 200) {
        final error = json.decode(signUpAttempt.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to sign up');
      }

      final signUpData = json.decode(signUpAttempt.body);
      final signUpId = signUpData['id'];

      // Send verification email
      final verificationResponse = await http.post(
        Uri.parse('$_baseUrl/client/sign_ups/$signUpId/prepare_verification'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'strategy': 'email_code',
        }),
      );

      if (verificationResponse.statusCode == 200) {
        return signUpData;
      } else {
        final error = json.decode(verificationResponse.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to send verification email');
      }
    } catch (e) {
      print('Error signing up: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/client/sign_ins/oauth_google'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAuthSuccess(data);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to sign in with Google');
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> signInWithFacebook() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/client/sign_ins/oauth_facebook'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAuthSuccess(data);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to sign in with Facebook');
      }
    } catch (e) {
      print('Error signing in with Facebook: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>> verifyEmail(String signUpId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/client/sign_ups/$signUpId/attempt_verification'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkPublishableKey}',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'code': code,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        await _handleAuthSuccess(data);
        return data;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to verify email');
      }
    } catch (e) {
      print('Error verifying email: $e');
      rethrow;
    }
  }

  static Future<void> _handleAuthSuccess(Map<String, dynamic> data) async {
    try {
      await MongoDBService.createOrUpdateUser(data);
    } catch (e) {
      print('Error handling auth success: $e');
      // Don't rethrow as this is not critical for the user flow
    }
  }

  static Future<void> signOut() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/end_all'),
        headers: {
          'Authorization': 'Bearer ${AppConfig.clerkSecretKey}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['errors']?[0]?['message'] ?? 'Failed to sign out');
      }
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }
} 
