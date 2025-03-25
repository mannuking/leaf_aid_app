import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_config.dart';

// Mock user data
class MockUser {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? profileImageUrl;
  
  MockUser({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.profileImageUrl,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': profileImageUrl,
    };
  }
}

class ClerkService {
  // Set to true to use mock implementation
  static const bool useMockAuth = true;
  
  // Store the current user
  static MockUser? _currentUser;
  
  // Mock authentication state
  static bool _isAuthenticated = false;
  
  // Authentication state stream controller
  static final _authStateController = StreamController<bool>.broadcast();
  
  // Get authentication state stream
  static Stream<bool> get authStateChanges => _authStateController.stream;
  
  // Check if user is authenticated
  static bool get isAuthenticated => _isAuthenticated;
  
  // Get current user
  static MockUser? get currentUser => _currentUser;
  
  // Initialize Clerk service
  static Future<void> initialize() async {
    // In a real implementation, this would initialize the Clerk SDK
    // For now, we'll just set up our mock user
    debugPrint('Initializing mock Clerk service');
    
    if (useMockAuth) {
      // Simulate already logged in user
      _currentUser = MockUser(
        id: 'mock-user-123',
        email: 'test@example.com',
        firstName: 'Test',
        lastName: 'User',
        profileImageUrl: 'https://via.placeholder.com/150',
      );
      
      _isAuthenticated = true;
      _authStateController.add(_isAuthenticated);
    }
  }
  
  // Sign in with email and password
  static Future<Map<String, dynamic>> signInWithEmailPassword(String email, String password) async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Very basic validation
    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      throw Exception('Invalid email or password');
    }
    
    // Create mock user based on provided email
    final nameParts = email.split('@')[0].split('.');
    final firstName = nameParts.isNotEmpty ? nameParts[0].capitalize() : 'User';
    final lastName = nameParts.length > 1 ? nameParts[1].capitalize() : '';
    
    _currentUser = MockUser(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      firstName: firstName,
      lastName: lastName,
      profileImageUrl: 'https://via.placeholder.com/150',
    );
    
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
    
    // Return as Map<String, dynamic> to match the expected type in auth_screen.dart
    return _currentUser!.toJson();
  }
  
  // Sign up with email and password
  static Future<Map<String, dynamic>> signUp({
    required String email, 
    required String password,
    String? name,
  }) async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Very basic validation
    if (email.isEmpty || !email.contains('@') || password.isEmpty) {
      throw Exception('Invalid email or password');
    }
    
    // Parse name if provided
    String firstName = 'New';
    String lastName = 'User';
    
    if (name != null && name.isNotEmpty) {
      final nameParts = name.split(' ');
      firstName = nameParts[0];
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }
    
    final userId = 'user-${DateTime.now().millisecondsSinceEpoch}';
    
    return {
      'id': userId,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'profileImageUrl': 'https://via.placeholder.com/150',
    };
  }
  
  // Verify email with code
  static Future<Map<String, dynamic>> verifyEmail(String signUpId, String verificationCode) async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Verify the code is not empty
    if (verificationCode.isEmpty) {
      throw Exception('Invalid verification code');
    }
    
    // Create a mock user
    _currentUser = MockUser(
      id: signUpId,
      email: 'verified@example.com',
      firstName: 'Verified',
      lastName: 'User',
      profileImageUrl: 'https://via.placeholder.com/150',
    );
    
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
    
    return _currentUser!.toJson();
  }
  
  // Sign in with Google
  static Future<Map<String, dynamic>> signInWithGoogle() async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = MockUser(
      id: 'google-${DateTime.now().millisecondsSinceEpoch}',
      email: 'google.user@gmail.com',
      firstName: 'Google',
      lastName: 'User',
      profileImageUrl: 'https://via.placeholder.com/150',
    );
    
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
    
    return _currentUser!.toJson();
  }
  
  // Sign in with Facebook
  static Future<Map<String, dynamic>> signInWithFacebook() async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    _currentUser = MockUser(
      id: 'facebook-${DateTime.now().millisecondsSinceEpoch}',
      email: 'facebook.user@example.com',
      firstName: 'Facebook',
      lastName: 'User',
      profileImageUrl: 'https://via.placeholder.com/150',
    );
    
    _isAuthenticated = true;
    _authStateController.add(_isAuthenticated);
    
    return _currentUser!.toJson();
  }
  
  // Sign out
  static Future<void> signOut() async {
    if (!useMockAuth) {
      throw Exception('Real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = null;
    _isAuthenticated = false;
    _authStateController.add(_isAuthenticated);
  }
  
  // Update user profile
  static Future<void> updateUserProfile({
    String? firstName,
    String? lastName,
    String? profileImageUrl,
  }) async {
    if (!useMockAuth || _currentUser == null) {
      throw Exception('Not authenticated or real authentication not implemented');
    }
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    
    _currentUser = MockUser(
      id: _currentUser!.id,
      email: _currentUser!.email,
      firstName: firstName ?? _currentUser!.firstName,
      lastName: lastName ?? _currentUser!.lastName,
      profileImageUrl: profileImageUrl ?? _currentUser!.profileImageUrl,
    );
  }
  
  // Get JWT token
  static Future<String> getToken() async {
    // Return a fake JWT token
    return 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJtb2NrLXVzZXItMTIzIiwibmFtZSI6IlRlc3QgVXNlciIsImlhdCI6MTUxNjIzOTAyMn0.fake-signature';
  }
  
  // Dispose resources
  static void dispose() {
    _authStateController.close();
  }
}

// Helper extension for string capitalization
extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
  }
}
