import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import '../config.dart';

class GeminiService {
  // Hard-code several options to try
  static final List<String> _serverUrls = [
    'http://10.0.2.2:8000',    // Android emulator
    'http://localhost:8000',   // Web or iOS simulator
    'http://127.0.0.1:8000',   // Alternative localhost
    'http://192.168.1.2:8000', // Example local network IP - replace with your actual IP
  ];
  
  // Set a short timeout to fail fast if a server isn't reachable
  static const int _timeoutSeconds = 5;
  
  // Choose the right URL based on platform and device
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:8000';
    
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    }
    
    return 'http://localhost:8000';
  }

  static Future<bool> testConnection() async {
    print('Testing connection to server...');
    
    // Try each URL in our list until one works
    for (final url in _serverUrls) {
      try {
        print('Attempting to connect to: $url/test');
        final response = await http.get(
          Uri.parse('$url/test'),
          headers: {'Accept': 'application/json'},
        ).timeout(Duration(seconds: _timeoutSeconds));
        
        if (response.statusCode == 200) {
          print('Connection successful to: $url');
          return true;
        } else {
          print('Server responded with status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Connection to $url failed: $e');
      }
    }
    
    return false;
  }

  static const String _baseUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
  
  static Future<String> generateResponse(String message) async {
    print('Generating response for: "$message"');
    
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are a helpful plant care assistant. You can only discuss topics related to plants, agriculture, gardening, and plant care. If asked about other topics, politely redirect the conversation back to plants. Here is the user\'s question: $message'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          }
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && data['candidates'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] ?? 
                 'Sorry, I could not generate a response.';
        }
      }
      
      throw Exception('Failed to generate response: ${response.statusCode}');
    } catch (e) {
      print('Error generating response: $e');
      throw Exception('Failed to communicate with Gemini API: $e');
    }
  }
}
