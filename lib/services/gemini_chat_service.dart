import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:typed_data';
import '../config.dart';

class GeminiChatService {
  // For text-only conversations using Gemini 2.0 Flash
  static final model = GenerativeModel(
    model: 'gemini-2.0-flash',  // Updated to use Gemini 2.0 Flash
    apiKey: Config.geminiApiKey,
  );

  // For image analysis using Gemini 2.0 Flash with image generation capabilities
  static final modelVision = GenerativeModel(
    model: 'gemini-2.0-flash-exp-image-generation',  // Updated to use Gemini 2.0 Flash with image support
    apiKey: Config.geminiApiKey,
  );

  static Future<String> generateTextResponse(String prompt) async {
    try {
      final response = await model.generateContent([
        Content.text(
          'You are a helpful plant care assistant. You help users with plant diseases, gardening tips, and plant care advice. Here is the user\'s question: $prompt'
        ),
      ]);
      
      return response.text ?? 'Sorry, I could not generate a response.';
    } catch (e) {
      print('Error generating response: $e');
      return 'Sorry, there was an error processing your request. Please try again.';
    }
  }

  static Future<String> analyzeImages(String prompt, List<Uint8List> images) async {
    try {
      final contents = <Content>[];
      
      // Add the text prompt
      contents.add(Content.text(prompt));
      
      // Add each image
      for (final imageBytes in images) {
        contents.add(Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ]));
      }

      final response = await modelVision.generateContent(contents);
      return response.text ?? 'Sorry, I could not analyze the images.';
    } catch (e) {
      print('Error analyzing images: $e');
      return 'Sorry, there was an error analyzing the images. Please try again.';
    }
  }
} 
