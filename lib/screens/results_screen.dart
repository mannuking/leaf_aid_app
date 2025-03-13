import 'package:flutter/material.dart';
import 'dart:io';

class ResultsScreen extends StatelessWidget {
  final File imageFile;
  final String diseaseName;
  final double confidence;

  const ResultsScreen({
    Key? key,
    required this.imageFile,
    required this.diseaseName,
    required this.confidence,
  }) : super(key: key);

  Color _getStatusColor() {
    if (diseaseName.toLowerCase().contains('healthy')) {
      return Colors.green;
    } else if (diseaseName.toLowerCase().contains('background')) {
      return Colors.grey;
    }
    return Colors.red;
  }

  String _formatResult() {
    // Split by underscore and remove plant name prefix
    final parts = diseaseName.split('___');
    if (parts.length != 2) return diseaseName;

    final plantName = parts[0].replaceAll('_', ' ');
    final condition = parts[1].replaceAll('_', ' ');

    return '$plantName\n$condition';
  }

  Widget _buildResultCard() {
    final isHealthy = diseaseName.toLowerCase().contains('healthy');
    final isBackground = diseaseName.toLowerCase().contains('background');
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isHealthy ? 'Healthy Plant Detected!' : 
              isBackground ? 'No Plant Detected' : 'Disease Detected',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _getStatusColor(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatResult(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Confidence: ${(confidence * 100).toStringAsFixed(2)}%',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            if (!isHealthy && !isBackground) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendation:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getRecommendation(),
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getRecommendation() {
    // Add specific recommendations based on the disease
    if (diseaseName.contains('Apple___Apple_scab')) {
      return '• Remove infected leaves and fruit\n• Apply fungicide in early spring\n• Maintain good air circulation through pruning';
    } else if (diseaseName.contains('Tomato___Late_blight')) {
      return '• Remove and destroy infected plants\n• Avoid overhead watering\n• Apply copper-based fungicide\n• Ensure good air circulation';
    }
    // Add more disease-specific recommendations here
    return '• Consult a local agricultural expert\n• Remove infected parts\n• Consider appropriate fungicide treatment\n• Improve plant spacing and air circulation';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Results'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            _buildResultCard(),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Scan Another Leaf',
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
