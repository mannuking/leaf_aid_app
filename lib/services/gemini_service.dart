import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  // Replace this IP with your computer's local IP address
  // To find your IP:
  // - On Windows: Open CMD and type 'ipconfig'
  // - On Mac/Linux: Open Terminal and type 'ifconfig' or 'ip addr'
  static const String _baseUrl = 'http://122.162.149.33:8000'; // Update this IP address

  static Future<String> generateResponse(String prompt) async {
    try {
      print('Sending request to: $_baseUrl/chat');
      final response = await http.post(
        Uri.parse('$_baseUrl/chat'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'message': prompt,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' && data['message'] != null) {
          return data['message'] as String;
        } else {
          print('Invalid response format: $data');
          throw Exception('Invalid response format from backend');
        }
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error in generateResponse: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Failed to communicate with backend: $e');
    }
  }

  static Future<bool> testConnection() async {
    try {
      print('Testing connection to: $_baseUrl/test');
      final response = await http.get(Uri.parse('$_baseUrl/test'));
      
      print('Test response status: ${response.statusCode}');
      print('Test response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('Connection test failed: $e');
      return false;
    }
  }
} 
